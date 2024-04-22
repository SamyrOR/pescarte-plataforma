defmodule PescarteWeb.SessionContext do
  import Phoenix.Component, only: [assign: 2]

  alias Pescarte.Identidades.Models.Usuario

  def on_mount(:mount_pescarte_context, _params, _session, socket) do
    current_user = socket.assigns.current_user

    case Usuario.fetch_by(external_customer_id: current_user && current_user.id) do
      {:ok, usuario} -> {:cont, assign(socket, current_usuario: usuario)}
      {:error, :not_found} -> {:halt, socket}
    end
  end
end
