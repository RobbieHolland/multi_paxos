# Robert Holland (rh2515) and Chris Hawkes (ch3915)

defmodule Commander do
    def start leader, acceptors, replicas, data do
        waitfor = acceptors
        for a <- acceptors, do: send a, {:p2a, self(), data}

        next leader, waitfor, length(acceptors), replicas, data
    end

    def next leader, waitfor, n, replicas, {b, s, c} = data do
        receive do
            {:p2b, acceptor, b_prime} ->
                if b == b_prime do
                    waitfor = List.delete waitfor, acceptor
                    if length(waitfor) < (n / 2) do
                        for r <- replicas, do: send r, {:decision, s, c}
                        Process.exit(self(), :normal)
                    end

                    next leader, waitfor, n, replicas, data
                else
                    send leader, {:preempted, b_prime}
                    Process.exit(self(), :normal)
                end
        end
    end
end
