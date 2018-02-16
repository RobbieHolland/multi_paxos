defmodule Acceptor do
    def start config do
        next 0, MapSet.new
    end

    def next ballot_number, accepted do
        receive do
            {:p1a, scout, b} ->
                ballot_number = max ballot_number, b
                send scout, {:p1b, self(), ballot_number, accepted}
                next ballot_number, accepted
            {:p2a, commander, {b, _, _} = data} ->
                accepted = if b == ballot_number do
                    MapSet.put accepted, data
                else
                    accepted
                end
                send commander, {:p2b, self(), ballot_number}
                next ballot_number, accepted
        end
    end
end