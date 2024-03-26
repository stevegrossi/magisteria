defmodule Magisteria.Repo do
  use Ecto.Repo,
    otp_app: :magisteria,
    adapter: Ecto.Adapters.Postgres
end
