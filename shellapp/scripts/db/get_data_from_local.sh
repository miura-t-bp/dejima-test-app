# ========================================
# localのDBから引数で指定されたSQLを実行し、結果を返す
# ========================================

data=$(docker exec -i dejima_app bash -c "
    ROOT_PWD=\${PWD#/} && \
    mysql buyee -u root -p\"\$ROOT_PWD\" -h db -se \"$1\" 2>/dev/null | xargs
")

echo $data
