

# 引数の商品IDからXP側から受け取ったJSONデータを取得
item_code=$1
event_as_json=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT event_as_json FROM wechat_event WHERE event_as_json like '%$item_code%' ORDER BY id DESC LIMIT 1;")

# JSONデータから配送先情報を取得
shipment=$(echo "$event_as_json" | jq -r '.shipment')
recipient_name=$(echo "$shipment" | jq -r '.recipient_name')
zip_code=$(echo "$shipment" | jq -r '.zip_code')
state=$(echo "$shipment" | jq -r '.state')
city=$(echo "$shipment" | jq -r '.city')
town=$(echo "$shipment" | jq -r '.town')
district=$(echo "$shipment" | jq -r '.district')
full_address=$(echo "$shipment" | jq -r '.full_address')
tel=$(echo "$shipment" | jq -r '.tel')

# order_shopping_idをDBから取得
sql="
SELECT os.id FROM order_shopping os
LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
WHERE osb.item_code = '$item_code'
LIMIT 1;
"
order_shopping_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

# JSONデータからWeChat側注文情報などを取得
wechat_order_number=$(echo "$event_as_json" | jq -r '.ordersn')
wechat_member_id=$(echo "$event_as_json" | jq -r '.wechat_member_id')
wechat_shop_code=$(echo "$event_as_json" | jq -r '.wechat_shop_code')
buyer_user_name=$(echo "$event_as_json" | jq -r '.buyer_username')

# order_shopping_breakdown_idをDBから取得
order_shopping_breakdown_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM order_shopping_breakdown WHERE item_code = '$item_code' LIMIT 1;")

# JSONデータから商品情報などを取得
item=$(echo "$event_as_json" | jq -r '.items[]')
quantity_desired=$(echo "$item" | jq -r '.quantity')
item_can_buy=$(echo "$item" | jq -r '.item_can_buy')
if [[ "$item_can_buy" == "true" ]]; then
    item_can_buy=1
else
    item_can_buy=0
fi

# DBから注文に紐付く荷物がすでに登録されているか確認
sql="
SELECT bo.id FROM buyee_order bo
LEFT JOIN order_shopping os ON bo.id = os.order_id
LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
WHERE osb.item_code = '$item_code'
LIMIT 1;
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

echo "|_.member_delivery_address_id|_.member_id|_.title|_.country_id|_.zip_code|_.state_province_region|_.city|_.address_1|_.address_2|_.address_3|_.recipient_name|_.tel|_.status|"
echo "| 3043233 | 4256156 | $recipient_name | 39 | $zip_code | $state | $city | $town | $district | $full_address | $recipient_name | $tel | 1 |\n"

echo "* 以下のレコードを@order_shopping_wechat@に登録\n"

echo "|_.order_shopping_id|_.member_delivery_address_log_id|_.wechat_order_number|_.wechat_member_id|_.country_id|_.currency_id|_.delivery_full_address|_.wechat_shop_code|_.buyer_user_name|_.is_trading_card|"
echo "| $order_shopping_id | 上記でインサートした@member_delivery_address_log.id@ | $wechat_order_number | $wechat_member_id | 18 | 3 | $full_address | $wechat_shop_code | $buyer_user_name | 0 |\n"

echo "* 以下のレコードを@order_shopping_wechat_breakdown@に登録\n"

echo "|_.order_shopping_wechat_id|_.order_shopping_breakdown_id|_.wechat_item_id|_.quantity_desired|_.item_can_buy|"
echo "| 上記でインサートした@order_shopping_wechat.id@ | $order_shopping_breakdown_id | 0 | $quantity_desired | $item_can_buy |\n"

if [[ -n "$baggage_id" ]]; then
    echo "* 注文に紐付く@baggage@テーブルレコードの@member_delivery_address_log_id@を更新"
    echo "** @baggage_id@ : @$baggage_id@"
    echo "** @member_delivery_address_log_id@ : 上記でインサートした@member_delivery_address_log.id@\n"
fi
