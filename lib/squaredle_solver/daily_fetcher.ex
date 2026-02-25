defmodule SquaredleSolver.DailyFetcher do
  @moduledoc """
  Fetches and parses the daily Squaredle puzzle from the official site.
  """
  require Logger

  @url "https://squaredle.app/api/today-puzzle-config.js"

  @doc """
  Fetches today's puzzle. Returns `{:ok, grid_string}` or `{:error, reason}`.
  """
  def fetch_today_puzzle do
    with {:ok, %Req.Response{status: 200, body: body}} <- Req.get(@url),
         {:ok, grid_str} <- extract_grid_from_js(body) do
      {:ok, grid_str}
    else
      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch daily puzzle: #{inspect(reason)}")
        {:error, "Failed to connect"}
    end
  end

  @doc false
  def extract_grid_from_js_exported(js_content), do: extract_grid_from_js(js_content)

  defp extract_grid_from_js(js_content) do
    today_date =
      case Regex.run(~r/gTodayDateStr\s*=\s*'([^']+)'/, js_content) do
        [_, date] -> String.replace(date, "/", "\\\\/")
        _ -> nil
      end

    regex =
      if today_date do
        # This matches the specific date key (no trailing characters like -xp)
        # then captures the very next "board" array.
        ~r/"#{today_date}"\s*:\s*\{.*?("board"\s*:\s*\[.*?\])/s
      else
        ~r/("board"\s*:\s*\[.*?\])/s
      end

    case Regex.run(regex, js_content) do
      [_, board_str] ->
        rows =
          Regex.scan(~r/"([^"]+)"/, board_str)
          |> Enum.filter(fn [_, row] -> row != "board" end)
          |> Enum.map(fn [_, row] -> row end)

        if length(rows) > 0 do
          grid_str = Enum.join(rows, "-")
          {:ok, grid_str}
        else
          {:error, "Board array found but no rows extracted"}
        end

      _ ->
        {:error, "Could not locate board array in response"}
    end
  end
end
