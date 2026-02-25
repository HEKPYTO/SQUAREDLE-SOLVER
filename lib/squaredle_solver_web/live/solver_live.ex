defmodule SquaredleSolverWeb.SolverLive do
  use SquaredleSolverWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_dictionary)
    end

    {:ok,
     assign(socket,
       grid: "",
       words: [],
       trie: %{},
       loading: true,
       solving: false,
       fetch_error: nil
     )}
  end

  def handle_info(:load_dictionary, socket) do
    trie = SquaredleSolver.DictionaryServer.get_trie()
    {:noreply, assign(socket, trie: trie, loading: false)}
  end

  def handle_info(:do_solve, socket) do
    grid_str = String.downcase(socket.assigns.grid)

    words =
      case :ets.lookup(:squaredle_cache, {"solve", grid_str}) do
        [{_, cached_words}] ->
          cached_words

        [] ->
          {grid_map, size} = SquaredleSolver.Solver.parse_grid(grid_str)

          computed_words =
            SquaredleSolver.Solver.solve(grid_map, size, socket.assigns.trie)
            |> Enum.sort_by(&{String.length(&1), &1}, :desc)

          :ets.insert(:squaredle_cache, {{"solve", grid_str}, computed_words})
          computed_words
      end

    {:noreply, assign(socket, words: words, solving: false)}
  end

  def handle_info(:do_solve_daily, socket) do
    case :ets.lookup(:squaredle_cache, :daily) do
      [{_, {grid_str, words}}] ->
        {:noreply, assign(socket, grid: grid_str, words: words, solving: false, fetch_error: nil)}

      [] ->
        case SquaredleSolver.DailyFetcher.fetch_today_puzzle() do
          {:ok, grid_str, words} ->
            words =
              if words == [] do
                {grid_map, size} = SquaredleSolver.Solver.parse_grid(String.downcase(grid_str))
                SquaredleSolver.Solver.solve(grid_map, size, socket.assigns.trie)
              else
                words
              end
              |> Enum.sort_by(&{String.length(&1), &1}, :desc)

            :ets.insert(:squaredle_cache, {:daily, {grid_str, words}})
            :ets.insert(:squaredle_cache, {{"solve", String.downcase(grid_str)}, words})

            {:noreply,
             assign(socket, grid: grid_str, words: words, solving: false, fetch_error: nil)}

          {:error, reason} ->
            {:noreply,
             assign(socket,
               solving: false,
               fetch_error: "Could not load today's puzzle: #{reason}"
             )}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen p-4 sm:p-8 pt-16">
      <div class="w-full max-w-xl">
        <h1 class="text-4xl sm:text-5xl font-black mb-10 tracking-widest border-b-4 border-black dark:border-white pb-4 text-center uppercase">
          SQUAREDLE-SOLVER
        </h1>

        <div class="flex flex-col gap-8">
          <%= if @fetch_error do %>
            <div class="bg-red-100 dark:bg-red-900 border-4 border-black dark:border-white p-4 font-bold text-center shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]">
              {@fetch_error}
            </div>
          <% end %>

          <.form
            for={%{}}
            as={:solver}
            phx-submit="solve"
            phx-change="update"
            class="flex flex-col gap-4"
          >
            <div class="flex flex-col gap-2">
              <div class="flex justify-between items-baseline">
                <label class="text-sm font-bold tracking-widest uppercase">
                  Input Grid
                </label>
                <span class="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  '-' rows, space gaps
                </span>
              </div>
              <input
                type="text"
                name="grid"
                value={@grid}
                placeholder="abcd-efgh-ijkl-mnop"
                class="border-4 border-black bg-white dark:border-white dark:bg-zinc-800 p-4 sm:p-6 text-2xl tracking-[0.2em] uppercase font-black text-center focus:outline-none placeholder:text-zinc-400 dark:placeholder:text-zinc-500 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:focus:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]"
              />
            </div>

            <div class="flex flex-col sm:flex-row gap-4 mt-4">
              <button
                type="submit"
                disabled={@loading or @solving or String.trim(@grid) == ""}
                class={[
                  "flex-1 p-4 font-black text-xl uppercase tracking-widest border-4 transition-all",
                  if(@loading or @solving or String.trim(@grid) == "",
                    do:
                      "cursor-not-allowed border-gray-400 dark:border-zinc-700 bg-gray-200 dark:bg-zinc-800 text-gray-400 dark:text-zinc-600 shadow-[4px_4px_0px_0px_#9ca3af] dark:shadow-[4px_4px_0px_0px_#3f3f46]",
                    else:
                      "border-black dark:border-white bg-white dark:bg-zinc-900 text-black dark:text-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:bg-black hover:text-white dark:hover:bg-white dark:hover:text-black hover:translate-y-[2px] hover:translate-x-[2px] hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] active:translate-y-[4px] active:translate-x-[4px] active:shadow-none"
                  )
                ]}
              >
                <%= cond do %>
                  <% @loading -> %>
                    Loading...
                  <% @solving -> %>
                    Solving...
                  <% true -> %>
                    Solve
                <% end %>
              </button>

              <button
                type="button"
                phx-click="solve_daily"
                disabled={@loading or @solving}
                class={[
                  "flex-1 p-4 font-black text-lg uppercase tracking-widest border-4 transition-all",
                  if(@loading or @solving,
                    do:
                      "cursor-not-allowed border-gray-400 dark:border-zinc-700 bg-gray-200 dark:bg-zinc-800 text-gray-400 dark:text-zinc-600 shadow-[4px_4px_0px_0px_#9ca3af] dark:shadow-[4px_4px_0px_0px_#3f3f46]",
                    else:
                      "border-black dark:border-white bg-[#e53e3e] text-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] hover:bg-[#c53030] hover:translate-y-[2px] hover:translate-x-[2px] hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] active:translate-y-[4px] active:translate-x-[4px] active:shadow-none"
                  )
                ]}
              >
                <%= if @solving do %>
                  Fetching...
                <% else %>
                  Daily Squaredle
                <% end %>
              </button>
            </div>
          </.form>

          <%= if length(@words) > 0 and not @solving do %>
            <div class="border-4 border-black dark:border-white p-6 sm:p-8 flex flex-col gap-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] dark:shadow-[8px_8px_0px_0px_rgba(255,255,255,1)] bg-white dark:bg-zinc-900 mt-4">
              <div class="flex justify-between items-end border-b-4 border-black dark:border-white pb-4">
                <h2 class="text-2xl font-black uppercase tracking-widest">
                  Words Found
                </h2>
                <span class="text-xl font-black bg-black dark:bg-white text-white dark:text-black px-3 py-1">
                  {length(@words)}
                </span>
              </div>

              <div class="flex flex-col gap-8">
                <%= for {len, group_words} <- group_by_length(@words) do %>
                  <div class="flex flex-col gap-4">
                    <div class="flex items-center gap-4">
                      <h3 class="text-sm font-black uppercase tracking-widest whitespace-nowrap bg-black dark:bg-white text-white dark:text-black px-3 py-1">
                        {len} Letters
                      </h3>
                      <div class="h-1 w-full bg-black/10 dark:bg-white/10"></div>
                    </div>
                    <div class="flex flex-wrap gap-2 sm:gap-3">
                      <%= for word <- group_words do %>
                        <span class="bg-white dark:bg-zinc-800 border-2 border-black dark:border-white px-3 py-1.5 text-sm font-bold uppercase tracking-widest hover:bg-black hover:text-white dark:hover:bg-white dark:hover:text-black transition-colors cursor-default shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] dark:shadow-[2px_2px_0px_0px_rgba(255,255,255,1)] hover:translate-y-[1px] hover:translate-x-[1px] hover:shadow-[1px_1px_0px_0px_rgba(0,0,0,1)] dark:hover:shadow-[1px_1px_0px_0px_rgba(255,255,255,1)]">
                          {word}
                        </span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update", %{"grid" => grid}, socket) do
    {:noreply, assign(socket, grid: grid)}
  end

  def handle_event("solve", %{"grid" => grid}, socket) do
    if socket.assigns.loading or socket.assigns.solving or String.trim(grid) == "" do
      {:noreply, assign(socket, grid: grid)}
    else
      send(self(), :do_solve)
      {:noreply, assign(socket, grid: grid, solving: true)}
    end
  end

  def handle_event("solve_daily", _, socket) do
    if socket.assigns.loading or socket.assigns.solving do
      {:noreply, socket}
    else
      send(self(), :do_solve_daily)
      {:noreply, assign(socket, solving: true, fetch_error: nil)}
    end
  end

  defp group_by_length(words) do
    words
    |> Enum.group_by(&String.length/1)
    |> Enum.map(fn {len, group_words} -> {len, Enum.sort(group_words)} end)
    |> Enum.sort_by(fn {len, _} -> len end, :desc)
  end
end
