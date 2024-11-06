from classes.cswh import CsWh

# テスト環境を取得し、CsWhクラス生成
cswh = CsWh("local")

# 同梱作業
baggage_number = "G2310020042"
baggage_number, err = cswh.regist_weight(baggage_number)

print(err)
