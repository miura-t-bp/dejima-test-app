# ========================================
# pre-prdのDBから引数で指定されたSQLを実行し、結果を返す
# ========================================

data=$(ssh sss "mysql buyee -u\$DEJIMA_USER -p\$DEJIMA_PASS -h\$PRE_PRD_DB_HOST -se \"$1\" 2>/dev/null")

echo $data
