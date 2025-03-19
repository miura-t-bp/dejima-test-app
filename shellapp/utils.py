def get_domain_by_env(env):
    if env == "local":
        return "dejima.local"
    else:
        return f"{env}.buyee.jp"

def generate_cmd_for_create_mercarius_order(data):
    # 実行環境と作成する注文の商品数を取得
    env = data.get("env")
    item_count = data.get("item_count")
    item_id = data.get("item_id")

    # 実行環境からドメインを取得
    domain = get_domain_by_env(env)

    # コマンドを生成し返す
    cmd = f"bash shellapp/scripts/create_mercarius_order.sh {domain} {item_count} {item_id}".strip()
    return {
        "cmd": cmd,
    }

def generate_cmd_for_create_bunjang_order(data):
    # 実行環境を取得
    env = data.get("env")
    item_id = data.get("item_id")

    # 実行環境からドメインを取得
    domain = get_domain_by_env(env)

    # コマンドを生成し返す
    cmd = f"bash shellapp/scripts/create_bunjang_order.sh {domain} {item_id}".strip()
    return {
        "cmd": cmd,
    }

def generate_cmd_for_create_shopee_order(data):
    # 実行環境を取得
    env = data.get("env")
    item_id = data.get("item_id")

    # 実行環境からドメインを取得
    domain = get_domain_by_env(env)
    if domain != "dejima.local":
        domain = "stg"

    # コマンドを生成し返す
    cmd = f"bash shellapp/scripts/create_shopee_order.sh {domain} {item_id}".strip()
    return {
        "cmd": cmd,
    }

def generate_cmd_for_create_wechat_order(data):
    # 実行環境を取得
    env = data.get("env")

    # 実行環境からドメインを取得
    domain = get_domain_by_env(env)

    # コマンドを生成し返す
    cmd = f"bash shellapp/scripts/create_wechat_order.sh {domain}"
    return {
        "cmd": cmd,
    }

def generate_cmd_for_wechat_baggage_settlement(data):
    # 実行環境を取得
    env = data.get("env")

    # 実行環境からドメインを取得
    domain = get_domain_by_env(env)

    # コマンドを生成し返す
    cmd = f"bash shellapp/scripts/wechat_baggage_settlement.sh {domain} {data.get('baggage_number')}"
    return {
        "cmd": cmd,
    }
