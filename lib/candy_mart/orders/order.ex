defmodule CandyMart.Orders.Order do
  alias CandyMart.Users.User

  use Ecto.Schema
  import Ecto.Changeset

  use Pow.Ecto.Schema

  @all_fields ~w(
    quantity
    unit_cost
    total_cost
    product_name
    customer_id
  )a

  @required_fields @all_fields

  schema "orders" do
    field :quantity, :integer, null: false
    field :unit_cost, Money.Ecto.Amount.Type
    field :total_cost, Money.Ecto.Amount.Type
    field :product_name, :string, null: false
    field :customer_id, :integer, null: false

    timestamps()

    belongs_to(:user, User,
      foreign_key: :customer_id,
      references: :id,
      define_field: false
    )
  end

  def changeset(%__MODULE__{} = account, attrs \\ %{}) do
    account
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:customer_id)
  end

  def new_changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
  end
end
