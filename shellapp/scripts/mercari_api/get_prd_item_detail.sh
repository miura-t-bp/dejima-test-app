# ========================================
# メルカリ商品詳細取得APIを叩いて商品情報を取得する
# - メルカリ商品詳細取得API仕様書
#   - https://api-docs.jp-mercari.com/#/getItemById
# ========================================

# 引数から商品IDを取得
item_id=$1

# 本番DBからMercariUS用アカウントのaccess_tokenを取得
access_token=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT access_token FROM mercari_oauth WHERE store_login_info_id = 9729;")

# メルカリ検索APIから商品を検索
response=$(curl -s -X GET "https://api.jp-mercari.com/v1/items/$item_id" \
  -H "Accept: application/json" \
  -H "Authorization: $access_token")

# 商品情報を取得
echo "$response" | tr -d '\000-\037'
