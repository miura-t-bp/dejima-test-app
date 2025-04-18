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
left join order_shopping_bunjang osb on os.id = osb.order_shopping_id
left join order_shopping_mercarius osm on os.id = osm.order_shopping_id
where bo.member_id = 4320440
and bo.status != 3
and osb.id is null
and osm.id is null
and bo.created_at > '2025-04-01 00:00:00';  # 前回メンテ日時
"
item_codes=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")
item_codes_array=($item_codes)

for item_code in "${item_codes_array[@]}"; do
    # 商品IDからXP側から受け取ったJSONデータを取得
    event_as_json=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT event_as_json FROM mercarius_event WHERE item_code like '%$item_code%' ORDER BY id DESC LIMIT 1;")

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
    state_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM state_province_region WHERE name = '$state'")

    # order_shopping_idをDBから取得
    sql="
    SELECT os.id FROM order_shopping os
    LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
    WHERE osb.item_code = '$item_code'
    LIMIT 1
    "
    order_shopping_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

    # JSONデータからMercariUS側注文情報などを取得
    mercarius_order_number=$(echo "$event_as_json" | jq -r '.ordersn')
    buyer_id=$(echo "$event_as_json" | jq -r '.buyer_id')
    buyer_email_address=$(echo "$event_as_json" | jq -r '.buyer_email_address')

    # order_shopping_breakdown_idをDBから取得
    order_shopping_breakdown_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "SELECT id FROM order_shopping_breakdown WHERE item_code = '$item_code' LIMIT 1")

    # JSONデータから商品情報などを取得
    item=$(echo "$event_as_json" | jq --arg item_code "$item_code" '[.items[] | select(.jp_item_code == $item_code)][0]')
    mercarius_item_code=$(echo "$item" | jq -r '.us_item_code')
    mercarius_category_id=$(echo "$item" | jq -r '.us_category_id')
    mercarius_category_name=$(echo "$item" | jq -r '.us_category_name')
    mercarius_item_name=$(echo "$item" | jq -r '.item_name_en')
    mercarius_item_price=$(echo "$item" | jq -r '.item_price_usd')
    fees=$(echo "$item" | jq -c '.fee')

    # DBから注文に紐付く荷物がすでに登録されているか確認
    sql="
    SELECT ob.baggage_id
    FROM buyee_order bo
    LEFT JOIN order_shopping os ON bo.id = os.order_id
    LEFT JOIN order_shopping_breakdown osb ON os.id = osb.order_shopping_id
    LEFT JOIN order_baggage ob ON bo.id = ob.order_id
    WHERE osb.item_code = '$item_code'
    AND bo.status = 17
    LIMIT 1;
    "
    baggage_id=$(sh shellapp/scripts/db/get_data_from_prd.sh "$sql")

    # データメンテの対応内容の項目に記載する形でデータ出力
    echo ""
    echo $item_code,3085794,4320440,$recipient_name,84,$zip_code,$state_id,$state,$city,$street_address,$additional_address,$recipient_name,$tel,1,$order_shopping_id,上記でインサートしたmember_delivery_address_log.id,$mercarius_order_number,84,4,$buyer_id,$buyer_email_address,上記でインサートしたorder_shopping_mercarius.id,$order_shopping_breakdown_id,$mercarius_item_code,1,$mercarius_category_id,$mercarius_category_name,$mercarius_item_name,$mercarius_item_price,,$baggage_id,上記でインサートしたmember_delivery_address_log.id
    echo $fees
done
