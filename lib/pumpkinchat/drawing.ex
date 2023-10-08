defmodule Pumpkinchat.Drawing do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "drawings" do
    field :type, Ecto.Enum, values: ~w(pumpkin carving)a
    field :content, :string

    timestamps()
  end

  @fields ~w(type content)a

  def changeset(drawing, attrs \\ %{}) do
    drawing
    |> cast(attrs, @fields)
  end
end
