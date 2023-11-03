defmodule Sendex.Recipient do
  @moduledoc """
  Recipient schema used to validate data received from the .xls file.

  Every key is mandatory and should be a string:
  `:name` can contain only the last name or the first and last names separated by a space, depending of how you want to call the recipient in the message to be send;
  `:city` is for the city in which the artist wants to perform (used in the mail body);
  `:mail` is the adress mail the message will be sent to;
  `:title` is the way you want to address yourself to the recipient at the beginning of the message ("M.", "Ms.", "M./Ms.", "Dear")

  ### Example
      iex> %Recipient{
        title: "M.",
        name: "Foo Bar",
        city: "Baz",
        mail: "foo.bar@bin.com"
      }
  """
  @enforce_keys [:title, :name, :city, :mail]
  @type t() :: %__MODULE__{
          title: String.t(),
          name: String.t(),
          city: String.t(),
          mail: String.t(),
          sending_status: {nil | :ok | :error, term()}
        }
  defstruct([:title, :name, :city, :mail, sending_status: {nil, nil}])
end
