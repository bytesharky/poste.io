#!/bin/sh
# 用法: ./update_label.sh 文件 key value

file="$1"
key="$2"
val="$3"

if grep -q "^\$labels\['$key'\]" "$file"; then
    # 找到这一行就替换值
    sed -i "s|^\(\$labels\['$key'\] = \).*;|\1\"$val\";|" "$file"
else
    # 找不到就追加到文件末尾
    echo "\$labels['$key'] = \"$val\";" >> "$file"
fi
