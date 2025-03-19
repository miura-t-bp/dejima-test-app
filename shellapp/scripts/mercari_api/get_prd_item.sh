# ========================================
# メルカリ商品検索APIから指定カテゴリの商品を取得するスクリプト
# - メルカリ検索API仕様書
#   - https://api-docs.jp-mercari.com/#/getItemsBySearchv3
# ========================================

# 引数から対象カテゴリと取得数を取得
category_id=$1
marketplace=$2
limit=$3

# marketplaceを数値に変換
if [[ "$marketplace" == "c2c" ]]; then
    marketplace=1
elif [[ "$marketplace" == "b2c" ]]; then
    marketplace=2
else
    marketplace=3
fi

# 本番DBからMercariUS用アカウントのaccess_tokenを取得
access_token=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT access_token FROM mercari_oauth WHERE store_login_info_id = 9729;")

# メルカリ検索APIから商品を検索
response=$(curl -s -X GET "https://api.jp-mercari.com/v3/items/search?category_id=$category_id&marketplace=$marketplace&status=on_sale&limit=$limit" \
  -H "Accept: application/json" \
  -H "Authorization: $access_token")

# 商品情報を取得
echo "$response" | tr -d '\000-\037' | jq -r ".data[0:$limit]"
