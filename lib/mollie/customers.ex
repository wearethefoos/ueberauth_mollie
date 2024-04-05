defmodule Mollie.Customers do
  @moduledoc """
  Mollie Customers API

  See: https://docs.mollie.com/reference/v2/customers-api/overview
  """

  @doc """
  Get all customers

  Returns a list of customers created.

  Example:
      iex> Mollie.Customers.list_customers()
      {:ok, %{...}}

  Use pagination to limit the number of customers returned. The API returns a maximum of 250 customers per page.
  Use the `from` parameter to specify the first customer that should be returned. The `limit` parameter can be
  used to limit the number of customers returned.

  Example
      iex> client = Mollie.Client.new()
      iex> Mollie.Customers.list_customers(%{from: "cst_kEn1PlbGa", limit: 5})
      {:ok, %{...}}
  """
  def list_customers(query \\ []) do
    Mollie.Client.new()
    |> Tesla.get("/customers", query: query)
    |> handle_response()
  end

  @doc """
  Create a customer
  """

  def create_customer(params) do
    Mollie.Client.new()
    |> Tesla.post("/customers", params)
    |> handle_response()
  end

  @doc """
  Get a customer
  """
  def get_customer(customer_id) do
    Mollie.Client.new()
    |> Tesla.get("/customers/#{customer_id}")
    |> handle_response()
  end

  @doc """
  Update a customer
  """
  def update_customer(customer_id, params) do
    Mollie.Client.new()
    |> Tesla.patch("/customers/#{customer_id}", params)
    |> handle_response()
  end

  @doc """
  Delete a customer
  """
  def delete_customer(customer_id) do
    Mollie.Client.new()
    |> Tesla.delete("/customers/#{customer_id}")
    |> handle_response()
  end

  @spec handle_response({:ok, Tesla.Env.t()} | {:error, Tesla.Env.t()}) ::
          {:ok, map()} | {:error, map()}
  defp handle_response({:ok, %Tesla.Env{} = response}) do
    {:ok, Jason.decode!(response.body)}
  end

  defp handle_response({:error, response}) do
    {:error, Jason.decode!(response.body)}
  end
end
