# sharky/poste.io

在信息化快速发展的今天，拥有一套属于自己的邮件系统，对于企业和个人来说都非常有价值。**poste.io** 是一个开源、现代化的邮件服务器套件，支持 SMTP/IMAP/POP3，并自带 Webmail 前端，配置简单，非常适合中小型企业或技术爱好者使用。

本仓是一个基于 `analogic/poste.io` 构建的邮件服务器+Web客户端，在官方的基础上做了一些简单的修改。

> 💡 提示：本仓库不保存镜像本身，仅包含Dockerfile和一些必要的文件。

## 修改说明

**webmail端：**  

1. 补充了缺失的中文翻译
2. 更换了Logo，你也可以换成自己喜欢的图片后再构建
3. 修改了密钥登录按钮样式，在图标和文字之间增加间隙，看起来更舒服
4. 去掉路径 `webmail` 前缀，直接访问，例如：`https://mail.example.com/`

**admin端：**  

1. 增加了中文语言文件，以支持中文
2. 隐藏了PRO菜单，使界面更加清爽
3. 修改了密钥登录按钮样式，在图标和文字之间增加间隙，看起来更舒服

## 构建

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

使用host网络映射端口

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

如果你像我一样，不接收邮件，只用来发送邮件，可以不映射端口，用nginx容器反向代理

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
