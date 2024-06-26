defmodule Pescarte.ModuloPesquisa.Adapters.PesquisadorAdapter do
  alias Pescarte.Identidades.Models.Usuario

  alias Pescarte.ModuloPesquisa.Models.Pesquisador, as: Model
  alias Pescarte.ModuloPesquisa.Schemas.Pesquisador, as: Schema

  @spec internal_to_external(Model.t()) :: Schema.t()
  def internal_to_external(pesquisador) do
    attrs = %{
      id: pesquisador.id,
      nome: Usuario.build_usuario_name(pesquisador.usuario),
      cpf: pesquisador.usuario.cpf,
      email: pesquisador.usuario.contato.email_principal,
      participacao: pesquisador.bolsa
    }

    Schema.parse!(attrs)
  end
end
