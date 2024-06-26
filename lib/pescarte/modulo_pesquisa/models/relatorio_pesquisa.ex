defmodule Pescarte.ModuloPesquisa.Models.RelatorioPesquisa do
  use Pescarte, :model

  alias Pescarte.Database.Types.PublicId
  alias Pescarte.ModuloPesquisa.Models.Pesquisador
  alias Pescarte.ModuloPesquisa.Schemas.ConteudoAnual
  alias Pescarte.ModuloPesquisa.Schemas.ConteudoMensal
  alias Pescarte.ModuloPesquisa.Schemas.ConteudoTrimestral

  @type t :: %RelatorioPesquisa{
          tipo: atom,
          data_inicio: Date.t(),
          data_fim: Date.t(),
          data_entrega: Date.t(),
          data_limite: Date.t(),
          link: binary,
          status: atom,
          pesquisador: Pesquisador.t(),
          id: binary
        }

  @tipo ~w(mensal bimestral trimestral anual)a
  @status ~w(entregue atrasado pendente)a

  @required_fields ~w(tipo data_inicio data_fim status pesquisador_id)a
  @optional_fields ~w(data_entrega data_limite link)a

  @derive {
    Flop.Schema,
    filterable: ~w(tipo status nome_pesquisador)a,
    sortable: ~w(tipo status nome_pesquisador)a,
    adapter_opts: [
      join_fields: [
        nome_pesquisador: [
          binding: :usuario,
          field: :primeiro_nome,
          ecto_type: :string,
          path: [:pesquisador, :usuario]
        ]
      ]
    ]
  }

  @primary_key {:id, PublicId, autogenerate: true}
  schema "relatorio_pesquisa" do
    field :link, :string
    field :data_inicio, :date
    field :data_fim, :date
    field :data_entrega, :date
    field :data_limite, :date
    field :tipo, Ecto.Enum, values: @tipo
    field :status, Ecto.Enum, values: @status

    embeds_one :conteudo_anual, ConteudoAnual, source: :conteudo, on_replace: :update
    embeds_one :conteudo_mensal, ConteudoMensal, source: :conteudo, on_replace: :update
    embeds_one :conteudo_trimestral, ConteudoTrimestral, source: :conteudo, on_replace: :update

    belongs_to :pesquisador, Pesquisador, type: :string

    timestamps()
  end

  @spec changeset(struct, map) :: changeset
  def changeset(%RelatorioPesquisa{} = relatorio, attrs) do
    relatorio
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_embed(:conteudo_anual)
    |> cast_embed(:conteudo_mensal)
    |> cast_embed(:conteudo_trimestral)
    |> validate_required(@required_fields)
    |> validate_inclusion(:tipo, @tipo)
    |> validate_inclusion(:status, @status)
    |> foreign_key_constraint(:pesquisador_id)
    |> validate_period()
    |> validate_status()
    |> put_limit_date()
  end

  defp put_limit_date(changeset) do
    report_type = get_field(changeset, :tipo)
    today = Date.utc_today()

    limit_date =
      case report_type do
        nil -> changeset
        :mensal -> Date.new!(today.year, today.month, 15)
        _ -> Date.new!(today.year, today.month, 10)
      end

    put_change(changeset, :data_limite, limit_date)
  end

  defp validate_period(changeset) do
    start_date = get_field(changeset, :data_inicio)
    end_date = get_field(changeset, :data_fim)

    case {start_date, end_date} do
      {start_date, end_date} when is_nil(start_date) or is_nil(end_date) ->
        changeset

      {_, _} ->
        if Date.compare(start_date, end_date) == :gt do
          add_error(changeset, :data_inicio, "A data de início deve ser anterior a data de fim")
        else
          changeset
        end
    end
  end

  defp validate_status(changeset) do
    status = get_field(changeset, :status)

    case status do
      :entregue ->
        add_error(
          changeset,
          :status,
          "O relatório foi marcado como entregue e não é possível fazer novas alterações"
        )

      _ ->
        changeset
    end
  end
end
