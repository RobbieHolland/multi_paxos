# Robert Holland (rh2515) and Chris Hawkes (ch3915)

defmodule LeaderTest do
  use ExUnit.Case
  doctest Leader

  test "pmax pvals1" do
    # should return {slot, command} with highest ballot number for each slot
    # here there is only one slot (slot number 2)
    # {ballot_number, slot, command}
    pvals = MapSet.new
        |> MapSet.put({1,2,1})
        |> MapSet.put({2,2,2})
        |> MapSet.put({4,2,3})
        |> MapSet.put({3,2,4})

    assert Leader.pmax(pvals) == (MapSet.new |> MapSet.put({2,3}))
  end

  test "pmax pvals2" do
    pvals = MapSet.new
        |> MapSet.put({1,2,1})
        |> MapSet.put({2,2,2})
        |> MapSet.put({4,3,3})
        |> MapSet.put({3,3,4})

    assert Leader.pmax(pvals) == (MapSet.new |> MapSet.put({2,2}) |> MapSet.put({3,3}))
  end

  test "pmax pvals3" do
    pvals = MapSet.new

    assert Leader.pmax(pvals) == MapSet.new
  end

  test "update" do
    x = MapSet.new
      |> MapSet.put({2,1})
      |> MapSet.put({1,0})

    y = MapSet.new
      |> MapSet.put({2,3})

    assert Leader.update(x, y) == (MapSet.new |> MapSet.put({2,3}) |> MapSet.put({1,0}))
  end

end
