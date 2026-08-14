# Requirement
- [Go Installed](https://golang.org/doc/install)

# Usage
refer to [Extending Caddy](https://caddyserver.com/docs/extending-caddy)

## 1. **Install [xcaddy](https://github.com/caddyserver/xcaddy)**

```sh
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
```

## 2. Development

- build release version
```sh
xcaddy build master --with github.com/crackeer/caddyupload2dir --embed template:./template
```

- build debug version
```sh
xcaddy build master --with github.com/crackeer/caddyupload2dir=./ --embed template:./template --debug
```

# Example:caddy.json
apps.http.servers下的一个配置
```json
{
    "static": {
        "idle_timeout": 30000000000,
        "listen": [
            "0.0.0.0:80"
        ],
        "max_header_bytes": 10240000,
        "read_header_timeout": 10000000000,
        "routes": [
            {
                "match": [
                    {
                        "method": ["POST", "PUT", "DELETE"]
                    }
                ],
                "handle": [
                    {
                        "handler": "upload2dir",
                        "file_server_root": "/your/file/dir",
                        "admin_password": "replace-with-a-strong-password"
                    }
                ],
                "terminal": true
            },
            {
                "handle": [
                    {
                        "handler": "file_server",
                        "root": "/your/file/dir",
                        "browse": {
                            "template_file": "/new/template.html"
                        },
                        "index_names": [""]
                    }
                ]
            }
        ]
    }
}
```

## 管理员删除密码
设置可选的 `admin_password` 后，删除文件或空目录时，页面会提示输入管理员密码。密码仅通过 `X-Admin-Password` 请求头提交，插件在服务端校验通过后才执行删除；未配置该项时保留原有的无密码删除行为，以兼容旧配置。

Caddyfile 配置示例：

```caddyfile
upload2dir {
    file_field_name file
    admin_password replace-with-a-strong-password
}
```

请仅通过 HTTPS 提供该页面，避免密码在传输中暴露；不要将真实密码提交到版本库。

## what new filer_server page looks like?
- Add create directory in current directory、upload file to current directory、delete file or empty directory
- Uploading a file with an existing name preserves the existing file and stores the upload as `{FILE_NAME}-{timestamp}`.

[![pppwtDU.png](https://s1.ax1x.com/2023/02/26/pppwtDU.png)](https://imgse.com/i/pppwtDU)

## Build & Install as a systemd service

`build.sh` compiles a caddy binary that bundles this local plugin and assembles an
installable package under `dist/`:

```sh
./build.sh            # build against caddy master
./build.sh v2.6.4     # or a specific caddy version
```

The `dist/` directory contains `caddy`, `template.html`, `caddy.json`,
`caddy-upload2dir.service` and `install.sh`. Copy that directory to the target Linux
machine (with systemd) and run:

```sh
sudo ./install.sh
```

`install.sh` copies the `caddy` binary and `template.html` into `/usr/local/caddy/`,
installs `caddy.json` there (only when a config is not already present), installs the
`caddy-upload2dir.service` unit into `/etc/systemd/system/`, then reloads systemd and
enables + starts the service.

Useful commands after install:

```sh
systemctl status caddy-upload2dir.service
journalctl -u caddy-upload2dir.service -f
```

> Note: the shipped `caddy.json` uses development paths. Before installing, set
> `file_server_root` to the directory you want to serve and point
> `browse.template_file` at `/usr/local/caddy/template.html`. Set a strong
> `admin_password` before exposing the service beyond a trusted network.
