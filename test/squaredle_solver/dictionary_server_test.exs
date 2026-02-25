defmodule SquaredleSolver.DictionaryServerTest do
  use ExUnit.Case
  alias SquaredleSolver.DictionaryServer

  test "returns the loaded trie eventually" do
    trie = DictionaryServer.get_trie()
    assert is_map(trie)
    assert Map.has_key?(trie, "a")
  end

  test "handle_call queues callers when not loaded" do
    assert {:noreply, %{waiters: [:fake_from]}} =
             DictionaryServer.handle_call(:get_trie, :fake_from, %{loaded: false, waiters: []})
  end

  test "handle_info :load processes waiters" do
    # We spawn a process that just waits for a message so we can use it as a valid `from`
    # However, `GenServer.reply` expects `{pid, ref}`. We can just use `{self(), make_ref()}`
    # and then assert we received the message.
    ref = make_ref()
    from = {self(), ref}

    state = %{trie: nil, loaded: false, waiters: [from]}
    assert {:noreply, new_state} = DictionaryServer.handle_info(:load, state)
    assert new_state.loaded == true
    assert new_state.waiters == []

    assert_receive {^ref, trie}
    assert is_map(trie)
  end
end
