defmodule SquaredleSolver.Solver do
  @moduledoc """
  Core solver logic using Depth First Search and Bitmasking to find words in a Squaredle grid.
  """

  @dirs [{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}]

  @doc """
  Solves a given grid using a pre-populated Trie of valid words.

  Returns a list of unique valid words.
  """
  def solve(grid_map, size, trie) do
    Task.async_stream(
      grid_map,
      fn {{r, c}, _char} ->
        dfs({r, c}, grid_map, size, trie, "", 0)
      end,
      ordered: false
    )
    |> Enum.reduce(MapSet.new(), fn {:ok, words}, acc ->
      MapSet.union(acc, words)
    end)
    |> Enum.to_list()
  end

  defp dfs({r, c}, grid_map, size, trie, word_so_far, visited_mask) do
    char = Map.get(grid_map, {r, c})

    if is_nil(char) do
      MapSet.new()
    else
      new_word = word_so_far <> char
      new_mask = Bitwise.bor(visited_mask, Bitwise.bsl(1, r * size + c))

      case SquaredleSolver.Trie.check(trie, new_word) do
        :not_found ->
          MapSet.new()

        status ->
          words =
            @dirs
            |> Enum.reduce(MapSet.new(), fn {dr, dc}, acc ->
              nr = r + dr
              nc = c + dc

              if nr >= 0 and nr < size and nc >= 0 and nc < size do
                if Bitwise.band(new_mask, Bitwise.bsl(1, nr * size + nc)) == 0 do
                  MapSet.union(acc, dfs({nr, nc}, grid_map, size, trie, new_word, new_mask))
                else
                  acc
                end
              else
                acc
              end
            end)

          if status == :found and String.length(new_word) >= 4 do
            MapSet.put(words, new_word)
          else
            words
          end
      end
    end
  end

  @doc """
  Parses a string representation of the grid into a map of coordinates to characters.
  Gaps are represented by spaces and mapped to `nil`.
  """
  def parse_grid(grid_str) do
    rows = String.split(grid_str, "-")
    size = length(rows)

    grid_map =
      rows
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, r} ->
        row
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.map(fn {char, c} -> {{r, c}, if(char == " ", do: nil, else: char)} end)
        |> Enum.reject(fn {_, char} -> is_nil(char) end)
      end)
      |> Map.new()

    {grid_map, size}
  end
end
