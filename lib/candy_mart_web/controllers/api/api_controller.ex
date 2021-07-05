defmodule CandyMartWeb.Api.ApiController do
  use CandyMartWeb, :controller
  alias CandyMart.Orders

  def create_sale(conn, params) do
    with {:ok, order} <- Orders.create_order(params) do
      render(conn, "order.json", %{order: order})
    end
  end

  def create_sales(conn, params) do
    with {count, nil} <- Orders.create_orders(params) do
      render(conn, "orders.json", %{count: count})
    end
  end
end
