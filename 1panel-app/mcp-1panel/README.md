# 1Panel MCP Server 本地应用

将 [mcp-1panel](https://github.com/1Panel-dev/mcp-1panel) 打包为 1Panel 本地应用。应用以内置的 Linux 二进制构建 Docker 镜像，启动 Streamable HTTP 传输，使用明文 HTTP + Bearer Token 鉴权，由外部 Nginx 终止 TLS。

## 生成应用包

在项目根目录执行：

```bash
make package-1panel-app
```

该命令会：

1. 交叉编译 Linux `amd64` / `arm64` 二进制到 `1panel-app/mcp-1panel/0.2.0/`；
2. 生成 `dist/mcp-1panel-0.2.0-1panel-app.tar.gz`。

## 安装

将压缩包上传到 1Panel 服务器后解压到本地应用目录（默认安装路径为 `/opt/1panel`）：

```bash
tar -xzf mcp-1panel-0.2.0-1panel-app.tar.gz -C /opt/1panel/resource/apps/local/
```

然后在 1Panel「应用商店」中点击「更新应用列表」，在「本地」分类中安装 `1Panel MCP Server`。

> 应用镜像在安装时由包内的 Linux 二进制本地构建，没有远程镜像。安装时请展开「高级设置」，**取消勾选「拉取镜像」**，否则 1Panel 会尝试从镜像仓库拉取不存在的镜像导致安装失败。

## 安装参数

| 参数 | 说明 |
|---|---|
| 1Panel 地址 | 容器访问 1Panel 的地址，默认 `http://host.docker.internal:9999`，请按面板实际端口/域名修改 |
| 1Panel API 密钥 | 在 1Panel「面板设置 → API 接口」中创建 |
| MCP 访问令牌 | 客户端调用 MCP 时使用的 Bearer Token，默认自动追加随机串 |
| 工具权限级别 | `readonly`（默认）、`readwrite`、`full` |
| 端口 | 容器映射到宿主机 `127.0.0.1` 的明文 HTTP 端口，默认 `8000`，供本机 Nginx 反向代理 |

## Nginx 反向代理

服务在容器内监听明文 HTTP，证书由外部 Nginx 配置。示例：

```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name mcp.example.com;

    ssl_certificate     /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location /mcp {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Streamable HTTP / SSE 需要关闭缓冲并放宽超时
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        chunked_transfer_encoding on;
    }
}
```

> 应用默认将端口绑定到 `127.0.0.1`。如果 Nginx 运行在其他容器中，请把 compose 的 `ports` 改为 `${PANEL_APP_PORT_HTTP}:8000`，并通过防火墙或 1Panel 安全组限制来源。

## 客户端配置

MCP 端点：`https://mcp.example.com/mcp`

```json
{
  "mcpServers": {
    "mcp-1panel": {
      "url": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer <MCP 访问令牌>"
      }
    }
  }
}
```

客户端只需信任 Nginx 使用的正式证书，不再需要信任服务端自签 CA。

## 安全说明

- 默认以 `readonly` 权限运行，仅在明确需要时提升为 `readwrite` / `full`。
- 明文 HTTP 仅允许在显式设置 `-allow-plaintext-http` 且配置 MCP 令牌时监听非回环地址；应用已在 compose 中固定该组合。
- 容器端口默认只绑定宿主机 `127.0.0.1`，请勿将明文端口直接暴露到公网。
- 浏览器类客户端会携带 `Origin`，默认仅放行本机来源；如需从 Web 客户端访问，请自行在 compose 的 `command` 中追加 `-allowed-origins`。
