## Requirement
- [Go Installed](https://golang.org/doc/install)

## Install
refer to [Extending Caddy](https://caddyserver.com/docs/extending-caddy)
1. **Install [xcaddy](https://github.com/caddyserver/xcaddy)**

```sh
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
```

2. **Build A New Caddy Binary**

```sh
xcaddy build master --with github.com/crackeer/caddy-upload2dir
```

3. **copy new template.html**

here is the [template.html](https://github.com/crackeer/caddy-upload2dir/blob/main/template.html)

## Example:caddy.json
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
                "match" : [
                    {
                        "method" : ["POST", "PUT", "DELETE"]
                    }
                ],
                "handle" : [
                    {
                        "handler" : "upload2dir",
                        "file_server_root" : "/your/file/dir",
                        "admin_password" : "replace-with-a-strong-password"
                    }
                ],
                "terminal" : true
            },
            {
                "handle": [
                    {
                        "handler": "file_server",
                        "root": "/your/file/dir",
                        "browse": {
                            "template_file": "/new/template.html"
                        },
                        "index_names" : [""]
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
    admin_password replace-with-a-strong-password
}
```

请仅通过 HTTPS 提供该页面，避免密码在传输中暴露；不要将真实密码提交到版本库。

## what new filer_server page looks like?
- Add create directory in current directory、upload file to current directory、delete file or empty directory
[![pppwtDU.png](https://s1.ax1x.com/2023/02/26/pppwtDU.png)](https://imgse.com/i/pppwtDU)


