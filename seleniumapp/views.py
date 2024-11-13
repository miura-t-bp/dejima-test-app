from django.http import HttpResponse
from django.shortcuts import render
from django.http import JsonResponse

from .utils import regist_baggage, bundle_baggage, regist_baggage_weight, invoice_detail_input

import json

def index(request):
    return render(request, "selenium_index.html")

def regist_baggage_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # 荷物登録
        res = regist_baggage(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def bundle_baggage_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # 同梱作業チェック完了
        res = bundle_baggage(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def regist_baggage_weight_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # 同梱作業チェック完了
        res = regist_baggage_weight(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)

def invoice_detail_input_api(request):
    if request.method == 'POST':
        # リクエストのボディからJSONデータを取得
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        res = invoice_detail_input(data)

        return JsonResponse(res)

    return JsonResponse({'error': 'Invalid request method'}, status=405)
