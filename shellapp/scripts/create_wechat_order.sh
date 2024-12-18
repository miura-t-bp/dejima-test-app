#!/bin/bash

# ========================================
# WeChat注文を作成するスクリプト
#
# 処理の流れ
# 1. DBから最新のWeChat注文番号を取得
# 2. 取得したWeChat注文番号に1を足して新しいWeChat注文番号を作成
# 3. 新しいWeChat注文番号に重複がないか確認
# 4. メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
# 5. JSONデータを作成
# 6. アクセストークンを取得
# 7. 注文作成コマンドを実行
# ========================================

# 現在のスクリプトが存在するディレクトリを取得
NOW_DIR=$(dirname "$0")

domain=$1
if [[ "$domain" == "dejima.local" ]]; then
    # DBからデータを取得するシェルスクリプトのパス
    GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/get_data_from_local.sh"
else
    GET_DB_DATA_SHELL_FILE="$NOW_DIR/db/get_data_from_stg.sh"
fi

# 最新のWeChat注文番号を取得
latest_wechat_order_number=$(sh $GET_DB_DATA_SHELL_FILE "SELECT wechat_order_number FROM order_shopping_wechat ORDER BY id DESC LIMIT 1;")

# 新しいWeChat注文番号を生成
date_of_latest_wechat_order_number=${latest_wechat_order_number:6:6}
today=$(date +"%y%m%d")
if [[ "$date_of_latest_wechat_order_number" == "$today" ]]; then
    num=${latest_wechat_order_number:12:3}
    new_wechat_order_number="wechat${today}$(printf "%03d" $((10#$num + 1)))"

else
    new_wechat_order_number="wechat${today}001"
fi

# 新しいWeChat注文番号が重複していないか確認
wechat_order=$(sh $GET_DB_DATA_SHELL_FILE "SELECT id FROM order_shopping_wechat WHERE wechat_order_number = '$new_wechat_order_number';")
if [[ -n "$wechat_order" ]]; then
    echo "新しく生成したWeCHat注文番号が重複しています。new_wechat_order_number: $new_wechat_order_number"
    exit 1
fi

# メルカリ商品検索APIからフィギュアカテゴリの任意の商品を取得
category_id=81
items=$(sh $NOW_DIR/mercari_api/get_prd_item.sh $category_id 1)
item_data=$(echo "$items" | jq -c '.[]')

# JSON用のデータを用意
item_code=$(echo "$item_data" | jq -r '.id')
name=$(echo "$item_data" | jq -r '.name')
seller_id=$(echo "$item_data" | jq -r '.seller.id')
seller_name=$(echo "$item_data" | jq -r '.seller.name')

# 各種料金の計算
wechatpay_rate=0.05
gude_rate=0.06

# 日本円関連
original_item_price=$(echo "$item_data" | jq -r '.price')
original_buyee_fee=300
original_plan_fee=500
coupon_discount_amount=0
coupon_discount_type=1
original_amount=$(($original_item_price + $original_buyee_fee + $original_plan_fee - $coupon_discount_amount))

# 人民元関連
if [ "$coupon_discount_type" -eq 1 ]; then
     item_price=$(echo "($original_item_price - $coupon_discount_amount) * $gude_rate" | bc)
     buyee_fee=$(echo "$original_buyee_fee * $gude_rate" | bc)
elif [ "$number" -eq 2 ]; then
     item_price=$(echo "$original_item_price * $gude_rate" | bc)
     buyee_fee=$(echo "($original_buyee_fee - $coupon_discount_amount) * $gude_rate" | bc)
fi
plan_fee=$(echo "$original_plan_fee * $gude_rate" | bc)
amount=$(echo "$item_price + $buyee_fee + $plan_fee" | bc)

# WeChat側会員情報関連
wechat_member_id="241217002"

# JSONデータを作成
json_data="{\"items\":[{\"item_code\":\"$item_code\",\"product_code\":null,\"item_name\":\"$name\",\"quantity\":1,\"options\":null,\"sku\":\"$item_code\",\"item_url\":\"https://jp.mercari.com/item/$item_code\",\"item_image_url\":\"https://static.gude.cn/item/detail/orig/photos/$item_code.jpg\",\"seller\":{\"id\":\"$seller_id\",\"name\":\"$seller_name\"},\"item_can_buy\":true,\"shipping_payer_id\":2,\"use_cover_option\":false,\"original_item_price\":\"$original_amount\",\"item_price\":\"$amount\",\"plan_id\":1,\"item_payment\":{\"original_item_price\":\"$original_item_price\",\"original_buyee_fee\":\"$original_buyee_fee\",\"original_plan_fee\":\"$original_plan_fee\",\"original_amount\":\"$original_amount\",\"item_price\":\"$item_price\",\"buyee_fee\":\"$buyee_fee\",\"plan_fee\":\"$plan_fee\",\"amount\":\"$amount\",\"coupon_discount_amount\":\"$coupon_discount_amount\",\"coupon_discount_type\":$coupon_discount_type}}],\"payment\":{\"wechat_settlement_id\":\"1234321\",\"wechatpay_transation_id\":\"2345432\",\"fintech_transation_id\":\"3456543\",\"wechatpay_rate\":\"$wechatpay_rate\",\"gude_rate\":\"$gude_rate\"},\"shipment\":{\"shipping_fee\":0,\"country_code_iso_3166_alpha_2_code\":\"CN\",\"zip_code\":\"110100\",\"state\":\"北京\",\"city\":\"北京市\",\"town\":\"丰台区\",\"district\":\"街道\",\"full_address\":\"123北京市54321\",\"recipient_name\":\"受取人名\",\"tel\":\"090012345678\",\"fax\":null},\"event_code\":\"order_create\",\"ordersn\":\"$new_wechat_order_number\",\"buyer_username\":\"test user name\",\"create_time\":1734330783,\"country_code\":\"CN\",\"currency_code\":\"CNY\",\"wechat_member_id\":$wechat_member_id,\"wechat_shop_code\":\"wechat1\"}"

# アクセストークンを取得
access_token=$(sh $NOW_DIR/wechat/get_access_token.sh $domain)

echo "WeChat注文を作成します。item_code: $item_code, new_wechat_order_number: $new_wechat_order_number"

# 注文作成
url="https://{$domain}/publicApi/wechat-event/orderCreate"
curl -X POST $url \
     -H "User-agent: pharos" \
     -d "access_token=$access_token" \
     -d "json_data=$json_data" \
     --insecure
