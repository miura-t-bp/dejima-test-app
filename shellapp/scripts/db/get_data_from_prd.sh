# ========================================
# 本番のDBから引数で指定されたSQLを実行し、結果を返す
# ========================================

data=$(ssh pos "mysql buyee -u \$DEJIMA_RO_USER -p\$DEJIMA_RO_PASS -h \$DB_HOST -se \"$1\" 2>/dev/null")

echo $data
