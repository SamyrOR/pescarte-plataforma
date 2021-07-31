defmodule FuschiaWeb.Auth.Guardian do
  @moduledoc """
  Guardian serializer for Fuschia app
  """

  use Guardian, otp_app: :fuschia

  alias Fuschia.Context.Users
  alias Fuschia.Entities.User

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)

    {:ok, sub}
  end

  def resource_from_claims(claims) do
    user =
      claims
      |> Map.get("sub")
      |> Users.one()

    {:ok, user}
  end

  def authenticate(%{"email" => email, "password" => password}) do
    case Users.one_by_email(email) do
      nil -> {:error, :unauthorized}
      user -> validate_password(user, password)
    end
  end

  def user_claims(%{"email" => email}) do
    case user = Users.one_with_permissions(email) do
      nil -> {:error, :unauthorized}
      _ -> {:ok, User.for_jwt(user)}
    end
  end

  def create_token(user) do
    {:ok, token, _claims} = encode_and_sign(user)

    {:ok, token}
  end

  defp validate_password(_user, ""), do: {:error, :unauthorized}

  defp validate_password(user, password) when is_binary(password) do
    with %User{password_hash: password_hash} = user <- user,
         false <- is_nil(password_hash),
         true <- Bcrypt.verify_pass(password, user.password_hash) do
      create_token(user)
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp validate_password(_user, _password), do: {:error, :unauthorized}
end