# myapp/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='selenium_index'),
    path('regist-baggage/', views.regist_baggage_api, name='regist_baggage_api'),
    path('bundle-baggage/', views.bundle_baggage_api, name='bundle_baggage_api'),
    path('regist-baggage-weight/', views.regist_baggage_weight_api, name='regist_baggage_weight_api'),
    path('invoice-detail-input/', views.invoice_detail_input_api, name='invoice_detail_input_api'),
]
