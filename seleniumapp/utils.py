from .classes.cswh import CsWh

import logging
import time
import os

# 日本時間（JST）に変換するためのコンバータ
def jst_converter(*args):
    return time.localtime(time.time() + 9 * 3600)  # UTC+9

# ロガー設定用関数
def setup_logger():
    # ログディレクトリが存在しない場合は作成
    os.makedirs("/app/logs", exist_ok=True)

    # ロガー設定
    logger = logging.getLogger("logger")
    logger.setLevel(logging.DEBUG)

    # フォーマッタを日本時間に設定
    logging.Formatter.converter = jst_converter
    formatter = logging.Formatter('[%(asctime)s][%(levelname)s] %(message)s')

    # ハンドラー設定
    handlers = {
        "error": ("/app/logs/error.log", logging.ERROR),
        "info": ("/app/logs/info.log", logging.INFO),
        "debug": ("/app/logs/debug.log", logging.DEBUG)
    }

    # 各ハンドラーを作成しロガーに追加
    for handler_name, (file_path, level) in handlers.items():
        handler = logging.FileHandler(file_path)
        handler.setLevel(level)
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger

# ロガーを設定
logger = setup_logger()

def regist_baggage(data):
    try:
        logger.info("====== 荷物登録処理 開始 ======")

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
            logger.info(f"対象取得開始 個数:{quantity}")
            order_numbers = cswh.get_latest_order_numbers_by_service(service, quantity)

        logger.info(f"対象注文番号:{order_numbers}")

        # レスポンス用の辞書
        res = {
            "order_numbers": order_numbers,
            "baggage_numbers": []
        }

        # 注文番号それぞれに対して荷物登録を行う
        for regist_order_number in order_numbers:
            # 荷物仮登録
            logger.info(f"登録開始 注文番号:{regist_order_number}")
            baggage_number = cswh.regist_baggage(regist_order_number)

            # 重量・寸法登録スキップオプションが指定されていない場合は重量・寸法登録
            if not data.get("no_weight_regist"):
                cswh.regist_weight(baggage_number, data.get("weight_gram"), data.get("length_mm"), data.get("width_mm"), data.get("height_mm"))

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
    except Exception as e:
        logger.error(e)
        return error_response(f"荷物登録に失敗しました。order_number:{regist_order_number}")

def regist_baggage_weight(data):
    try:
        # テスト環境を取得し、CsWhクラス生成
        cswh = CsWh(data.get("env"))

        # 重量・寸法登録
        baggage_number = data.get("baggage_number")
        cswh.regist_weight(baggage_number, data.get("weight_gram"), data.get("length_mm"), data.get("width_mm"), data.get("height_mm"))

        # CS荷物詳細画面から荷物ステータスとURLを取得
        baggage_status, cs_baggage_detail_url = cswh.get_baggage_status_and_detail_url(baggage_number)

        return {
            "baggage_number": baggage_number,
            "baggage_status": baggage_status,
            "cs_baggage_detail_url": cs_baggage_detail_url
        }
    except Exception as e:
        logger.error(e)
        return error_response(f"重量・寸法登録に失敗しました。")

def bundle_baggage(data):
    try:
        # テスト環境を取得し、CsWhクラス生成
        cswh = CsWh(data.get("env"))

        # 同梱作業
        bundle_baggage_number = data.get("bundle_baggage_number")
        cswh.bundle_baggage(bundle_baggage_number)

        return {"bundle_baggage_number": bundle_baggage_number}
    except Exception as e:
        logger.error(e)
        return error_response(f"同梱作業チェックに失敗しました。")

def invoice_detail_input(data):
    try:
        # テスト環境を取得し、CsWhクラス生成
        cswh = CsWh(data.get("env"))

        # インボイス詳細登録（DHL）
        baggage_number = data.get("baggage_number")
        cswh.invoice_detail_input(baggage_number)

        return {"baggage_number": baggage_number}
    except Exception as e:
        logger.error(e)
        return error_response(f"インボイス詳細登録（DHL）に失敗しました。")

def error_response(error_message):
    return {"error": error_message}
