defmodule SquaredleSolver.DictionaryServerTest do
  use ExUnit.Case
  alias SquaredleSolver.DictionaryServer

  test "returns the loaded trie eventually" do
    trie = DictionaryServer.get_trie()
    assert is_map(trie)
    assert Map.has_key?(trie, "a")
  end

  test "handles queueing while loading" do
    {:ok, pid} = GenServer.start_link(DictionaryServer, %{})
    
    # Send a get_trie request immediately before it finishes loading
    task = Task.async(fn -> 
      GenServer.call(pid, :get_trie)
    end)
    
    # It should eventually reply with the map
    assert is_map(Task.await(task))
  end
end
