defmodule SquaredleSolver.DailyFetcherTest do
  use ExUnit.Case

  test "extract_grid_from_js parses full daily object" do
    js = """
    const gTodayDateStr = '2026/02/25';
    const config = {
      "2026\\/02\\/25-xp": { "board": ["no"] },
      "2026\\/02\\/25": { "board": ["yes", "yes"] }
    }
    """
    assert {:ok, "yes-yes"} = SquaredleSolver.DailyFetcher.extract_grid_from_js_exported(js)
  end

  test "extract_grid_from_js fallback to basic" do
    js = """
    "board": ["a", "b"]
    """
    assert {:ok, "a-b"} = SquaredleSolver.DailyFetcher.extract_grid_from_js_exported(js)
  end

  test "extract_grid_from_js fails correctly" do
    js = """
    "no_board_here"
    """
    assert {:error, "Could not locate board array in response"} = SquaredleSolver.DailyFetcher.extract_grid_from_js_exported(js)
  end

  test "extract_grid_from_js handles missing board inner array" do
    js = """
    "board": []
    """
    assert {:error, "Board array found but no rows extracted"} = SquaredleSolver.DailyFetcher.extract_grid_from_js_exported(js)
  end
end
