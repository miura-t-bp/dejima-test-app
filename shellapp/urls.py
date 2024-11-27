from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='shell_index'),
    path('create-mercarius-order/', views.create_mercarius_order_api, name='create_mercarius_order_api'),
    path('create-bunjang-order/', views.create_bunjang_order_api, name='create_bunjang_order_api')
]
