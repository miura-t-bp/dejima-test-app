from .classes.cswh import CsWh

import logging
import os

#  ログディレクトリが存在しない場合は作成
os.makedirs("/app/logs", exist_ok=True)

# ロガー設定
info_logger = logging.getLogger("info_logger")
info_logger.setLevel(logging.INFO)

# ファイルハンドラー設定
file_handler = logging.FileHandler("/app/logs/info.log")
file_handler.setLevel(logging.INFO)

# フォーマット設定
formatter = logging.Formatter('[%(asctime)s][%(levelname)s] %(message)s')
file_handler.setFormatter(formatter)

# ロガーにハンドラーを追加
info_logger.addHandler(file_handler)

def regist_baggage(data):

    info_logger.info("====== 荷物登録処理 開始 ======")

    # テスト環境を取得し、CsWhクラス生成
    cswh = CsWh(data.get("env"))

    # 荷物登録する注文番号を取得
    order_number = data.get("order_number")
    service = data.get("service")
    quantity = int(data.get("quantity"))

    # 注文番号とサービスのどちらも指定されていない場合はエラー
    if not order_number and service == "-1":
        return error_response("荷物登録する注文番号もしくはサービスを指定してください。")

    # 個数が2個以上でサービスが指定されていない場合はエラー
    if quantity > 1 and service == "-1":
        return error_response("複数注文の荷物登録を行う場合はサービスを指定してください。")

    # 個数が25個より多い場合はエラー
    if quantity > 25:
        return error_response("一度に登録できる荷物は25個までです。")

    # 対象
    if order_number:
        order_numbers = [order_number]
    else:
        info_logger.info(f"対象取得開始 個数:{quantity}")
        order_numbers = cswh.get_latest_order_numbers_by_service(service, quantity)

    info_logger.info(f"対象注文番号:{order_numbers}")

    # レスポンス用の辞書
    res = {
        "order_numbers": order_numbers,
        "baggage_numbers": []
    }

    # 注文番号それぞれに対して荷物登録を行う
    for regist_order_number in order_numbers:
        # 荷物仮登録
        info_logger.info(f"登録開始 注文番号:{order_numbers}")
        baggage_number, err_message = cswh.regist_baggage(regist_order_number)
        if err_message:
            return error_response(err_message)

        # 重量・寸法登録スキップオプションが指定されていない場合は重量・寸法登録
        if not data.get("no_weight_regist"):
            baggage_number, err_message = cswh.regist_weight(baggage_number)
            if err_message:
                return error_response(err_message)

        # 登録個数が1つの場合
        if len(order_numbers) == 1:
            # CS荷物詳細画面から荷物ステータスとURLを取得
            baggage_status, cs_baggage_detail_url = cswh.get_baggage_status_and_detail_url(baggage_number)
            return {
                "order_number": order_number,
                "baggage_number": baggage_number,
                "baggage_status": baggage_status,
                "cs_baggage_detail_url": cs_baggage_detail_url
            }
        else:
            res["baggage_numbers"].append(baggage_number)

    return res

def regist_baggage_weight(data):

    # テスト環境を取得し、CsWhクラス生成
    cswh = CsWh(data.get("env"))

    # 重量・寸法登録
    baggage_number, err_message = cswh.regist_weight(data.get("baggage_number"))

    # CS荷物詳細画面から荷物ステータスとURLを取得
    baggage_status, cs_baggage_detail_url = cswh.get_baggage_status_and_detail_url(baggage_number)

    if err_message:
        return error_response(err_message)

    return {
        "baggage_number": baggage_number,
        "baggage_status": baggage_status,
        "cs_baggage_detail_url": cs_baggage_detail_url
    }

def bundle_baggage(data):

    # テスト環境を取得し、CsWhクラス生成
    cswh = CsWh(data.get("env"))

    # 同梱作業
    bundle_baggage_number = data.get("bundle_baggage_number")
    cswh.bundle_baggage(bundle_baggage_number)

    return {"bundle_baggage_number": bundle_baggage_number}

def invoice_detail_input(data):

    # テスト環境を取得し、CsWhクラス生成
    cswh = CsWh(data.get("env"))

    # インボイス詳細登録（DHL）
    baggage_number, err_message = cswh.invoice_detail_input(data.get("baggage_number"))

    if err_message:
        return error_response(err_message)

    return {"baggage_number": baggage_number}

def error_response(err_message):
    return {
        "error": err_message
    }
