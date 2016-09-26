defmodule Spellbook.Parser do
  @moduledoc """
  Configuration parser behaviour.
  """
  @callback parse(data :: String.t) :: {:ok | :error, Map.t | String.t}
end
