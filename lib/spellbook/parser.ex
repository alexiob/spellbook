defmodule Spellbook.Parser do
  @callback parse(data :: String.t) :: {:ok | :error, Map.t | String.t}
end
