from django.shortcuts import render
from django.http import JsonResponse

from .utils import generate_cmd_for_create_mercarius_order, generate_cmd_for_create_bunjang_order, generate_cmd_for_create_wechat_order, generate_cmd_for_wechat_baggage_settlement

import json

def index(request):
    return render(request, 'shell_index.html')

def create_mercarius_order_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # MercariUS注文作成用コマンドを生成
        res = generate_cmd_for_create_mercarius_order(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def create_bunjang_order_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # Bunjang注文作成用コマンドを生成
        res = generate_cmd_for_create_bunjang_order(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def create_wechat_order_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # WeChat注文作成用コマンドを生成
        res = generate_cmd_for_create_wechat_order(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def wechat_baggage_settlement_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # WeChat荷物決済用コマンドを生成
        res = generate_cmd_for_wechat_baggage_settlement(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)
