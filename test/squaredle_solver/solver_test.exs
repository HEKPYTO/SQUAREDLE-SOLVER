defmodule SquaredleSolver.SolverTest do
  use ExUnit.Case
  alias SquaredleSolver.Trie
  alias SquaredleSolver.Solver

  setup do
    trie =
      Trie.new()
      |> Trie.insert("apple")
      |> Trie.insert("ape")
      |> Trie.insert("peal")
      |> Trie.insert("leap")
      |> Trie.insert("pale")
      |> Trie.insert("lap")
      |> Trie.insert("pal")
      |> Trie.insert("zap")
      |> Trie.insert("dog")
      |> Trie.insert("god")

    {:ok, trie: trie}
  end

  test "parse_grid" do
    {grid, size} = Solver.parse_grid("abc-def-ghi")
    assert size == 3
    assert grid[{0, 0}] == "a"
    assert grid[{1, 1}] == "e"
    assert grid[{2, 2}] == "i"
    assert map_size(grid) == 9
  end

  test "parse_grid with spaces (gaps)" do
    {grid, size} = Solver.parse_grid("a b-cde-f g")
    assert size == 3
    assert grid[{0, 0}] == "a"
    assert grid[{0, 1}] == nil
    assert grid[{0, 2}] == "b"
    assert grid[{1, 1}] == "d"
    assert grid[{2, 1}] == nil
    assert map_size(grid) == 7
  end

  test "solve simple grid", %{trie: trie} do
    # a p x
    # x p e
    # x l x
    {grid, size} = Solver.parse_grid("apx-xpe-xlx")

    words = Solver.solve(grid, size, trie) |> Enum.into(MapSet.new())

    # In my logic, words must be >= 4 letters
    assert MapSet.member?(words, "apple")

    # 3 letters
    refute MapSet.member?(words, "ape")
    # pale is p-a... wait, p(1,1)->a(0,0)? Yes. a(0,0)->l(2,1)? No.
    refute MapSet.member?(words, "pale")
  end

  test "solve grid with gaps", %{trie: trie} do
    # a p x
    # x   e
    # x l x
    {grid, size} = Solver.parse_grid("apx-x e-xlx")

    words = Solver.solve(grid, size, trie) |> Enum.into(MapSet.new())

    refute MapSet.member?(words, "apple")
  end
end
