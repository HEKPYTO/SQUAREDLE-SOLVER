ARG ELIXIR_VERSION=1.16.2
ARG ALPINE_VERSION=3.19

ARG BUILDER_IMAGE="elixir:${ELIXIR_VERSION}-alpine"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apk add --no-cache build-base git python3 libstdc++

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./

RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.deploy

RUN mix compile

COPY config/runtime.exs config/

COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE}

RUN apk add --no-cache libstdc++ openssl ncurses-libs bash

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/squaredle_solver ./

USER nobody

CMD ["/app/bin/server"]
