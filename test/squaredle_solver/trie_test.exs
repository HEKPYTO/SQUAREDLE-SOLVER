defmodule SquaredleSolver.TrieTest do
  use ExUnit.Case
  alias SquaredleSolver.Trie

  test "new/0" do
    assert Trie.new() == %{}
  end

  test "insert/2" do
    trie = Trie.new() |> Trie.insert("apple")
    assert Map.has_key?(trie, "a")
    assert trie["a"]["p"]["p"]["l"]["e"][:end_of_word] == true
  end

  test "check/2" do
    trie = Trie.new() |> Trie.insert("apple") |> Trie.insert("app")

    assert Trie.check(trie, "app") == :found
    assert Trie.check(trie, "appl") == :prefix
    assert Trie.check(trie, "apple") == :found
    assert Trie.check(trie, "apples") == :not_found
    assert Trie.check(trie, "banana") == :not_found
    assert Trie.check(trie, "a") == :prefix
  end

  test "check/2 empty" do
    assert Trie.check(Trie.new(), "") == :not_found
  end

  test "from_file/1" do
    File.write!("test_dict.txt", "apple\nbanana\ncat\ndog\n")
    trie = Trie.from_file("test_dict.txt")
    File.rm!("test_dict.txt")

    assert Trie.check(trie, "apple") == :found
    assert Trie.check(trie, "banana") == :found
    # cat and dog should be filtered because < 4 letters
    assert Trie.check(trie, "cat") == :not_found
    assert Trie.check(trie, "dog") == :not_found
  end
end
