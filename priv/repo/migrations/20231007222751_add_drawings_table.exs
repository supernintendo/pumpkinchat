defmodule Pumpkinchat.Repo.Migrations.AddDrawingsTable do
  use Ecto.Migration

  def up do
    create table("drawings") do
      add :uuid, :uuid, primary_key: true
      add :type, :string
      add :content, :text

      timestamps()
    end
  end
end
