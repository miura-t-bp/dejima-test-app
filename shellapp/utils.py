def generate_cmd_for_create_mercarius_order(data):
    # 実行環境と作成する注文の商品数を取得
    env = data.get("env")
    item_count = data.get("item_count")

    domain = f"{env}.buyee.jp"
    cmd = f"bash shellapp/scripts/create_mercarius_order.sh {item_count} {domain}"
    return {
        "cmd": cmd,
    }

def generate_cmd_for_create_bunjang_order(data):
    # 実行環境を取得
    env = data.get("env")

    domain = f"{env}.buyee.jp"
    cmd = f"bash shellapp/scripts/create_bunjang_order.sh {domain}"
    return {
        "cmd": cmd,
    }
