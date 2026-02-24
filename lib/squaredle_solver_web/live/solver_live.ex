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
    <html lang="en" class="overscroll-none h-full bg-zinc-50">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>SQUAREDLE-SOLVER</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}></script>
      </head>
      <body class="overscroll-none h-full bg-zinc-50 text-zinc-900 font-mono antialiased">
        <div class="flex flex-col items-center min-h-screen py-16 px-4">
          <div class="w-full max-w-lg flex flex-col items-center">
            
            <h1 class="text-4xl sm:text-5xl font-black mb-12 uppercase tracking-[0.2em] border-b-[6px] border-zinc-900 pb-4 w-full text-center">
              SQUAREDLE
            </h1>

            <div class="w-full bg-white p-8 border-[3px] border-zinc-900 shadow-[8px_8px_0px_0px_rgba(24,24,27,1)] flex flex-col gap-8">
              <.form
                for={%{}}
                as={:solver}
                phx-submit="solve"
                phx-change="update"
                class="flex flex-col gap-6"
              >
                <div class="flex flex-col gap-3">
                  <label class="text-xs uppercase font-bold tracking-widest text-zinc-500">
                    Input Grid (use '-' for rows, space for gaps)
                  </label>
                  <input
                    type="text"
                    name="grid"
                    value={@grid}
                    placeholder="abcd-efgh-ijkl-mnop"
                    class="w-full bg-zinc-100 border-[3px] border-zinc-900 p-4 sm:p-5 text-xl sm:text-2xl tracking-[0.2em] uppercase font-bold text-center focus:outline-none focus:ring-0 focus:bg-white transition-colors placeholder:text-zinc-300 placeholder:tracking-[0.1em]"
                  />
                </div>

                <button
                  type="submit"
                  disabled={@loading}
                  class={["w-full p-5 font-black text-xl uppercase tracking-[0.15em] border-[3px] border-zinc-900 transition-all",
                         if(@loading, 
                            do: "bg-zinc-200 text-zinc-400 cursor-wait shadow-none", 
                            else: "bg-zinc-900 text-white shadow-[4px_4px_0px_0px_rgba(24,24,27,1)] hover:translate-y-[2px] hover:translate-x-[2px] hover:shadow-[2px_2px_0px_0px_rgba(24,24,27,1)] active:translate-y-[4px] active:translate-x-[4px] active:shadow-none cursor-pointer")]}
                >
                  <%= if @loading do %>
                    Loading...
                  <% else %>
                    Solve Puzzle
                  <% end %>
                </button>
              </.form>
            </div>

            <%= if length(@words) > 0 do %>
              <div class="w-full mt-12 bg-white border-[3px] border-zinc-900 p-8 shadow-[8px_8px_0px_0px_rgba(24,24,27,1)]">
                <div class="flex justify-between items-baseline border-b-[3px] border-zinc-900 pb-4 mb-6">
                  <h2 class="text-2xl font-black uppercase tracking-widest">
                    Words
                  </h2>
                  <span class="text-lg font-bold bg-zinc-900 text-white px-3 py-1">
                    <%= length(@words) %>
                  </span>
                </div>
                
                <div class="flex flex-col gap-8">
                  <%= for {len, group_words} <- group_by_length(@words) do %>
                    <div class="flex flex-col gap-3">
                      <div class="flex items-center gap-4">
                        <h3 class="text-sm font-bold uppercase tracking-widest text-zinc-500 whitespace-nowrap"><%= len %> Letters</h3>
                        <div class="h-[2px] w-full bg-zinc-200"></div>
                      </div>
                      <div class="flex flex-wrap gap-2 sm:gap-3">
                        <%= for word <- group_words do %>
                          <span class="bg-zinc-100 border-2 border-zinc-900 px-3 py-1.5 text-sm sm:text-base font-bold uppercase tracking-wider hover:bg-zinc-900 hover:text-white transition-colors cursor-default">
                            <%= word %>
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

  defp group_by_length(words) do
    words
    |> Enum.group_by(&String.length/1)
    |> Enum.sort_by(fn {len, _} -> len end, :desc)
  end
end
