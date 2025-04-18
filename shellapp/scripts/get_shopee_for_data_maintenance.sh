# ========================================
# 以下のレコードを登録するデータメンテ用のデータを取得するスクリプト
# - order_shopping_shopee
# - order_shopping_shopee_breakdown
# ========================================

# 引数からXP側から受け取ったJSONデータを取得
shopee_order_number=$1
event_as_json=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT event_as_json FROM shopee_event WHERE shopee_order_number = '$shopee_order_number' ORDER BY id ASC LIMIT 1;")

# 引数からmember_delivery_address_log_idと何番目の商品かを取得
member_delivery_address_log_id=$2
item_index=$3

# インサート用のデータを取得
country_code=$(echo "$event_as_json" | jq -r '.country_code')
country_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT country_id FROM country_iso_3166 WHERE alpha_2_code = '$country_code' LIMIT 1;")
currency_code=$(echo "$event_as_json" | jq -r '.currency_code')
currency_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM currency WHERE code = '$currency_code' LIMIT 1;");
delivery_full_address=$(echo "$event_as_json" | jq -r '.shipment.full_address')
hashidate_shop_code=$(echo "$event_as_json" | jq -r '.kisaragi_shop_code')
buyer_user_name=$(echo "$event_as_json" | jq -r '.buyer_username')

# 商品情報を取得
item=$(echo "$event_as_json" | jq -c --argjson idx "$item_index" '.items[$idx]')


# 商品IDを取得
item_code=$(echo "$item" | jq -r '.item_code')
echo "$item_code"
echo ""

# order_shopping_idを取得
sql="
select os.id from buyee_order bo
inner join order_shopping os on bo.id = os.order_id
inner join order_shopping_breakdown osb on os.id = osb.order_shopping_id
left join order_shopping_shopee oss on os.id = oss.order_shopping_id
where osb.item_code = '$item_code'
and bo.status != 3;
"
order_shopping_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

echo "以下のレコードをorder_shopping_shopeeに登録"
echo "$order_shopping_id,$member_delivery_address_log_id,$shopee_order_number,$country_id,$currency_id,$delivery_full_address,$hashidate_shop_code,$buyer_user_name"
echo ""

# データを取得
shopee_item_id=$(echo "$item" | jq -r '.shopee_item_id')
quantity_desired=$(echo "$item" | jq -r '.quantity')
shopee_item_price=$(echo "$item" | jq -r '.item_price')
shopee_item_purchase_price=$(echo "$item" | jq -r '.item_price_fx')

# order_shopping_breakdown_idを取得
sql="
select osb.id from buyee_order bo
inner join order_shopping os on bo.id = os.order_id
inner join order_shopping_breakdown osb on os.id = osb.order_shopping_id
left join order_shopping_shopee oss on os.id = oss.order_shopping_id
where osb.item_code = '$item_code'
and bo.status != 3;
"
order_shopping_breakdown_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

echo "以下のレコードをorder_shopping_shopee_breakdownに登録"
echo "上記でインサートしたorder_shopping_shopee.id,$order_shopping_breakdown_id,$shopee_item_id,$quantity_desired,$shopee_item_price,$shopee_item_purchase_price,1"
echo ""
echo ""
