FROM alpine:3.20

RUN apk add --no-cache ca-certificates

COPY mcp-1panel-linux-amd64 mcp-1panel-linux-arm64 /tmp/

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      aarch64|arm64) cp /tmp/mcp-1panel-linux-arm64 /usr/local/bin/mcp-1panel ;; \
      *) cp /tmp/mcp-1panel-linux-amd64 /usr/local/bin/mcp-1panel ;; \
    esac; \
    chmod +x /usr/local/bin/mcp-1panel; \
    rm -f /tmp/mcp-1panel-linux-*

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/mcp-1panel"]
