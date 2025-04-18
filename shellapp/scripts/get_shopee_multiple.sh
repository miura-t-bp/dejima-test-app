# ========================================
# 以下のレコードを登録するデータメンテ用のデータを取得するスクリプト(複数商品注文用)
# - member_delivery_address_log
# - order_shopping_mercarius
# - order_shopping_mercarius_breakdown
# ========================================

# データメンテ対象の商品IDを取得
sql="
select osbreakdown.item_code from buyee_order bo
inner join order_shopping os on bo.id = os.order_id
inner join order_shopping_breakdown osbreakdown on os.id = osbreakdown.order_shopping_id
left join order_shopping_shopee oss on os.id = oss.order_shopping_id
where bo.member_id = 1093336
and bo.status != 3
and oss.id is null
and bo.created_at >= '2024-04-04';  # 前回メンテ日時
"
item_codes=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")
item_codes_array=($item_codes)

echo ""

for item_code in "${item_codes_array[@]}"; do
    # 商品IDからXP側から受け取ったJSONデータを取得
    event_as_json=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT event_as_json FROM shopee_event WHERE event_as_json like '%$item_code%' ORDER BY id DESC LIMIT 1;")

    # インサート用のデータを取得
    shopee_order_number=$(echo "$event_as_json" | jq -r '.ordersn')
    country_code=$(echo "$event_as_json" | jq -r '.country_code')
    country_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT country_id FROM country_iso_3166 WHERE alpha_2_code = '$country_code' LIMIT 1;")
    currency_code=$(echo "$event_as_json" | jq -r '.currency_code')
    currency_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM currency WHERE code = '$currency_code' LIMIT 1;");
    delivery_full_address=$(echo "$event_as_json" | jq -r '.shipment.full_address')
    hashidate_shop_code=$(echo "$event_as_json" | jq -r '.kisaragi_shop_code')
    buyer_user_name=$(echo "$event_as_json" | jq -r '.buyer_username')

    # JSONデータから商品情報などを取得
    item=$(echo "$event_as_json" | jq --arg item_code "$item_code" '[.items[] | select(.item_code == $item_code)][0]')
    shopee_item_id=$(echo "$item" | jq -r '.shopee_item_id')
    quantity_desired=$(echo "$item" | jq -r '.quantity')
    shopee_item_price=$(echo "$item" | jq -r '.item_price')
    shopee_item_purchase_price=$(echo "$item" | jq -r '.item_price_fx')

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

    # データメンテの対応内容の項目に記載する形でデータ出力
    echo $item_code,$order_shopping_id,8861561,$shopee_order_number,$country_id,$currency_id,$delivery_full_address,$hashidate_shop_code,$buyer_user_name,上記でインサートしたorder_shopping_shopee.id,$order_shopping_breakdown_id,$shopee_item_id,$quantity_desired,$shopee_item_price,$shopee_item_purchase_price,1

done
