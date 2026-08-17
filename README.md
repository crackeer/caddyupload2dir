# Requirement
- [Go Installed](https://golang.org/doc/install)

# Development
refer to [Extending Caddy](https://caddyserver.com/docs/extending-caddy)

## 1. Install [xcaddy](https://github.com/caddyserver/xcaddy)

```sh
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
```

## 2. build caddy with plugin caddyupload2dir

```sh
xcaddy build master --with github.com/crackeer/caddyupload2dir=./ --embed template:./template --debug
```

## 3. run caddy with plugin caddyupload2dir

```sh
./caddy -config caddy.json
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
- Add create directory in current directory、upload file to current directory、delete file or directory
- Uploading a file with an existing name preserves the existing file and stores the upload as `{FILE_NAME}-{timestamp}`.

[![pppwtDU.png](https://s1.ax1x.com/2023/02/26/pppwtDU.png)](https://imgse.com/i/pppwtDU)

## Build & Install as a systemd service

`build.sh` compiles a caddy binary that bundles this local plugin and creates
`caddyupload2dir.zip`. The archive extracts into a single top-level
`caddyupload2dir/` directory:

```sh
./build.sh            # build against caddy master
./build.sh v2.6.4     # or a specific caddy version
```

The extracted directory contains `caddy`, `template.html`, `caddy.json`,
`caddyupload2dir.service` and `install.sh`. Copy it to the target Linux machine
(with systemd) and run:

```sh
sudo ./install.sh
```

`install.sh` copies the `caddy` binary, `template.html`, and `caddy.json` into
`/usr/local/caddy/`. If a configuration already exists, it is saved as a timestamped
`caddy.json.bak.*` file before replacement. The installer validates the installed
configuration, installs `caddyupload2dir.service` under `/etc/systemd/system/`, then
reloads systemd and enables + restarts the service.

Useful commands after install:

```sh
systemctl status caddyupload2dir.service
journalctl -u caddyupload2dir.service -f
```

> The packaged configuration listens on port `8080`, serves root `/`, reads the browse
> template from `/usr/local/caddy/template.html`, and uses the default delete password
> `admin`. Change `file_server_root`, `root`, and `admin_password` before exposing the
> service beyond a trusted network. Serving `/` and running the service as root provides
> broad filesystem access.
