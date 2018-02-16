defmodule Replica do
    def start config, database, monitor do
        receive do
            {:bind, leaders} ->
                state = Map.new
                    |> Map.put(:slot_in, 1)
                    |> Map.put(:slot_out, 1)
                    |> Map.put(:requests, [])
                    |> Map.put(:proposals, MapSet.new)
                    |> Map.put(:decisions, MapSet.new)
                    |> Map.put(:config, config)
                    |> Map.put(:database, database)
                    |> Map.put(:monitor, monitor)
                    |> Map.put(:leaders, leaders)
                
                next state
        end
    end

    def next state do
        state = receive do
            {:client_request, c} ->
                send state[:monitor], {:client_request, state[:config][:server_num]}
                Map.update!(state, :requests, &([c|&1]))
            {:decision, s, c} ->
                state = Map.update!(state, :decisions, &(MapSet.put &1, {s,c}))
                while_perform(state)
        end
        state = propose(state)
        next(state)
    end

    def while_perform state do
        slot_out = state[:slot_out]

        ds = for {^slot_out, _} = d <- state[:decisions], do: d
        if ds != [] do
            [{_, c} | _] = ds

            ps = for {^slot_out, _} = p <- state[:proposals], do: p
            state = if ps != [] do
                [{_, c_prime} = p | _] = ps
                state = Map.update!(state, :proposals, &(MapSet.delete &1, p))
                if c != c_prime do
                    Map.update!(state, :requests, &([c_prime|&1]))
                else
                    state
                end
            else
                state
            end
            state = perform c, state
            while_perform state
        else
            state
        end
    end

    def propose %{:leaders => leaders, :decisions => decisions, :slot_in => slot_in} = state do
        window = 1
        if (state[:slot_in] < state[:slot_out] + window) and (state[:requests] != []) do

            taken_slots = for {^slot_in, _} <- decisions, do: true
            slot_free = length(taken_slots) == 0

            [c | tail] = state[:requests]

            state = if slot_free do
                for l <- leaders do
                    send l, {:propose, slot_in, c}
                end
                state 
                    |> Map.update!(:proposals, &(MapSet.put &1, {slot_in, c}))
                    |> Map.put(:requests, tail)
            else
                state
            end

            propose Map.update!(state, :slot_in, &(&1 + 1))
        else
            state
        end
    end

    def perform {k, cid, op} = c, %{:database => database, :decisions => decisions} = state do
        # in both cases still need to increment slot_out
        taken_slots = for {s, ^c} <- decisions, do: s < state[:slot_out]
        previously_perfomed = Enum.any? taken_slots

        if not previously_perfomed do
            send database, {:execute, op}
            result = true
            send k, {:reply, cid, result}
        end

        Map.update!(state, :slot_out, &(&1 + 1))
    end
end