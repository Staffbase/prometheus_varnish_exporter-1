FROM golang:1.16 as builder

WORKDIR /workspace

COPY go.mod go.sum ./
COPY . ./

RUN go get -d -v ./...
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o prometheus_varnish_exporter

FROM debian:stretch-slim AS final

WORKDIR /

COPY --from=builder /workspace/prometheus_varnish_exporter .

RUN         set -x \
            && \
            apt-get -qq update && apt-get -qq upgrade \
            && \
            apt-get -qq install \
                debian-archive-keyring \
                curl \
                gnupg \
                apt-transport-https \
            && \
            curl -Ss -L https://packagecloud.io/varnishcache/varnish60lts/gpgkey | apt-key add - \
            && \
            printf "%s\n%s" \
                "deb https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" \
                "deb-src https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" \
            > "/etc/apt/sources.list.d/varnishcache_varnish60lts.list" \
            && \
            apt-get -qq update && apt-get -qq install varnish \
            && \
            apt-get -qq purge curl gnupg apt-transport-https && \
            apt-get -qq autoremove && apt-get -qq autoclean && \
            rm -rf /var/cache/*

USER 65532:65532

ENTRYPOINT ["./prometheus_varnish_exporter"]
