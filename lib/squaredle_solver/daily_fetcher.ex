defmodule SquaredleSolver.DailyFetcher do
  @moduledoc """
  Fetches and parses the daily Squaredle puzzle from the official site.
  """
  require Logger

  @url "https://squaredle.app/api/today-puzzle-config.js"
  @char_map "5pyf0gcrl1a9oe3ui8d2htn67sqjkxbmw4vzPYFGCRLAOEUIDHTNSQJKXBMWVZ" |> String.graphemes()

  @doc """
  Fetches today's puzzle. Returns `{:ok, grid_string, words}` or `{:error, reason}`.
  """
  def fetch_today_puzzle(opts \\ []) do
    url = Keyword.get(opts, :url, Application.get_env(:squaredle_solver, :daily_puzzle_url, @url))

    with {:ok, %Req.Response{status: 200, body: body}} <- Req.get(url),
         {:ok, grid_str, words} <- extract_grid_and_words_from_js(body) do
      {:ok, grid_str, words}
    else
      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch daily puzzle: #{inspect(reason)}")
        {:error, "Failed to connect"}
    end
  end

  @doc false
  def extract_grid_and_words_from_js_exported(js_content),
    do: extract_grid_and_words_from_js(js_content)

  defp extract_grid_and_words_from_js(js_content) do
    today_date =
      case Regex.run(~r/gTodayDateStr\s*=\s*'([^']+)'/, js_content) do
        [_, date] -> String.replace(date, "/", "\\/")
        _ -> nil
      end

    key_string = if today_date, do: "\"#{today_date}\":", else: "\"board\":"

    case String.split(js_content, key_string, parts: 2) do
      [_, rest] ->
        [puzzle_block | _] = String.split(rest, ~r/,"20\d{2}\\\/\d{2}\\\/\d{2}/, parts: 2)

        board_match = Regex.run(~r/"board"\s*:\s*\[(.*?)\]/s, puzzle_block)

        if board_match do
          board_str = Enum.at(board_match, 1)

          rows =
            Regex.scan(~r/"([^"]+)"/, board_str)
            |> Enum.filter(fn [_, row] -> row != "board" end)
            |> Enum.map(fn [_, row] -> row end)

          if length(rows) > 0 do
            grid_str = Enum.join(rows, "-")

            words =
              case Regex.run(~r/"wordScores"\s*:\s*"([^"]+)"/, puzzle_block) do
                [_, encoded] -> decode_words(encoded)
                _ -> []
              end

            optional_words =
              case Regex.run(~r/"optionalWordScores"\s*:\s*"([^"]+)"/, puzzle_block) do
                [_, encoded] -> decode_words(encoded)
                _ -> []
              end

            {:ok, grid_str, words ++ optional_words}
          else
            {:error, "Board array found but no rows extracted"}
          end
        else
          # Fallback for simple tests
          case Regex.run(~r/("board"\s*:\s*\[.*?\])/s, js_content) do
            [_, board_str] ->
              rows =
                Regex.scan(~r/"([^"]+)"/, board_str)
                |> Enum.filter(fn [_, row] -> row != "board" end)
                |> Enum.map(fn [_, row] -> row end)

              if length(rows) > 0 do
                {:ok, Enum.join(rows, "-"), []}
              else
                {:error, "Board array found but no rows extracted"}
              end

            _ ->
              {:error, "Could not locate board array in response"}
          end
        end

      _ ->
        {:error, "Could not locate puzzle key in response"}
    end
  end

  defp decode_words(encoded) do
    encoded
    |> String.graphemes()
    |> Enum.map(fn char ->
      case Enum.find_index(@char_map, &(&1 == char)) do
        nil -> char
        idx -> Enum.at(@char_map, Integer.mod(idx - 12 + length(@char_map), length(@char_map)))
      end
    end)
    |> Enum.join()
    |> Base.decode64!(padding: false)
    |> String.split(",")
  end
end
