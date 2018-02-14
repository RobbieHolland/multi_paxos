defmodule Leader do
    def start acceptors, replicas do
        ballot_number = {0, self()}
        active = false
        proposals = MapSet.new

        spawn Scout, :start, [self(), acceptors, ballot_number]

        next proposals, active, replicas, ballot_number, acceptors
    end

    def next proposals, active, replicas, ballot_number, acceptors do
        receive do
            {:propose, s, c} ->
                taken_slots = for {s, _} <- proposals, do: s
                slot_free = length(taken_slots) == 0

                proposals = if slot_free do
                # deviant
                    if active do
                        spawn Commander, :start, [self(), acceptors, replicas, {ballot_number, s, c}]
                    end
                    MapSet.put proposals, {s, c}
                else
                    proposals
                end

                next proposals, active, replicas, ballot_number, acceptors
        end
        
    end
end