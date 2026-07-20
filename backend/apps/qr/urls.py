from django.urls import path
from . import views

app_name = 'qr'

urlpatterns = [
    path('generate/<uuid:outpass_id>/', views.QRGenerateView.as_view(), name='generate'),
    path('regenerate/<uuid:outpass_id>/', views.QRRegenerateView.as_view(), name='regenerate'),
    path('validate/', views.QRValidateView.as_view(), name='validate'),
    path('detail/<uuid:outpass_id>/', views.QRDetailView.as_view(), name='detail'),
]
