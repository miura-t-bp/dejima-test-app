# ========================================
# Shopee注文を作成するスクリプト
#
# 処理の流れ
# 1. DBから最新のShopee注文番号を取得
# 2. 取得したShopee注文番号に1を足して新しいShopee注文番号を作成
# 3. 新しいShopee注文番号に重複がないか確認
# 4. メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
# 5. JSONデータを作成し、注文作成コマンドを実行
# ========================================

# 現在のスクリプトが存在するディレクトリを取得
NOW_DIR=$(dirname "$0")

domain=$1

# DBからデータを取得するシェルスクリプトのパス
if [[ "$domain" == "dejima.local" ]]; then
    GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/$(sh $NOW_DIR/db/get_file_by_domain.sh $domain)"
else
    GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/get_data_from_pre_prd.sh"
fi

# 最新のShopee注文番号を取得
latest_shopee_order_number=$(sh $GET_DB_DATA_SHELL_FILE "SELECT shopee_order_number FROM order_shopping_shopee ORDER BY id DESC LIMIT 1;")

# 新しいShopee注文番号を生成[]
date_of_latest_shopee_order_number=${latest_shopee_order_number:2:6}
today=$(date +"%y%m%d")
if [[ "$date_of_latest_shopee_order_number" == "$today" ]]; then
    num=${latest_shopee_order_number:8:3}
    new_shopee_order_number="SH${today}$(printf "%03d" $((10#$num + 1)))"
else
    new_shopee_order_number="SH${today}001"
fi

# 新しいShopee注文番号が重複していないか確認
shopee_order=$(sh $GET_DB_DATA_SHELL_FILE "SELECT id FROM order_shopping_shopee WHERE shopee_order_number = '$new_shopee_order_number';")
if [[ -n "$shopee_order" ]]; then
    echo "新しく生成したShopee注文番号が重複しています。"
    exit 1
fi

# 引数から商品IDを取得
item_id=$2

# 商品情報JSONデータを作成
if [[ -n "$item_id" ]]; then
    # 引数で商品IDが指定されている場合は、商品情報をメルカリ商品検索APIから取得
    item_data=$(sh $NOW_DIR/mercari_api/get_prd_item_detail.sh $item_id)
else
    # その他の場合は、メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
    category_id=81
    items=$(sh $NOW_DIR/mercari_api/get_prd_item.sh $category_id "c2c" 1)
    item_data=$(echo "$items" | jq -c '.[]')
fi

item_code=$(echo "$item_data" | jq -r '.id')
item_name=$(echo "$item_data" | jq -r '.name')
item_image_url=$(echo "$item_data" | jq -r '.photos[0]')
item_price=$(echo "$item_data" | jq -r '.price')
item_price_fx=$((item_price * 5))  # 日本円の金額にを5倍したものをの外貨での金額とする
category_id=$(echo "$item_data" | jq -r '.item_category.id')
seller_id=$(echo "$item_data" | jq -r '.seller.id')
seller_name=$(echo "$item_data" | jq -r '.seller.name')

# JSONデータを作成
json_data="{\"items\":[{\"item_code\":\"$item_code\",\"product_code\":null,\"item_name\":\"$item_name\",\"quantity\":1,\"options\":null,\"sku\":\"$item_code\",\"item_url\":\"https://www.mercari.com/jp/items/$item_code/\",\"item_image_url\":\"$item_image_url\",\"original_item_price\":$item_price,\"shopee_item_id\":2914664703,\"item_price_fx\":\"$item_price_fx\",\"seller\":{\"id\":$seller_id,\"name\":\"$seller_name\"},\"item_can_buy\":true,\"category_id\":\"$category_id\",\"shipping_payer_id\":\"2\"}],\"payment\":{\"fx_rate\":null},\"store\":{\"shop_code\":\"\",\"partner_code\":\"\"},\"shipment\":{\"shipping_fee\":null,\"country_code_iso_3166_alpha_2_code\":\"TW\",\"zip_code\":\"110\",\"state\":\"台北市\",\"city\":\"信義區\",\"town\":\"\",\"district\":\"\",\"full_address\":\"110台北市信義區菸廠路88號九樓\",\"recipient_name\":\"吳岱凌\",\"tel\":\"886968117336\",\"fax\":null},\"ordersn\":\"$new_shopee_order_number\",\"buyer_username\":\"test buyer name\",\"create_time\":1574665365,\"country_code\":\"TW\",\"currency_code\":\"TWD\",\"kisaragi_shop_code\":\"mercaristore02.tw\"}"

echo "Shopee注文を作成します。item_code: $item_code, shopee_order_number: $new_shopee_order_number"

# 注文作成
if [[ "$domain" == "dejima.local" ]]; then
    curl -X POST "http://dejima.local/shopee-event/orderCreate" \
        -H "Content-Type: application/json" \
        -d "$json_data"
else
    ssh sss bash << EOF
        curl -s -X POST "http://shopee.stg.private.buyee.jp/shopee-event/orderCreate" \
             -H "Content-Type: application/json" \
             -d '$json_data'
EOF
fi
echo \

# 注文作成が成功しているか確認
sql="
SELECT bo.id, bo.order_number FROM order_shopping os
INNER JOIN buyee_order bo ON os.order_id = bo.id
INNER JOIN order_shopping_shopee oss ON os.id = oss.order_shopping_id
WHERE oss.shopee_order_number = '$new_shopee_order_number';
"
read new_order_id new_order_number < <(sh "$GET_DB_DATA_SHELL_FILE" "$sql")

# 注文作成が成功している場合は、CSメルカリ注文詳細画面のURLを表示
if [[ -n "$new_order_id" ]]; then
    if [[ "$domain" == "dejima.local" ]]; then
        cs_domain="cs.dejima.local"
    else
        cs_domain="cs.dev17.buyee.jp"
    fi
    echo "Shopee注文を作成しました。Buyee注文番号: $new_order_number"
    echo "◆CSメルカリ注文詳細画面"
    echo "https://$cs_domain/shopping/mercariDetail/order_id/$new_order_id"
fi
