defmodule SquaredleSolverWeb.SolverLive do
  use SquaredleSolverWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_dictionary)
    end

    {:ok, assign(socket, grid: "", words: [], trie: %{}, loading: true), layout: false}
  end

  def handle_info(:load_dictionary, socket) do
    trie = SquaredleSolver.DictionaryServer.get_trie()
    {:noreply, assign(socket, trie: trie, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="overscroll-none h-full bg-white">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>SQUAREDLE-SOLVER</title>
        <script src="https://cdn.tailwindcss.com">
        </script>
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
        </script>
      </head>
      <body class="overscroll-none h-full bg-white text-black font-mono selection:bg-black selection:text-white">
        <div class="flex flex-col items-center justify-center min-h-screen p-4 sm:p-8">
          <div class="w-full max-w-xl">
            <h1 class="text-4xl sm:text-5xl font-black mb-10 tracking-widest border-b-4 border-black pb-4 text-center uppercase">
              SQUAREDLE-SOLVER
            </h1>

            <div class="flex flex-col gap-8">
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
                    <span class="text-xs font-bold text-gray-500 uppercase tracking-wider">
                      '-' rows, space gaps
                    </span>
                  </div>
                  <input
                    type="text"
                    name="grid"
                    value={@grid}
                    placeholder="abcd-efgh-ijkl-mnop"
                    class="border-4 border-black p-4 sm:p-6 text-2xl tracking-[0.2em] uppercase font-black text-center focus:outline-none focus:ring-4 focus:ring-black placeholder:text-gray-200 transition-all shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] focus:translate-y-1 focus:translate-x-1 focus:shadow-none"
                  />
                </div>

                <div class="flex flex-col sm:flex-row gap-4 mt-4">
                  <button
                    type="submit"
                    disabled={@loading}
                    class={[
                      "flex-1 p-4 font-black text-xl uppercase tracking-widest border-4 border-black transition-all",
                      if(@loading,
                        do: "opacity-50 cursor-not-allowed bg-gray-100 text-gray-400 border-gray-400",
                        else:
                          "bg-white text-black hover:bg-black hover:text-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-y-1 hover:translate-x-1 hover:shadow-none active:bg-gray-800"
                      )
                    ]}
                  >
                    <%= if @loading do %>
                      Loading...
                    <% else %>
                      Solve
                    <% end %>
                  </button>

                  <button
                    type="button"
                    phx-click="solve_daily"
                    disabled={@loading}
                    class={[
                      "flex-1 p-4 font-black text-lg uppercase tracking-widest border-4 border-black transition-all",
                      if(@loading,
                        do: "opacity-50 cursor-not-allowed bg-gray-100 text-gray-400 border-gray-400",
                        else:
                          "bg-[#e53e3e] text-white hover:bg-[#c53030] shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-y-1 hover:translate-x-1 hover:shadow-none active:bg-[#9b2c2c]"
                      )
                    ]}
                  >
                    Daily Squaredle
                  </button>
                </div>
              </.form>

              <%= if length(@words) > 0 do %>
                <div class="border-4 border-black p-6 sm:p-8 flex flex-col gap-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white mt-4">
                  <div class="flex justify-between items-end border-b-4 border-black pb-4">
                    <h2 class="text-2xl font-black uppercase tracking-widest">
                      Words Found
                    </h2>
                    <span class="text-xl font-black bg-black text-white px-3 py-1">
                      {length(@words)}
                    </span>
                  </div>

                  <div class="flex flex-col gap-8">
                    <%= for {len, group_words} <- group_by_length(@words) do %>
                      <div class="flex flex-col gap-4">
                        <div class="flex items-center gap-4">
                          <h3 class="text-sm font-black uppercase tracking-widest whitespace-nowrap bg-black text-white px-3 py-1">
                            {len} Letters
                          </h3>
                          <div class="h-1 w-full bg-black/10"></div>
                        </div>
                        <div class="flex flex-wrap gap-2 sm:gap-3">
                          <%= for word <- group_words do %>
                            <span class="bg-white border-2 border-black px-3 py-1.5 text-sm font-bold uppercase tracking-widest hover:bg-black hover:text-white transition-colors cursor-default shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] hover:translate-y-[1px] hover:translate-x-[1px] hover:shadow-[1px_1px_0px_0px_rgba(0,0,0,1)]">
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
      </body>
    </html>
    """
  end

  def handle_event("update", %{"grid" => grid}, socket) do
    {:noreply, assign(socket, grid: grid)}
  end

  def handle_event("solve", %{"grid" => grid}, socket) do
    if socket.assigns.loading do
      {:noreply, assign(socket, grid: grid)}
    else
      {grid_map, size} = SquaredleSolver.Solver.parse_grid(String.downcase(grid))

      words =
        SquaredleSolver.Solver.solve(grid_map, size, socket.assigns.trie)
        |> Enum.sort_by(&{String.length(&1), &1}, :desc)

      {:noreply, assign(socket, grid: grid, words: words)}
    end
  end

  def handle_event("solve_daily", _, socket) do
    if socket.assigns.loading do
      {:noreply, socket}
    else
      case SquaredleSolver.DailyFetcher.fetch_today_puzzle() do
        {:ok, grid_str} ->
          {grid_map, size} = SquaredleSolver.Solver.parse_grid(String.downcase(grid_str))

          words =
            SquaredleSolver.Solver.solve(grid_map, size, socket.assigns.trie)
            |> Enum.sort_by(&{String.length(&1), &1}, :desc)

          {:noreply, assign(socket, grid: grid_str, words: words)}

        {:error, _reason} ->
          # Just ignore for now
          {:noreply, socket}
      end
    end
  end

  defp group_by_length(words) do
    words
    |> Enum.group_by(&String.length/1)
    |> Enum.sort_by(fn {len, _} -> len end, :desc)
  end
end
