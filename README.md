# analogic/poste.io

## 修改说明

1. 补充了中文翻译
2. 更换了Logo
3. 修改了密钥登录按钮样式(增加图标和文字直接的间隙)

```bash
docker build -t my-poste .
```
## 示例

### 示例一

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

### 将 /webmail 重写到 /

这里使用另一个nginx进行反向代理，可以是nginx容器或主机上的nginx

#### 1. 关闭poste内置nginx的 gzip 压缩

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
            proxy_pass              http://poste/;
            proxy_set_header Host   $host;
            proxy_hide_header Via;
            proxy_hide_header X-Varnish;
            proxy_hide_header X-Powered-By;
            proxy_max_temp_file_size  0;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_intercept_errors on;
        }
    }
```
