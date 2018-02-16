# Robert Holland (rh2515) and Chris Hawkes (ch3915)

defmodule Scout do
    def start leader, acceptors, b do
        for a <- acceptors, do: send a, {:p1a, self(), b}

        next leader, acceptors, b, length(acceptors), MapSet.new
    end

    def next leader, wait_for, b, n, p_values do
        receive do
            {:p1b, acceptor, b_prime, r} ->
                if b_prime == b do
                    p_values = MapSet.union p_values, r
                    wait_for = List.delete wait_for, acceptor

                    if length(wait_for) < (n / 2) do
                        send leader, {:adopted, b, p_values}
                        Process.exit self(), :normal
                    end

                    next leader, wait_for, b, n, p_values
                else
                    send leader, {:preempted, b_prime}
                    Process.exit self(), :normal
                end
        end
    end
end
