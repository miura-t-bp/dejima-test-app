from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='shell_index'),
    path('create-mercarius-order/', views.create_mercarius_order_api, name='create_mercarius_order_api'),
    path('create-bunjang-order/', views.create_bunjang_order_api, name='create_bunjang_order_api'),
    path('create-shopee-order/', views.create_shopee_order_api, name='create_shopee_order_api'),
    path('create-wechat-order/', views.create_wechat_order_api, name='create_wechat_order_api'),
    path('wechat-baggage-settlement/', views.wechat_baggage_settlement_api, name='wechat_baggage_settlement_api'),
]
