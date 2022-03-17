defmodule TexasHoldem.Repo do
  use Ecto.Repo,
    otp_app: :texas_holdem,
    adapter: Ecto.Adapters.Postgres
end
