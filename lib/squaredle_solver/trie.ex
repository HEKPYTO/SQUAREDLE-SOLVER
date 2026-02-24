defmodule SquaredleSolver.Trie do
  @moduledoc """
  A simple, fast in-memory Trie data structure for prefix matching.
  """

  @doc """
  Initializes an empty Trie map.
  """
  def new do
    %{}
  end

  @doc """
  Inserts a word into the Trie.
  """
  def insert(trie, word) when is_binary(word) do
    do_insert(trie, String.graphemes(word))
  end

  defp do_insert(trie, []) do
    Map.put(trie, :end_of_word, true)
  end

  defp do_insert(trie, [char | rest]) do
    child = Map.get(trie, char, %{})
    Map.put(trie, char, do_insert(child, rest))
  end

  @doc """
  Checks if a word is in the Trie as a full word (`:found`), 
  a valid prefix (`:prefix`), or missing (`:not_found`).
  """
  def check(trie, word) when is_binary(word) do
    do_check(trie, String.graphemes(word))
  end

  defp do_check(_trie, []) do
    :not_found
  end

  defp do_check(trie, [char]) do
    case Map.get(trie, char) do
      nil -> :not_found
      child -> if Map.get(child, :end_of_word), do: :found, else: :prefix
    end
  end

  defp do_check(trie, [char | rest]) do
    case Map.get(trie, char) do
      nil -> :not_found
      child -> do_check(child, rest)
    end
  end

  @doc """
  Loads words from a text file into the Trie. Filters words shorter than 4 characters.
  """
  def from_file(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&(String.length(&1) >= 4))
    |> Enum.reduce(new(), &insert(&2, &1))
  end
end
