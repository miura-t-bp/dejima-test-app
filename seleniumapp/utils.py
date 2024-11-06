from .classes.cswh import CsWh

import subprocess

def regist_baggage(data):

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

    # 注文番号が指定されている場合は、個数を1に設定
    if order_number:
        quantity = 1

    # 指定された個数分の荷物登録を行う
    res = {"order_numbers": [], "baggage_numbers": []}
    for _ in range(quantity):
        # 注文番号が指定されていない場合は、最新の注文番号を取得
        regist_order_number = order_number if order_number else cswh.get_latest_order_number_by_service(service)

        # 荷物仮登録
        baggage_number, err_message = cswh.regist_baggage(regist_order_number)
        if err_message:
            return error_response(err_message)

        # 重量・寸法登録スキップオプションが指定されていない場合は重量・寸法登録
        if not data.get("no_weight_regist"):
            baggage_number, err_message = cswh.regist_weight(baggage_number)
            if err_message:
                return error_response(err_message)

        # 登録個数が1つの場合
        if quantity == 1:
            # CS荷物詳細画面から荷物ステータスとURLを取得
            baggage_status, cs_baggage_detail_url = cswh.get_baggage_status_and_detail_url(baggage_number)
            return {
                "order_number": order_number,
                "baggage_number": baggage_number,
                "baggage_status": baggage_status,
                "cs_baggage_detail_url": cs_baggage_detail_url
            }
        else:
            res["order_numbers"].append(regist_order_number)
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
    else:
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
    else:
        return {"baggage_number": baggage_number}

def error_response(err_message):
    return {
        "error": err_message
    }
