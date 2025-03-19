# ========================================
# Bunjang注文を作成するスクリプト
#
# 処理の流れ
# 1. DBから最新のBunjang注文番号を取得
# 2. 取得したBunjnag注文番号に1を足して新しいBunjang注文番号を作成
# 3. 新しいBunjang注文番号に重複がないか確認
# 4. メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
# 5. JSONデータを作成し、注文作成コマンドを実行
# ========================================

# 現在のスクリプトが存在するディレクトリを取得
NOW_DIR=$(dirname "$0")

domain=$1

# DBからデータを取得するシェルスクリプトのパス
GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/$(sh $NOW_DIR/db/get_file_by_domain.sh $domain)"

# 最新のBunjang注文番号を取得
latest_bunjang_order_number=$(sh $GET_DB_DATA_SHELL_FILE "SELECT bunjang_order_number FROM order_shopping_bunjang ORDER BY id DESC LIMIT 1;")

# 新しいBunjang注文番号を生成
date_of_latest_bunjang_order_number=${latest_bunjang_order_number:2:6}
today=$(date +"%y%m%d")
if [[ "$date_of_latest_bunjang_order_number" == "$today" ]]; then
    num=${latest_bunjang_order_number:8:3}
    new_bunjang_order_number="BJ${today}$(printf "%03d" $((10#$num + 1)))"
else
    new_bunjang_order_number="BJ${today}001"
fi

# 新しいBunjang注文番号が重複していないか確認
bunjang_order=$(sh $GET_DB_DATA_SHELL_FILE "SELECT id FROM order_shopping_bunjang WHERE bunjang_order_number = '$new_bunjang_order_number';")
if [[ -n "$bunjang_order" ]]; then
    echo "新しく生成したBunjang注文番号が重複しています。"
    exit 1
fi

# 引数から使用する商品のセラータイプ(C2CかB2C)と商品IDを取得
marketplace=$2
item_id=$3

# 商品情報JSONデータを作成
if [[ -n "$item_id" ]]; then
    # 引数で商品IDが指定されている場合は、商品情報をメルカリ商品検索APIから取得
    item_data=$(sh $NOW_DIR/mercari_api/get_prd_item_detail.sh $item_id)
else
    # その他の場合は、メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
    category_id=81
    items=$(sh $NOW_DIR/mercari_api/get_prd_item.sh $category_id $marketplace 1)
    item_data=$(echo "$items" | jq -c '.[]')
fi

item_code=$(echo "$item_data" | jq -r '.id')
item_name=$(echo "$item_data" | jq -r '.name')
item_image_url=$(echo "$item_data" | jq -r '.photos[0]')
item_price=$(echo "$item_data" | jq -r '.price')
item_price_fx=$((item_price * 10))  # 日本円の金額にを10倍したものを韓国ウォンの金額とする
category_id=$(echo "$item_data" | jq -r '.item_category.id')
seller_id=$(echo "$item_data" | jq -r '.seller.id')
if [[ "$marketplace" == "c2c" ]]; then
    seller_id=$(echo "$item_data" | jq -r '.seller.id')  # C2Cの場合はseller.idをseller_idとして使用
elif [[ "$marketplace" == "b2c" ]]; then
    seller_id=$(echo "$item_data" | jq -r '.seller.shop_id')  # B2Cの場合はseller.shop_idをseller_idとして使用
fi
seller_name=$(echo "$item_data" | jq -r '.seller.name')

# JSONデータを作成
json_data="{\"items\":[{\"item_code\":\"$item_code\",\"product_code\":null,\"item_name\":\"$item_name\",\"quantity\":1,\"sku\":\"$item_code\",\"item_url\":\"https://www.mercari.com/jp/items/$item_code/\",\"item_image_url\":\"$item_image_url\",\"original_item_price\":$item_price,\"bunjang_item_id\":\"276867251\",\"item_price_fx\":\"$item_price_fx\",\"item_price\":$item_price,\"seller\":{\"id\":\"$seller_id\",\"name\":\"$seller_name\"},\"item_can_buy\":true,\"category_id\":$category_id,\"shipping_payer_id\":1,\"sub_ordersn\":63965903,\"is_authenticity\":false}],\"payment\":{\"fx_rate\":null},\"shipment\":{\"country_code_iso_3166_alpha_2_code\":\"KR\",\"zip_code\":\"15826\",\"state\":\"test\",\"city\":\"test\",\"town\":\"\",\"district\":\"\",\"full_address\":\"full address test\",\"recipient_name\":\"test\",\"tel\":\"09012345678\",\"fax\":null,\"personal_customs_clearance_code\":\"P123456789876\"},\"ordersn\":\"$new_bunjang_order_number\",\"buyer_username\":\"test buyer name\",\"create_time\":1708883761,\"country_code\":\"KR\",\"currency_code\":\"KRW\",\"bunjang_shop_code\":\"bunjang-shop-code\"}"
# B2Cの場合はitemsにvariant_idの項目を追加
if [[ "$marketplace" == "b2c" ]]; then
    variant_id=$(echo "$item_data" | jq -r '.item_variants[0].id')
    json_data=$(echo "$json_data" | jq -c --arg variant_id "$variant_id" '.items |= map(. + {"variant_id":$variant_id})')
fi

echo "Bunjang注文を作成します。item_code: $item_code, bunjang_order_number: $new_bunjang_order_number"

# 注文作成
url="https://{$domain}/bunjang-event/orderCreate"
curl -X POST $url \
     -H "Content-Type: application/json" \
     -d "$json_data" \
     --insecure
echo \

# 注文作成が成功しているか確認
sql="
SELECT bo.id, bo.order_number FROM order_shopping os
INNER JOIN buyee_order bo ON os.order_id = bo.id
INNER JOIN order_shopping_bunjang osb ON os.id = osb.order_shopping_id
WHERE osb.bunjang_order_number = '$new_bunjang_order_number';
"
read new_order_id new_order_number < <(sh "$GET_DB_DATA_SHELL_FILE" "$sql")

# 注文作成が成功している場合は、CSメルカリ注文詳細画面のURLを表示
if [[ -n "$new_order_id" ]]; then
    echo "Bunjang注文を作成しました。Buyee注文番号: $new_order_number"
    echo "◆CSメルカリ注文詳細画面"
    echo "https://cs.$domain/shopping/mercariDetail/order_id/$new_order_id"
fi
