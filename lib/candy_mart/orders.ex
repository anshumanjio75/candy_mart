defmodule CandyMart.Orders do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias CandyMart.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias CandyMart.Orders.Order

  @pagination [page_size: 15]
  @pagination_distance 5
  @batch_size 5000

  @doc """
  Paginate the list of orders using filtrex
  filters.

  ## Examples

      iex> list_orders(%{})
      %{orders: [%Order{}], ...}
  """
  @spec paginate_orders(map) :: {:ok, map} | {:error, any}
  def paginate_orders(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:orders), params["order"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_orders(filter, params) do
      {:ok,
       %{
         orders: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_orders(filter, params) do
    Order
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def create_orders(attrs \\ %{}) do
    data =
      attrs["_json"]
      |> convert_params()
      |> Enum.map(fn order -> add_time_stamp(order) end)

    Order
    |> Repo.insert_all(data)
  end

  defp add_time_stamp(item) do
    time = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

    Map.merge(item, %{
      inserted_at: time,
      updated_at: time
    })
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{source: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  defp filter_config(:orders) do
    defconfig do
      text(:product_name)
      number([:quantity, :unit_cost, :total_cost, :customer_id])
    end
  end

  def import_orders(file) do
    "#{file.path}"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.map(fn {:ok, order} -> parse_fields(order) end)
    |> convert_params()
    |> insert_orders()
  end

  def parse_fields(order) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    order
    |> Map.update!("customer_id", &(&1 |> String.to_integer()))
    |> Map.update!("total_cost", &(&1 |> String.to_integer()))
    |> Map.update!("unit_cost", &(&1 |> String.to_integer()))
    |> Map.update!("quantity", &(&1 |> String.to_integer()))
    |> Map.put("inserted_at", NaiveDateTime.from_iso8601!(order["purchased_at"]))
    |> Map.put("updated_at", timestamp)
    |> Map.put("product_name", order["product"])
    |> Map.delete("product")
    |> Map.delete("purchased_at")
  end

  def convert_params(data) do
    data
    |> Enum.map(fn orders ->
      orders
      |> Enum.into(%{})
      |> convert()
    end)
  end

  def convert(data) do
    for {key, val} <- data, into: %{}, do: {String.to_atom(key), val}
  end

  def insert_orders(items) do
    Enum.chunk_every(items, @batch_size)
    |> Enum.each(fn rows ->
      Repo.insert_all(Order, rows)
    end)
  end
end
