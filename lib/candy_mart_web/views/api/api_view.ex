defmodule CandyMartWeb.Api.ApiView do
  use CandyMartWeb, :view

  def render("orders.json", %{count: count}) do
    %{count: count}
  end

  def render("order.json", %{order: order}) do
    %{
      id: order.id,
      customer_id: order.customer_id,
      product_name: order.product_name,
      quantity: order.quantity,
      total_cost: order.total_cost.amount,
      unit_cost: order.unit_cost.amount
    }
  end
end
