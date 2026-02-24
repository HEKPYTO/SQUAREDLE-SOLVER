defmodule SquaredleSolverWeb.SolverLiveTest do
  use SquaredleSolverWeb.ConnCase
  import Phoenix.LiveViewTest

  test "disconnected and connected mount", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "SQUAREDLE-SOLVER"
    assert render(page_live) =~ "SQUAREDLE-SOLVER"
  end

  test "disconnected mount with missing dictionary", %{conn: conn} do
    # Create a mock test where connected?(socket) is false
    conn = Plug.Conn.assign(conn, :live_socket_id, nil)
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "SQUAREDLE-SOLVER"
  end

  test "submits grid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html =
      view
      |> form("form", %{"grid" => "xyz"})
      |> render_submit()

    assert html =~ "Found Words (0)"
  end

  test "changes grid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html =
      view
      |> form("form", %{"grid" => "xyza"})
      |> render_change()

    assert html =~ "xyza"
  end
end
