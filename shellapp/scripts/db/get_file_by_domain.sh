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

    # pre-prdを使用しているdev環境の番号
    pre_prd_dev_numbers=(1 2 3 4 6 8 9 10 11 12 13 18)

    for num in "${pre_prd_dev_numbers[@]}"; do
        if [[ "$num" -eq "$dev_num" ]]; then
            is_pre_prd=true
            break
        fi
    done

    # dev環境の番号が13以下の場合pre-prd、それ以外はstg
    if [[ "$is_pre_prd" -eq true ]]; then
        echo "get_data_from_pre_prd.sh"
    else
        echo "get_data_from_stg.sh"
    fi
fi
