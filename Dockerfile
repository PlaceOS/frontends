FROM crystallang/crystal:1.0.0-alpine as builder

WORKDIR /build

COPY shard.yml .
COPY shard.override.yml .
COPY shard.lock .

RUN CRFLAGS="--static" shards install --production --ignore-crystal-version

COPY src /build/src

RUN crystal build --error-trace --static --release --no-debug -o bin/frontends src/app.cr

FROM alpine:3.11
WORKDIR /app

# Add trusted CAs for communicating with external services
RUN apk update && apk add --no-cache ca-certificates tzdata && update-ca-certificates

RUN apk add --no-cache git openssh

COPY --from=builder /build/bin /app/bin

# Run the app binding on port 3000
EXPOSE 3000
HEALTHCHECK CMD wget -qO- http://localhost:3000/api/frontends/v1
CMD ["/app/bin/frontends", "-b", "0.0.0.0", "-p", "3000"]
