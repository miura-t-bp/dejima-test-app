# ========================================
# 以下のレコードを登録するデータメンテ用のデータを取得するスクリプト
# - member_delivery_address_log
# - order_shopping_mercarius
# - order_shopping_mercarius_breakdown
#
# 処理の流れ
# 1. 商品IDからXP側から受け取ったJSONデータを取得
# 2. 取得したJSONデータを元にDBに登録するデータを作成
# 3. 荷物がすでに登録されている場合はbaggage.member_delivery_address_logのレコードも更新
# ========================================

# 引数の商品IDからXP側から受け取ったJSONデータを取得
item_code=$1
event_as_json=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT event_as_json FROM mercarius_event WHERE event_as_json like '%$item_code%' ORDER BY id DESC LIMIT 1;")

# JSONデータから配送先情報を取得
shipment=$(echo "$event_as_json" | jq -r '.shipment')
recipient_name=$(echo "$shipment" | jq -r '.recipient_name')
zip_code=$(echo "$shipment" | jq -r '.zip_code')
zip_code=$(echo "$zip_code" | sed 's/-.*//')
state=$(echo "$shipment" | jq -r '.state')
city=$(echo "$shipment" | jq -r '.city')
street_address=$(echo "$shipment" | jq -r '.street_address')
additional_address=$(echo "$shipment" | jq -r '.additional_address')
tel=$(echo "$shipment" | jq -r '.tel')

# order_shopping_idをDBから取得
sql="
SELECT os.id FROM order_shopping os
LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
WHERE osb.item_code = '$item_code'
"
order_shopping_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

# JSONデータからMercariUS側注文情報などを取得
mercarius_order_number=$(echo "$event_as_json" | jq -r '.ordersn')
buyer_id=$(echo "$event_as_json" | jq -r '.buyer_id')
buyer_email_address=$(echo "$event_as_json" | jq -r '.buyer_email_address')

# order_shopping_breakdown_idをDBから取得
order_shopping_breakdown_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM order_shopping_breakdown WHERE item_code = '$item_code'")

# JSONデータから商品情報などを取得
item=$(echo "$event_as_json" | jq -r '.items[]')
mercarius_item_code=$(echo "$item" | jq -r '.us_item_code')
mercarius_category_id=$(echo "$item" | jq -r '.us_category_id')
mercarius_category_name=$(echo "$item" | jq -r '.us_category_name')
mercarius_item_name=$(echo "$item" | jq -r '.item_name_en')
mercarius_item_price=$(echo "$item" | jq -r '.item_price_usd')
fees=$(echo "$item" | jq -r '.fee')

# DBから注文に紐付く荷物がすでに登録されているか確認
sql="
SELECT bo.id FROM buyee_order bo
LEFT JOIN order_shopping os ON bo.id = os.order_id
LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
WHERE osb.item_code = '$item_code';
"
order_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")
sql="
SELECT baggage_id FROM order_baggage ob
LEFT JOIN baggage b ON ob.baggage_id = b.id
WHERE ob.order_id = $order_id;
"
baggage_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

# データメンテの対応内容の項目に記載する形でデータ出力
echo "h3. $item_code\n"

echo "* 以下のレコードを@member_delivery_address_log@に登録\n"

echo "member_delivery_address_id,member_id,title,country_id,zip_code,state_province_region,city,address_1,address_2,recipient_name,tel,status"
echo "3043233,4256156,$recipient_name,39,$zip_code,$state,$city,$street_address,$additional_address,$recipient_name,$tel,1\n"

echo "* 以下のレコードを@order_shopping_mercarius@に登録\n"

echo "order_shopping_id,member_delivery_address_log_id,mercarius_order_number,country_id,currency_id,buyer_user_name,mail_address"
echo "$order_shopping_id,{上記でインサートした@member_delivery_address_log.id@},$mercarius_order_number,84,4,$buyer_id,$buyer_email_address\n"

echo "* 以下のレコードを@order_shopping_mercarius_breakdown@に登録\n"

echo "order_shopping_mercarius_id,order_shopping_breakdown_id,mercarius_item_code,quantity_desired,mercarius_category_id,mercarius_category_name,mercarius_item_name,mercarius_item_price,fees"
echo "{上記でインサートした@order_shopping_mercarius.id@},$order_shopping_breakdown_id,$mercarius_item_code,$quantity_desired,$mercarius_category_id,$mercarius_category_name,$mercarius_item_name,$mercarius_item_price,$fees\n"

if [[ -n "$baggage_id" ]]; then
    echo "* 注文に紐付く@baggage@テーブルレコードの@member_delivery_address_log_id@を更新"
    echo "** @baggage_id@ : @$baggage_id@"
    echo "** @member_delivery_address_log_id@ : {上記でインサートした@member_delivery_address_log.id@}\n"
fi
