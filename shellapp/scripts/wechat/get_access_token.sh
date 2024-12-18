#!/bin/bash

# ========================================
# WeChatイベントを実行するためのアクセストークンを取得するスクリプト
# ========================================

# アクセストークンを取得
domain=$1
response=$(curl -s --insecure -u pharos:VqBOLspD https://{$domain}/publicApi/wechat-event/getAccessToken -d 'grant_type=client_credentials')
access_token=$(echo "$response" | jq -r '.access_token')

echo $access_token
