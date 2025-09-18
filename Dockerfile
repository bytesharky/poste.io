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

# 样式微调和隐藏 PRO 菜单
ARG EXTRA_CSS="<style>\n\
.pro,.nav-sidebar p.alert{ display:none !important}\n\
img#logo { pointer-events: none; user-select: none;}\n\
button#login-passkey,button#passkey-login-btn { display:flex; align-items:center; justify-content:center; margin:auto; gap:5px; }\n\
</style>"

# 控制台登录页下方的链接地址
ARG MY_URL="https://github.com/bytesharky/poste.io"

# 复制助手脚本
COPY update_label.sh /usr/local/bin/

# 将 STYLE 内容插入 </head> 前
# 替换 LOGO 路径
# 替换 插件本地化翻译
RUN chmod +x /usr/local/bin/update_label.sh && \
    sed -i 's@"/webmail"@"/"@' /opt/admin/templates/base.html.twig && \
    sed -i 's@\(<a href="\)https://poste.io\(" style="color: black;">\)poste@\1'${MY_URL}'\2sharky - poste@' /opt/admin/templates/Base/Security/login.html.twig && \
    echo "CSS injection" && \
    sed -i "s@</head>@${EXTRA_CSS}\n</head>@" /opt/www/webmail/skins/elastic/templates/includes/layout.html && \
    sed -i "s@</head>@${EXTRA_CSS}\n</head>@" /opt/admin/templates/base.html.twig && \
    echo "Replace the logo" && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/watermark.html && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/templates/login.html && \
    sed -i "s@images/logo.svg@images/logo.png@" /opt/www/webmail/skins/elastic/templates/includes/menu.html && \
    sed -i "s@background-blend-mode:\s\+soft-light;@background-blend-mode: color-dodge;@" /opt/www/webmail/skins/elastic/watermark.html && \
    echo "Add plugins localization" && \
    sed -i "s@ Login with Passkey@'.\$this->gettext('passkeyloginbtn').'@"  /opt/www/webmail/plugins/poste_passkey_login/poste_passkey_login.php && \
    sed -i '/function passkey_button(\$args)/,/{/{s@{@&\n        \$this->add_texts("localization/");@;}' /opt/www/webmail/plugins/poste_passkey_login/poste_passkey_login.php && \
    sed -i "s@>Administration<@><roundcube:label name=""Administration"" /><@" /opt/www/webmail/skins/elastic/templates/login.html && \
    update_label.sh "/opt/www/webmail/program/localization/en_US/labels.inc" "Administration" "Administration" && \
    update_label.sh "/opt/www/webmail/program/localization/zh_TW/labels.inc" "Administration" "主控台"
    
# 补充中文翻译（webmail）和新的 LOGO 文件
COPY webmail/ /opt/www/webmail/

# 补充中文翻译（admin）
COPY admin/ /opt/admin/

# 拷贝nginx模板（隐藏路径webmail前缀）
COPY nginx.templates/ /etc/nginx/sites-enabled.templates/

# 定义数据卷
VOLUME ["/data"]

# 继承原镜像的 ENTRYPOINT 和 CMD
