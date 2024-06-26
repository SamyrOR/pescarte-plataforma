defmodule Pescarte.Cotacoes.Handlers.CotacaoHandler do
  alias Pescarte.Cotacoes.Repository

  @behaviour Pescarte.Cotacoes.Handlers.IManageCotacaoHandler

  @impl true
  def zip_file?(cotacao) do
    cotacao.tipo == :zip or String.ends_with?(cotacao.link, "zip")
  end

  @impl true
  defdelegate list_cotacao, to: Repository

  @impl true
  defdelegate fetch_cotacao_by_link(link), to: Repository

  @impl true
  defdelegate fetch_cotacao_by_id(id), to: Repository

  @impl true
  def find_cotacoes_not_ingested do
    Repository.find_all_cotacao_by_not_ingested()
  end

  @impl true
  def find_cotacoes_not_downloaded do
    Repository.find_all_cotacao_by_not_downloaded()
  end

  @impl true
  def get_cotacao_file_base_name(cotacao) do
    cotacao.link
    |> String.split("/")
    |> List.last()
  end

  @impl true
  def insert_cotacao_pesagro(link, today) do
    alias Pescarte.Cotacoes.Models.Fonte
    alias Pescarte.Database.Repo

    fonte = Repo.replica().get_by(Fonte, nome: "pesagro")

    tipo =
      case Enum.reverse(String.split(link, ".")) do
        ["zip" | _] -> :zip
        ["pdf" | _] -> :pdf
      end

    attrs = %{
      fonte_id: fonte.id,
      link: link,
      data: today,
      importada?: false,
      baixada?: false,
      tipo: tipo
    }

    Repository.insert_cotacao(attrs)
  end

  @impl true
  def set_cotacao_downloaded(cotacao) do
    Repository.upsert_cotacao(cotacao, %{baixada?: true})
  end
end
