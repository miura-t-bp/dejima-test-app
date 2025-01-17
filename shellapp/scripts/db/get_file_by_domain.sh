# ========================================
# ドメインからDBからデータを取得するシェルスクリプトのファイル名を取得する
# ========================================

domain=$1
if [[ "$domain" == "dejima.local" ]]; then
    # ローカル
    echo "get_data_from_local.sh"
else
    # ドメインからdev環境の番号を取得
    dev_num=$(echo "$domain" | sed -e 's/[^0-9]//g')
    dev_num=$((dev_num))

    # dev環境の番号が13以下の場合pre-prd、それ以外はstg
    if [[ $dev_num -le 13 ]]; then
        echo "get_data_from_pre_prd.sh"
    else
        echo "get_data_from_stg.sh"
    fi
fi
