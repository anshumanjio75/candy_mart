defmodule CandyMart.Users.User do
  alias CandyMart.Orders.Order

  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()

    timestamps()

    has_many(:order, Order,
      foreign_key: :customer_id,
      on_delete: :delete_all
    )
  end
end
