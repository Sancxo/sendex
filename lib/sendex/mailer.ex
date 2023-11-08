defmodule Sendex.Mailer do
  require Logger
  use Agent

  alias Sendex.Recipient

  @typedoc "A map of non negative integers as key and of Recipient structs as values."
  @type recipients_map() :: %{non_neg_integer() => %Recipient{}}

  @typedoc "A tuple made of a :ok / :error atom and its data as returned by Swoosh.Mailer.deliver/2"
  @type delivery_result() :: {:ok | :error, term()}

  @doc "Starts the Mailer Agent; takes a recipients map as argument."
  @spec start_link(recipients_map()) :: {:error, any()} | {:ok, pid()}
  def start_link(recipients_map), do: Agent.start_link(fn -> recipients_map end)

  @doc "Updates the Agent state; takes a mailer pid, and a delivery result as arguments."
  @spec update_status(
          atom() | pid() | {atom(), any()} | {:via, atom(), any()},
          {non_neg_integer(), %Recipient{}},
          delivery_result()
        ) ::
          :ok
  def update_status(mailer, {recipient_key, _}, result) do
    Agent.update(mailer, fn recipients_map ->
      recipients_map
      |> Map.update!(recipient_key, fn value -> %Recipient{value | sending_status: result} end)
    end)
  end

  @spec get_results(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: recipients_map()
  @doc "Returns the Mailer Agent state; takes a mailer pid as argument."
  def get_results(mailer), do: Agent.get(mailer, fn recipients_map -> recipients_map end)

  @spec stop_mailer(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: :ok
  @doc "Stops the Mailer Agent; takes a mailer pid as argument."
  def stop_mailer(mailer), do: Agent.stop(mailer)
end
