defmodule TestSolver do
  @dirs [{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}]

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

          if status == :found do
            MapSet.put(words, new_word)
          else
            words
          end
      end
    end
  end
end

trie = SquaredleSolver.Trie.new()
trie = SquaredleSolver.Trie.insert(trie, "pale")
{grid, size} = SquaredleSolver.Solver.parse_grid("ape-l z-dog")
words = TestSolver.solve(grid, size, trie)
IO.inspect(words)
