# SQUAREDLE-SOLVER

[![CI](https://github.com/HEKPYTO/SQUAREDLE-SOLVER/actions/workflows/ci.yml/badge.svg)](https://github.com/HEKPYTO/SQUAREDLE-SOLVER/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/HEKPYTO/SQUAREDLE-SOLVER/badge.svg)](https://coveralls.io/github/HEKPYTO/SQUAREDLE-SOLVER)
[![Elixir Version](https://img.shields.io/badge/elixir-1.16.2-purple.svg)](https://elixir-lang.org/)
[![Phoenix Version](https://img.shields.io/badge/phoenix-1.8.4-orange.svg)](https://www.phoenixframework.org/)

A highly optimized, fast full-stack Elixir/Phoenix solver for the popular word-finding game [Squaredle](https://squaredle.app). 

Built to demonstrate the concurrency power of the Erlang VM (BEAM) using parallelized Depth-First Search (DFS) combined with an in-memory Prefix Trie and bitmask path validation.

## Features

- Optimal Core Algorithm: Parallel processing via `Task.async_stream`, utilizing Bitwise integer masking for instant path-validation without memory overhead, backed by a deeply nested Elixir Map functioning as a Prefix Trie.
- Robust Edge Case Support: Capable of handling arbitrary grid sizes and irregular board shapes (grids with gaps).
- Instant Dictionary: Implements an async `DictionaryServer` (GenServer) on application boot to pre-warm the Trie into BEAM memory for instantaneous 0-latency dictionary lookups.
- Daily Puzzle Fetching: Connects to the official site and extracts today's puzzle configuration via an isolated HTTP Regex crawler using `Req`.
- Minimalist Neo-brutalist Phoenix LiveView UI: A clean, stark interactive frontend heavily driven by Tailwind CSS. State handling, form interactions, and solving happen instantaneously over WebSockets without JavaScript.
- 100% Core Test Coverage: Strictly developed through Document Driven Development (DDD) and Test Driven Development (TDD) via `ExCoveralls`.
- Production Ready: Ships with a minimal Multi-stage Alpine Dockerfile and Docker Compose orchestration completely free of CORS/Origin constraints, allowing perfect Traefik/Cloudflare proxying.

---

## Prerequisites

If running locally without Docker:
* [Elixir](https://elixir-lang.org/install.html) 1.16+
* Erlang/OTP 26+

If running via Docker:
* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

---

## Quickstart (Docker)

The fastest way to get the solver running is via the included `docker-compose.yml`.

```bash
# Clone the repository
git clone https://github.com/HEKPYTO/SQUAREDLE-SOLVER.git
cd SQUAREDLE-SOLVER

# Build the release and boot the server
docker compose up --build -d
```

Visit the application at [`http://localhost:4000`](http://localhost:4000).

---

## Local Development

To start your Phoenix server locally without Docker:

1. Install dependencies:
   ```bash
   mix deps.get
   ```

2. Run the application:
   ```bash
   mix phx.server
   ```
   Or inside IEx (Interactive Elixir):
   ```bash
   iex -S mix phx.server
   ```

Visit [`http://localhost:4000`](http://localhost:4000) from your browser.

---

## Testing & CI/CD

This project strictly adheres to TDD principles and utilizes `excoveralls` to enforce a 100% code coverage threshold on core logic. 

Run the test suite and verify coverage:
```bash
MIX_ENV=test mix coveralls
```

The repository includes a GitHub Actions workflow (`.github/workflows/ci.yml`) that automatically runs on `push` and `pull_request`. The CI pipeline enforces:
1. Standard Elixir Code Formatting (`mix format --check-formatted`)
2. Zero Compilation Warnings (`mix compile --warnings-as-errors`)
3. Unit Tests & Coverage Verification (`mix coveralls`)

---

## Document Driven Development

All core modules are documented thoroughly using `@moduledoc` and `@doc`. You can generate the HTML documentation locally using ExDoc:

```bash
# Generate docs
mix docs
```

Open `doc/index.html` to view the comprehensive API reference.

---

## Algorithmic Deep Dive

1. Prefix Trie: The English dictionary (words >= 4 letters) is parsed into a deeply nested Elixir map. Map lookups in the BEAM are O(1) per character, enabling instant prefix rejection.
2. Parallel DFS: Instead of searching sequentially, a separate lightweight process is spawned for each starting letter on the grid using `Task.async_stream`.
3. Bitmasking: Tracking the visited cells in a standard List or Set creates immense garbage collection pressure in deep recursion. Since Squaredle boards are small (e.g., 4x4 or 5x5), the visited path is tracked using a single 32-bit integer, relying on bitwise `bor` and `band` operations.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
