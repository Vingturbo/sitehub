#!/bin/bash
set -e

echo "📝 开始处理 Issue #$ISSUE_NUMBER"

# ========== 长度检查 ==========
check_length() {
    local value="$1"
    local max="$2"
    local field="$3"
    if [ ${#value} -gt "$max" ]; then
        echo "❌ $field 长度超限：${#value} > $max"
        echo "reply=❌ 提交失败：$field 长度超过限制（最多 $max 字符）" >> $GITHUB_OUTPUT
        exit 0
    fi
}

# ========== 提取字段（固定行号） ==========
SITE_URL=$(echo "$ISSUE_BODY" | sed -n '3p')
SITE_NAME=$(echo "$ISSUE_BODY" | sed -n '7p')
SITE_DESC=$(echo "$ISSUE_BODY" | sed -n '11p')
SITE_ICON=$(echo "$ISSUE_BODY" | sed -n '15p')
SITE_COLOR=$(echo "$ISSUE_BODY" | sed -n '19p')
SITE_EMAIL=$(echo "$ISSUE_BODY" | sed -n '23p')
SITE_OWNER=$(echo "$ISSUE_BODY" | sed -n '27p')

[ "$SITE_DESC" = "_No response_" ] && SITE_DESC=""
[ "$SITE_ICON" = "_No response_" ] && SITE_ICON=""
[ "$SITE_COLOR" = "_No response_" ] && SITE_COLOR=""
[ "$SITE_EMAIL" = "_No response_" ] && SITE_EMAIL=""
[ "$SITE_OWNER" = "_No response_" ] && SITE_OWNER=""

echo "🔍 URL: $SITE_URL"
echo "🔍 名称: $SITE_NAME"
echo "🔍 描述: $SITE_DESC"
echo "🔍 图标: $SITE_ICON"
echo "🔍 颜色: $SITE_COLOR"
echo "🔍 邮箱: $SITE_EMAIL"
echo "🔍 所有者: $SITE_OWNER"

check_length "$SITE_URL" 500 "站点 URL"
check_length "$SITE_NAME" 100 "站点名称"
check_length "$SITE_DESC" 500 "站点描述"
check_length "$SITE_ICON" 500 "图标 URL"
check_length "$SITE_COLOR" 7 "主题色"
check_length "$SITE_EMAIL" 254 "邮箱"
check_length "$SITE_OWNER" 100 "所有者 GitHub 用户名"

if [ -z "$SITE_OWNER" ]; then
    SITE_OWNER=$SUBMITTER
fi

HTTP_CODE=$(curl -o /dev/null -s -L -w "%{http_code}" --connect-timeout 5 "$SITE_URL" || echo "curl脚本错误，请检查 URL 是否正确")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ 网站正常"
else
    echo "❌ 状态码：$HTTP_CODE"
    echo "reply=❌ 提交失败: 站点返回状态码错误,不是200(HTTP $HTTP_CODE),请确认 URL 及 网站是否正常" >> $GITHUB_OUTPUT
    exit 0
fi

# ========== 验证图标 URL（如果填写了） ==========
if [ -n "$SITE_ICON" ]; then
    echo "🔍 验证图标 URL..."
    ICON_CODE=$(curl -o /dev/null -s -L -w "%{http_code}" --connect-timeout 5 "$SITE_ICON" || echo "curl脚本错误，请检查图标 URL 是否正确")
    if [ "$ICON_CODE" -ne 200 ]; then
        echo "❌ 图标不可访问（HTTP $ICON_CODE）"
        echo "reply=❌ 提交失败：图标 URL 不可访问（HTTP $ICON_CODE），请确认图标地址正确" >> $GITHUB_OUTPUT
        exit 0
    else
        echo "✅ 图标可访问（HTTP $ICON_CODE）"
    fi
fi

# ========== 验证主题色格式（如果填写了） ==========
if [ -n "$SITE_COLOR" ]; then
    echo "🔍 验证主题色格式..."
    if ! echo "$SITE_COLOR" | grep -qE '^#[0-9a-fA-F]{6}$'; then
        echo "❌ 主题色格式错误：$SITE_COLOR"
        echo "reply=❌ 提交失败：主题色格式不正确，应为 6 位十六进制颜色码（如 #1a73e8）" >> $GITHUB_OUTPUT
        exit 0
    else
        echo "✅ 主题色格式正确"
    fi
fi

# ========== 验证邮箱格式（如果填写了） ==========
if [ -n "$SITE_EMAIL" ]; then
    echo "🔍 验证邮箱格式..."
    if ! echo "$SITE_EMAIL" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
        echo "❌ 邮箱格式错误：$SITE_EMAIL"
        echo "reply=❌ 提交失败：邮箱格式不正确，请填写有效的邮箱地址（如 user@example.com）" >> $GITHUB_OUTPUT
        exit 0
    else
        echo "✅ 邮箱格式正确"
    fi
fi

# ========== 计算哈希前缀 ==========
PREFIX=$(echo "$SITE_URL" | md5sum | cut -c1-2)
echo "🔑 哈希前缀: $PREFIX"

# ========== 预生成单行 JSON ==========
JSON_LINE=$(jq -c -n \
    --arg url "$SITE_URL" \
    --arg name "$SITE_NAME" \
    --arg desc "$SITE_DESC" \
    --arg icon "$SITE_ICON" \
    --arg color "$SITE_COLOR" \
    --arg email "$SITE_EMAIL" \
    --arg submitter "$SITE_OWNER" \
    '{url: $url, name: $name, description: $desc, icon: $icon, color: $color, email: $email, submitter: $submitter, added_at: now | todate}'
)

echo "📦 JSON: $JSON_LINE"

# ========== 创建目录、更新索引、追加写入 ==========
# ========== 更新索引文件（确保不重复） ==========
INDEX_FILE="index.txt"
mkdir -p data
git pull --ff-only origin main
# 如果 index.txt 不存在，直接创建
if [ ! -f "$INDEX_FILE" ]; then
    echo "$PREFIX" > "$INDEX_FILE"
    echo "➕ 创建索引文件，添加前缀: $PREFIX"
else
    # 检查前缀是否已存在
    if ! grep -qx "$PREFIX" "$INDEX_FILE"; then
        echo "$PREFIX" >> "$INDEX_FILE"
        echo "➕ 新增前缀到索引: $PREFIX"
    else
        echo "✅ 前缀已存在于索引: $PREFIX"
    fi
fi
echo "✅ 索引文件更新完成"
# ========== 检查 URL 是否已存在（逐行 jq 解析） ==========
JSONL_FILE="data/${PREFIX}.jsonl"
URL_FOUND=false

if [ -f "$JSONL_FILE" ]; then
    echo "🔍 检查 URL 是否已存在..."
    while IFS= read -r line; do
        # 跳过空行
        [ -z "$line" ] && continue
        
        # 用 jq 提取 URL 并比较
        EXISTING_URL=$(echo "$line" | jq -r '.url' 2>/dev/null)
        if [ "$EXISTING_URL" = "$SITE_URL" ]; then
            URL_FOUND=true
            break
        fi
    done < "$JSONL_FILE"
fi

if [ "$URL_FOUND" = true ]; then
    echo "⚠️ URL 已存在，跳过收录"
    echo "reply=ℹ️ 该网站已被收录，无需重复提交" >> $GITHUB_OUTPUT
    exit 0
fi
echo "$JSON_LINE" >> "data/$PREFIX.jsonl"
echo "✅ jsonl 文件更新完成"
git add data/ index.txt
git commit -m "Add website $SITE_NAME ($SITE_URL) for issue $ISSUE_NUMBER"
git push origin main
echo "✅ 提交完成"
echo "reply=✅ 提交成功: 站点 $SITE_NAME ($SITE_URL) 已成功收录" >> $GITHUB_OUTPUT