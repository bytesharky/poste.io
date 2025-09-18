# sharky/poste.io

在信息化快速发展的今天，拥有一套属于自己的邮件系统，对于企业和个人来说都非常有价值。**poste.io** 是一个开源、现代化的邮件服务器套件，支持 SMTP/IMAP/POP3，并自带 Webmail 前端，配置简单，非常适合中小型企业或技术爱好者使用。

本仓是一个基于 `analogic/poste.io` 构建的邮件服务器+Web客户端，在官方的基础上做了一些简单的修改。

> 💡 提示：本仓库不保存镜像本身，仅包含Dockerfile和一些必要的文件。

## 修改说明

**webmail端：**  

1. 补充了缺失的中文翻译
2. 更换了Logo，你也可以换成自己喜欢的图片后再构建
3. 修改了密钥登录按钮样式，在图标和文字之间增加间隙，看起来更舒服
4. 去掉路径 webmail 前缀，直接访问，例如：https://mail.example.com/ (仅`hidden-prefix`分支)

**admin端：**  

1. 增加了中文语言文件，以支持中文
2. 隐藏了PRO菜单，使界面更加清爽
3. 修改了密钥登录按钮样式，在图标和文字之间增加间隙，看起来更舒服

## 构建

克隆本仓库后使用下面的命令构建，确保你已经安装docker

```bash
docker build -t my-poste .
```

## 展示

### webmail

![webmail](/example/example-webmail1.jpeg)
![webmail](/example/example-webmail2.jpeg)
![webmail](/example/example-webmail3.jpeg)

### admin

![webmail](/example/example-admin1.jpeg)
![webmail](/example/example-admin2.jpeg)
![webmail](/example/example-admin3.jpeg)

## 示例

### 示例一

使用host网络运行，并映射端口

```bash
docker run -d \
    --name poste \
    --hostname mail.example.com \
    --network host \
    --domainname example.com \
    -p 25:25 \
    -p 465:465 \
    -p 587:587 \
    -p 143:143 \
    -p 993:993 \
    -p 110:110 \
    -p 995:995 \
    -p 80:80 \
    -p 443:443 \
    -v /data/docker/poste/data:/data \
    -e DISABLE_CLAMAV=TRUE \
    -e DISABLE_RSPAMD=TRUE \
    -e TZ=Asia/Shanghai \
    --restart always \
    my-poste:latest
```

### 示例二

如果你像我一样，不用来接收邮件，只用来发送邮件，可以不映射端口，用nginx容器反向代理访问Webmail

```bash
docker run -d \
    --name poste \
    --hostname mail.example.com \
    --network docker-net \
    --domainname example.com \
    -v /data/docker/poste/data:/data \
    -e DISABLE_CLAMAV=TRUE \
    -e DISABLE_RSPAMD=TRUE \
    -e TZ=Asia/Shanghai \
    -e HTTPS=OFF \
    --restart always \
    my-poste:latest
```

### 进阶：将 /webmail 重写到 /

> 💡 提示：如果你只是想隐藏 `/webmail`, 建议你直接使用 `hidden-prefix` 分支，`hidden-prefix` 在容器内进行了重写，实现隐藏 `/webmail` 前缀。

当然你也可继续使用下面的方式，使用另一个nginx进行反向代理，可以是nginx容器或主机上的nginx，可以更灵活的配置。

#### 1. 关闭poste内置nginx的 gzip 压缩

因为要使用 `sub_filter` 指令，必须关闭上游服务器的 `gizp`，否则得到压缩后的数据是无法正常使用 `sub_filter` 指令替换的。

在 poste 的 nginx 配置文件中找到 `gzip on;` 修改为 `gzip off;` 并重新加载配置，可以直接使用下面的命令完成修改。

```bash
docker exec poste bash -c 'sed -i "s@gzip\s\+on\s*;@gzip off;@g" /etc/nginx/nginx.conf && nginx -s reload'

```

#### 2. 配置nginx反向代理

```nginx
    server {
        listen 80;
        listen [::]:80;
        server_name mail.example.com;
        return 301 https://$host$request_uri;
    }

    server {
        listen       443 ssl;
        listen       [::]:443 ssl;
        http2        on;
        charset      utf-8;
        server_name  mail.example.com;
        access_log   logs/mail.access.log;
        error_log    logs/mail.error.log;
        gzip         on;
        
        ssl_protocols        TLSv1.2 TLSv1.3;
        ssl_certificate      /var/www/sslcert/example.com.cer;  
        ssl_certificate_key  /var/www/sslcert/example.com.key; 

        ssl_stapling on; 
        ssl_stapling_verify on; 
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM';
        ssl_prefer_server_ciphers on;
        resolver 8.8.8.8 8.8.4.4 223.5.5.5 valid=300s;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
        
        location / {
            proxy_pass              http://poste/webmail/;
            proxy_redirect          /webmail/ /;
            proxy_set_header Host   $host;
            proxy_hide_header Via;
            proxy_hide_header X-Varnish;
            proxy_hide_header X-Powered-By;
            proxy_max_temp_file_size  0;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_intercept_errors on;

            ## replace content ##
            sub_filter_once  off;
            sub_filter_types text/html application/javascript text/css;
            sub_filter '/webmail/' '/';
        }

        location /admin/ {
            proxy_pass              http://poste;
            proxy_set_header Host   $host;
            proxy_hide_header Via;
            proxy_hide_header X-Varnish;
            proxy_hide_header X-Powered-By;
            proxy_max_temp_file_size  0;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_intercept_errors on;
            sub_filter_once  off;
            sub_filter '"/webmail"' '"/"';
        }

        # # Block access to admin API and installation endpoints
        # location ~ ^/admin/(api|install) {
        #     return 404;
        # }
    }
```

