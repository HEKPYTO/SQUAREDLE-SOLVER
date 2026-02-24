defmodule SquaredleSolver.DictionaryServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_trie do
    GenServer.call(__MODULE__, :get_trie)
  end

  @impl true
  def init(_) do
    # Trigger loading in a background process immediately after init
    send(self(), :load)
    {:ok, %{trie: nil, loaded: false, waiters: []}}
  end

  @impl true
  def handle_info(:load, state) do
    path = Application.app_dir(:squaredle_solver, "priv/dictionary.txt")
    trie = SquaredleSolver.Trie.from_file(path)
    
    # Reply to any waiting processes
    Enum.each(state.waiters, fn from ->
      GenServer.reply(from, trie)
    end)
    
    {:noreply, %{trie: trie, loaded: true, waiters: []}}
  end

  @impl true
  def handle_call(:get_trie, from, %{loaded: false} = state) do
    {:noreply, %{state | waiters: [from | state.waiters]}}
  end

  @impl true
  def handle_call(:get_trie, _from, %{loaded: true, trie: trie} = state) do
    {:reply, trie, state}
  end
end
