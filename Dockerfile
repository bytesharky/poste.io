# 版本号
ARG UPSTREAM=2.5.7

FROM analogic/poste.io:$UPSTREAM

# 关闭反病毒以降低CPU/内存使用
ENV DISABLE_CLAMAV=TRUE \
    DISABLE_RSPAMD=TRUE \
    TZ=Asia/Shanghai

# 暴露端口
# SMTP/SMTPS
# EXPOSE 25 465 587
# IMAP/IMAPS
# EXPOSE 143 993
# POP3/POP3S
# EXPOSE 110 995
# Website
# EXPOSE 80 443 

WORKDIR /

# 隐藏 PRO 菜单
ARG EXTRA_CSS="<style>\n.pro,.nav-sidebar p.alert{display:none !important}\nbutton#login-passkey,button#passkey-login-btn{display:flex;align-items:center;justify-content:center;margin:auto;gap:5px}\n</style>"

# 将 STYLE 内容插入 </head> 前
# 替换 LOGO
RUN sed -i "s@</head>@${EXTRA_CSS}\n</head>@" /opt/www/webmail/skins/elastic/templates/includes/layout.html && \
    sed -i "s@</head>@${EXTRA_CSS}\n</head>@" /opt/admin/templates/base.html.twig && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/watermark.html && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/templates/login.html && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/templates/includes/menu.html && \
    sed -i "s@background-blend-mode:\s\+soft-light;@background-blend-mode: color-dodge;@" /opt/www/webmail/skins/elastic/watermark.html
    
# 补充中文翻译（webmail）
# 替换 LOGO
COPY webmail/ /opt/www/webmail/

# 补充中文翻译（admin）
COPY admin/ /opt/admin/

# 定义数据卷
VOLUME ["/data"]

# 继承原镜像的 ENTRYPOINT 和 CMD
