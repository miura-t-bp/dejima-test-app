#!/bin/bash

# ========================================
# MercariUS注文を作成するスクリプト
#
# 処理の流れ
# 1. DBから最新のMercariUS注文番号を取得
# 2. 取得したMercariUS注文番号に1を足して新しいMercariUS注文番号を作成
# 3. 新しいMercariUS注文番号に重複がないか確認
# 4. メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
# 5. JSONデータを作成し、注文作成コマンドを実行
# ========================================

# 現在のスクリプトが存在するディレクトリを取得
NOW_DIR=$(dirname "$0")

domain=$1

# DBからデータを取得するシェルスクリプトのパス
GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/$(sh $NOW_DIR/db/get_file_by_domain.sh $domain)"

if [[ "$domain" == "dejima.local" ]]; then
    # client_idとsecret_client_idが記載された設定ファイルのパス
    CONFIG_FILE="/etc/shellapp/app.local.conf"
else
    CONFIG_FILE="/etc/shellapp/app.dev.conf"
fi

# ファイルの存在確認
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# 設定ファイルを読み込む
client_id=$(grep '^mercarius_client_id' "$CONFIG_FILE" | cut -d'=' -f2 | xargs)
mercarius_secret_client_id=$(grep '^mercarius_secret_client_id' "$CONFIG_FILE" | cut -d'=' -f2 | xargs)

# 最新のMercariUS注文番号を取得
latest_mercarius_order_number=$(sh $GET_DB_DATA_SHELL_FILE "SELECT mercarius_order_number FROM order_shopping_mercarius ORDER BY id DESC LIMIT 1;")

# 新しいMercariUS注文番号を生成
date_of_latest_mercarius_order_number=${latest_mercarius_order_number:3:6}
today=$(date +"%y%m%d")
if [[ "$date_of_latest_mercarius_order_number" == "$today" ]]; then
    num=${latest_mercarius_order_number:9:3}
    new_mercarius_order_number="MUS${today}$(printf "%03d" $((10#$num + 1)))"

else
    new_mercarius_order_number="MUS${today}001"
fi

# 新しいMercariUS注文番号が重複していないか確認
mercarius_order=$(sh $GET_DB_DATA_SHELL_FILE "SELECT id FROM order_shopping_mercarius WHERE mercarius_order_number = '$new_mercarius_order_number';")
if [[ -n "$mercarius_order" ]]; then
    echo "新しく生成したMercariUS注文番号が重複しています。"
    exit 1
fi

# 引数から使用する商品数と商品IDを取得
limit=$2
item_id=$3

# 商品情報JSONデータを作成
if [[ "$limit" -eq 1 && -n "$item_id" ]]; then
    # 引数で商品IDが指定されている場合は、商品情報をメルカリ商品検索APIから取得
    item=$(sh $NOW_DIR/mercari_api/get_prd_item_detail.sh $item_id)

    item_code=$(echo "$item" | jq -r '.id')
    item_price=$(echo "$item" | jq -r '.price')
    item_price_fx=$(echo "$item_price * 0.01" | bc)  # 日本円の金額にを0.01倍したものをUSDの金額とする

    items_json="{\"us_item_code\":\"$item_code\",\"jp_item_code\":\"$item_code\",\"us_category_id\":\"123\",\"us_category_name\":\"figure\",\"item_name_en\":\"GokuFigure\",\"item_price_usd\":$item_price_fx}"
else
    # その他の場合は、指定された数のフィギュアカテゴリ商品情報をメルカリ商品検索APIから取得
    category_id=81
    items=$(sh $NOW_DIR/mercari_api/get_prd_item.sh $category_id "c2c" $limit)

    # item_dataを1つずつ処理し、指定された数の商品情報含む商品情報のJSONデータを作成
    items_json=""
    while read -r item; do
        item_code=$(echo "$item" | jq -r '.id')
        item_price=$(echo "$item" | jq -r '.price')
        item_price_fx=$(echo "$item_price * 0.01" | bc)  # 日本円の金額にを0.01倍したものをUSDの金額とする

        if [[ -n "$items_json" ]]; then
            items_json+=","
        fi
        items_json+="{\"us_item_code\":\"$item_code\",\"jp_item_code\":\"$item_code\",\"us_category_id\":\"123\",\"us_category_name\":\"figure\",\"item_name_en\":\"GokuFigure\",\"item_price_usd\":$item_price_fx}"
    done < <(echo "$items" | jq -c '.[]')
fi

# 送信するJSONデータを作成
json_data="{\"client_id\":\"$client_id\",\"secret_client_id\":\"$mercarius_secret_client_id\",\"items\":[$items_json],\"payment\":{\"fx_rate\":0.01},\"shipment\":{\"country_code\":\"US\",\"zip_code\":\"92802\",\"state\":\"California\",\"city\":\"Anaheim\",\"street_address\":\"Test Street\",\"additional_address\":\"Test Additional Address\",\"recipient_name\":\"Test Recipient Name\",\"tel\":\"09012345678\"},\"buyer_id\":\"112358\",\"buyer_email_address\":\"test.test39@gmail.com\",\"create_time\":\"1708883761\",\"ordersn\":\"$new_mercarius_order_number\"}"

echo "MercariUS注文を作成します。item_code: $item_code, mercarius_order_number: $new_mercarius_order_number"

# 注文作成
url="https://{$domain}/publicApi/mercarius-event/orderCreate"
curl -X POST $url \
     -H "Content-Type: application/json" \
     -d "$json_data" \
     --insecure
echo \

# 注文作成が成功しているか確認
sql="
SELECT bo.id, bo.order_number FROM order_shopping os
INNER JOIN buyee_order bo ON os.order_id = bo.id
INNER JOIN order_shopping_mercarius osm ON os.id = osm.order_shopping_id
WHERE osm.mercarius_order_number = '$new_mercarius_order_number';
"
read new_order_id new_order_number < <(sh "$GET_DB_DATA_SHELL_FILE" "$sql")

# 注文作成が成功している場合は、CSメルカリ注文詳細画面のURLを表示
if [[ -n "$new_order_id" ]]; then
    echo "MercariUS注文を作成しました。Buyee注文番号: $new_order_number"
    echo "◆CSメルカリ注文詳細画面"
    echo "https://cs.$domain/shopping/mercariDetail/order_id/$new_order_id"
fi
