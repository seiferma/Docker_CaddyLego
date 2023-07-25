FROM --platform=$BUILDPLATFORM golang:alpine AS builder

ARG TARGETARCH
ARG CADDY_VERSION=v2.6.4
ARG GOOS=linux
ARG CGOENABLED=0

RUN apk add --no-cache git
RUN GOARCH=$TARGETARCH && \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    xcaddy build --with github.com/caddy-dns/lego-deprecated
RUN apk add --no-cache libcap
RUN setcap cap_net_bind_service=+ep /go/caddy
RUN touch /tmp/empty



FROM scratch

ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

COPY --from=builder /go/caddy /bin/caddy
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /tmp/empty /etc/caddy/Caddyfile

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

