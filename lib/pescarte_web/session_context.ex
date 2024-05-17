defmodule PescarteWeb.SessionContext do
  import Phoenix.Component, only: [assign: 2, assign_new: 3]
  import Phoenix.LiveView, only: [redirect: 2]

  alias Pescarte.Identidades.Models.Usuario
  alias Supabase.GoTrue

  def on_mount(:mount_session_from_conn, _params, session, socket) do
    session
    |> GoTrue.LiveView.mount_current_user(socket)
    |> mount_current_usuario()
  end

  def on_mount(:mount_pescarte_context, _params, _session, socket) do
    mount_current_usuario(socket)
  end

  def mount_current_usuario(socket) do
    current_user = socket.assigns.current_user

    case Usuario.fetch_by(external_customer_id: current_user && current_user.id) do
      {:ok, usuario} ->
        {:cont, assign(socket, current_usuario: usuario)}

      {:error, :not_found} ->
        {:halt,
         socket
         |> assign(error_message: "Não conseguimos carregar seu usuário!")
         |> redirect(to: "/")}
    end
  end
end
