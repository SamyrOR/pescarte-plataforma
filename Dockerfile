# ---- Builder Stage ----
FROM bitwalker/alpine-elixir:latest AS builder

MAINTAINER matdsoupe

RUN apk add --no-cache build-base

RUN mkdir /app
WORKDIR /app

ENV MIX_ENV=prod

# Cache elixir deps
ADD ./mix.exs ./mix.lock ./
RUN mix do local.rebar, local.hex --force
RUN mix do deps.get, deps.compile

COPY lib ./lib
COPY config ./config
COPY priv ./priv

RUN mix release

# ---- Application Stage ----
FROM alpine AS app

ENV MIX_ENV=prod

# Install needed packages
RUN apk add --no-cache openssl \
      ncurses-libs postgresql-client

# Copy over the build artifact from the previous step and create a non root user
RUN adduser -D -h /home/fuschia fuschia
WORKDIR /home/fuschia
COPY --from=builder /app/_build .
RUN chown -R fuschia: ./prod

USER fuschia

COPY entrypoint.sh .

# Run the Phoenix app
CMD ["./entrypoint.sh"]