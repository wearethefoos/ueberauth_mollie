defmodule Mollie.Payments do
  @moduledoc """
  Convenience functions for working with Mollie Payments.

  see: https://docs.mollie.com/reference/v2/payments-api/overview
  """

  @doc """
  Get Payments

  Returns a list of payments created.

  Example:
      iex> Mollie.Payments.list_payments()
      {:ok, %{...}}
  """
  def list_payments do
    Mollie.Client.new()
    |> Tesla.get("/payments")
    |> handle_response()
  end

  @doc """
  Create Payment

  Creates a new payment.

  Example:
      iex> Mollie.Payments.create(%{
      iex>   amount: %{
      iex>     currency: "EUR",
      iex>     value: "10.00"
      iex>   },
      iex>   description: "My first payment",
      iex>   redirectUrl: "https://example.com/redirect"
      iex> })
      {:ok, %{...}}
  """
  def create_payment(body) do
    Mollie.Client.new()
    |> Tesla.post("/payments", body)
    |> handle_response()
  end

  @doc """
  Get Payment

  Returns a single payment by its ID.

  Example:
      iex> Mollie.Payments.get("tr_7UhSN1zuXS")
      {:ok, %{...}}
  """
  def get_payment(id) do
    Mollie.Client.new()
    |> Tesla.get("/payments/#{id}")
    |> handle_response()
  end

  @doc """
  Update Payment

  Updates a payment.

  Example:
      iex> Mollie.Payments.update("tr_7UhSN1zuXS", %{
      iex>   description: "My updated payment"
      iex> })
      {:ok, %{...}}
  """
  def update_payment(id, body) do
    Mollie.Client.new()
    |> Tesla.patch("/payments/#{id}", body)
    |> handle_response()
  end

  @doc """
  Cancel Payment

  Cancels a payment.

  Example:
      iex> Mollie.Payments.cancel("tr_7UhSN1zuXS")
      {:ok, %{...}}
  """
  def cancel_payment(id) do
    Mollie.Client.new()
    |> Tesla.delete("/payments/#{id}")
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
