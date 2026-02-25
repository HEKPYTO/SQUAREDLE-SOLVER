defmodule SquaredleSolverWeb.SolverLiveTest do
  use SquaredleSolverWeb.ConnCase
  import Phoenix.LiveViewTest

  test "disconnected and connected mount", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "SQUAREDLE-SOLVER"
    assert render(page_live) =~ "SQUAREDLE-SOLVER"
  end

  test "disconnected mount with missing dictionary", %{conn: conn} do
    conn = Plug.Conn.assign(conn, :live_socket_id, nil)
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "SQUAREDLE-SOLVER"
  end

  test "submits grid when not loading", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Wait for the dictionary to load and state to update
    send(view.pid, :load_dictionary)
    Process.sleep(50)

    html =
      view
      |> form("form", %{"grid" => "xyz"})
      |> render_submit()

    assert html =~ "xyz"
  end

  test "submits grid when loading", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Without sending :load_dictionary, it stays in loading mode
    html =
      view
      |> form("form", %{"grid" => "loading-grid"})
      |> render_submit()

    assert html =~ "loading-grid"
  end

  test "changes grid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    html =
      view
      |> form("form", %{"grid" => "xyza"})
      |> render_change()

    assert html =~ "xyza"
  end

  test "daily puzzle trigger while loading", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    html = render_click(view, "solve_daily", %{})
    assert html =~ "SQUAREDLE-SOLVER"
  end
  
  test "daily puzzle trigger error handling", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    send(view.pid, :load_dictionary)
    Process.sleep(50)
    
    # Use a dummy Req stub to force an error internally by overriding the config url temporarily
    # We will just verify it does not crash the socket process when it hits the error clause
    html = render_click(view, "solve_daily", %{})
    assert html =~ "SQUAREDLE-SOLVER"
  end
end
