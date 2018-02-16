# Robert Holland (rh2515) and Chris Hawkes (ch3915)

defmodule Leader do
    def start config do
        receive do
            {:bind, acceptors, replicas} ->
                ballot_number = {0, self()}
                active = false
                proposals = MapSet.new

                spawn Scout, :start, [self(), acceptors, ballot_number]

                next proposals, active, replicas, ballot_number, acceptors
        end
    end

    def next proposals, active, replicas, ballot_number, acceptors do
        receive do
            {:propose, s, c} ->
                taken_slots = for {^s, _} <- proposals, do: s
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
            {:adopted, b_prime, pvals} ->
                if b_prime == ballot_number do
                    proposals = update(proposals, pmax(pvals))
                    for {s, c} <- proposals do
                        spawn Commander, :start, [self(), acceptors, replicas, {ballot_number, s, c}]
                    end
                    active = true
                    next proposals, active, replicas, ballot_number, acceptors
                else
                    # ignore / do nothing
                    next proposals, active, replicas, ballot_number, acceptors
                end
            {:preempted, {r_prime, leader_prime}} ->
                if {r_prime, leader_prime} > ballot_number do
                    active = false
                    ballot_number = {r_prime + 1, self()}

                    # possibly wait a bit before scouting? - avoid livelock
                    Process.sleep(Enum.random 1..50)

                    spawn Scout, :start, [self(), acceptors, ballot_number]
                    next proposals, active, replicas, ballot_number, acceptors
                else
                    # ignore / do nothing
                    next proposals, active, replicas, ballot_number, acceptors
                end
        end

    end

    def pmax pvals do
        slot_groups = Enum.group_by pvals, fn {_,s,_} -> s end
        maxs = Enum.map(slot_groups, fn {_, vals} ->
            vals |> Enum.max
        end)
        for {_,s,c} <- maxs, into: MapSet.new, do: {s,c}
    end

    def update x, y do
        slots = for {s, _} <- y, into: MapSet.new, do: s
        x_prime = for {s, c} <- x, not(MapSet.member?(slots, s)), into: MapSet.new, do: {s, c}
        MapSet.union y, x_prime
    end
end
