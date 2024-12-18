#!/bin/bash

# ========================================
# WeChat荷物の二次決済を行うスクリプト
#
# 処理の流れ
# 1. JSONデータを作成
# 2. アクセストークンを取得
# 3. 荷物決済コマンドを実行
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

# JSON用のデータを用意
baggage_number=$2

# 各種料金の計算
wechatpay_rate=0.05
gude_rate=0.06

# 日本円関連
original_total_pack_fee=$(sh $GET_DB_DATA_SHELL_FILE "SELECT total_pack_fee FROM baggage WHERE baggage_number = '$baggage_number';")
original_total_pack_fee=$(echo "$original_total_pack_fee" | awk '{print int($1)}')
original_total_bundle_fee=$(sh $GET_DB_DATA_SHELL_FILE "SELECT total_bundle_fee FROM baggage WHERE baggage_number = '$baggage_number';")
original_total_bundle_fee=$(echo "$original_total_bundle_fee" | awk '{print int($1)}')
original_total_photo_fee=$(sh $GET_DB_DATA_SHELL_FILE "SELECT total_photo_fee FROM baggage WHERE baggage_number = '$baggage_number';")
original_total_photo_fee=$(echo "$original_total_photo_fee" | awk '{print int($1)}')
original_international_delivery_fee=1750
original_international_delivery_insurance_fee=0
original_customs_clearance_commission_fee=0
original_delivery_service_fee=0
original_unsettled_storage_cost=0
coupon_discount_amount=0
coupon_discount_type=3
original_total_amount=$(($original_total_pack_fee + $original_total_bundle_fee + $original_total_photo_fee + $original_international_delivery_fee + $original_international_delivery_insurance_fee + $original_customs_clearance_commission_fee + $original_delivery_service_fee + $original_unsettled_storage_cost - $coupon_discount_amount))

# 人民元関連
total_pack_fee=$(echo "$original_total_pack_fee * $gude_rate" | bc)
total_bundle_fee=$(echo "$original_total_bundle_fee * $gude_rate" | bc)
total_photo_fee=$(echo "$original_total_photo_fee * $gude_rate" | bc)
international_delivery_fee=$(echo "$original_international_delivery_fee * $gude_rate" | bc)
international_delivery_insurance_fee=$(echo "$original_international_delivery_insurance_fee * $gude_rate" | bc)
customs_clearance_commission_fee=$(echo "$original_customs_clearance_commission_fee * $gude_rate" | bc)
delivery_service_fee=$(echo "$original_delivery_service_fee * $gude_rate" | bc)
unsettled_storage_cost=$(echo "$original_unsettled_storage_cost * $gude_rate" | bc)
total_amount=$(echo "$original_total_amount * $gude_rate" | bc)

# JSONデータを作成
json_data="{\"baggage_number\":\"$baggage_number\",\"payment\":{\"original_total_amount\":\"$original_total_amount\",\"total_amount\":\"$total_amount\",\"original_total_pack_fee\":\"$original_total_pack_fee\",\"total_pack_fee\":\"$total_pack_fee\",\"original_total_bundle_fee\":\"$original_total_bundle_fee\",\"total_bundle_fee\":\"$total_bundle_fee\",\"original_total_photo_fee\":\"$original_total_photo_fee\",\"total_photo_fee\":\"$total_photo_fee\",\"original_international_delivery_fee\":\"$original_international_delivery_fee\",\"international_delivery_fee\":\"$international_delivery_fee\",\"original_international_delivery_insurance_fee\":\"$original_international_delivery_insurance_fee\",\"international_delivery_insurance_fee\":\"$international_delivery_insurance_fee\",\"original_customs_clearance_commission_fee\":\"$original_customs_clearance_commission_fee\",\"customs_clearance_commission_fee\":\"$customs_clearance_commission_fee\",\"original_delivery_service_fee\":\"$original_delivery_service_fee\",\"delivery_service_fee\":\"$delivery_service_fee\",\"original_unsettled_storage_cost\":\"$original_unsettled_storage_cost\",\"unsettled_storage_cost\":\"$unsettled_storage_cost\",\"coupon_discount_amount\":$coupon_discount_amount,\"coupon_discount_type\":$coupon_discount_type,\"wechat_settlement_id\":123321,\"wechatpay_transation_id\":\"234432\",\"fintech_transation_id\":\"345543\",\"wechatpay_rate\":\"$wechatpay_rate\",\"gude_rate\":\"$gude_rate\"},\"shipment\":{\"shipping_fee\":0,\"country_code_iso_3166_alpha_2_code\":\"CN\",\"zip_code\":\"110000\",\"state\":\"北京\",\"city\":\"北京市\",\"town\":\"丰台区\",\"district\":\"街道\",\"full_address\":\"123北京市54321\",\"recipient_name\":\"受取人名\",\"tel\":\"090012345678\",\"fax\":null},\"international_delivery_method_id\":36,\"event_code\":\"regist_sttlement_and_delivery_info\"}"

# アクセストークンを取得
access_token=$(sh $NOW_DIR/wechat/get_access_token.sh $domain)

# 二次決済と配送依頼を行う
url="https://{$domain}/publicApi/wechat-event/registSettlementAndDeliveryInfo"
curl -X POST $url \
     -H "User-agent: pharos" \
     -d "access_token=$access_token" \
     -d "json_data=$json_data" \
     --insecure
