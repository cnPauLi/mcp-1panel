# 1Panel MCP Server 本地应用

将 [mcp-1panel](https://github.com/1Panel-dev/mcp-1panel) 打包为 1Panel 本地应用。应用以内置的 Linux 二进制构建 Docker 镜像，启动 Streamable HTTP 传输并提供 HTTPS + Bearer Token 鉴权。

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
| TLS 证书地址 | 写入 HTTPS 证书 SAN 的域名/IP，必须包含客户端实际访问使用的地址，如 `mcp.example.com,192.168.1.10` |
| 端口 | 对外暴露的 HTTPS 端口，默认 `8000` |

> TLS 证书在容器首次启动时生成。修改「TLS 证书地址」后重启应用即可自动重新签发服务端证书，CA 不变。

## 客户端配置

MCP 端点：`https://<服务器地址>:<端口>/mcp`

```json
{
  "mcpServers": {
    "mcp-1panel": {
      "url": "https://mcp.example.com:8000/mcp",
      "headers": {
        "Authorization": "Bearer <MCP 访问令牌>"
      }
    }
  }
}
```

服务端使用本地自签 CA，客户端必须信任该 CA（不要关闭证书校验）。CA 文件位于实例数据目录：

```text
/opt/1panel/apps/local/mcp-1panel/<实例名>/data/tls/ca.crt
```

Node 系客户端可通过环境变量信任：

```bash
export NODE_EXTRA_CA_CERTS=/opt/1panel/apps/local/mcp-1panel/<实例名>/data/tls/ca.crt
```

也可以将 `ca.crt` 导入系统或客户端证书库。首次启动时应用日志会输出 CA 路径和 SHA-256 指纹，可用于核对。

## 安全说明

- 默认以 `readonly` 权限运行，仅在明确需要时提升为 `readwrite` / `full`。
- 监听非回环地址必须使用 HTTPS + `-allow-remote-http` + 令牌，应用已在 compose 中固定该组合。
- 浏览器类客户端会携带 `Origin`，默认仅放行本机来源；如需从 Web 客户端访问，请自行在 compose 的 `command` 中追加 `-allowed-origins`。
