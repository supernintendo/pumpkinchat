defmodule Pumpkinchat.Repo do
  use Ecto.Repo,
    otp_app: :pumpkinchat,
    adapter: Ecto.Adapters.Postgres
end
