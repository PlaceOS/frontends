FROM crystallang/crystal:0.34.0-alpine as builder

WORKDIR /build

COPY shard.yml /build
COPY shard.lock /build
RUN shards install --production --static

COPY src /build/src
RUN crystal build --error-trace --static --release --debug -o bin/frontend-loader src/app.cr

FROM alpine:3.11
WORKDIR /app

RUN apk add --no-cache git

COPY --from=builder /build/bin /app/bin

# Run the app binding on port 3000
EXPOSE 3000
HEALTHCHECK CMD wget -qO- http://localhost:3000/api/frontends/v1
CMD ["/app/bin/frontend-loader", "-b", "0.0.0.0", "-p", "3000"]
