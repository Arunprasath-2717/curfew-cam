from django.urls import path
from . import views

app_name = 'detection'

urlpatterns = [
    path('webhook/', views.DetectionWebhookView.as_view(), name='webhook'),
    path('list/', views.DetectionListView.as_view(), name='list'),
    path('alerts/', views.AlertListView.as_view(), name='alert-list'),
    path('alerts/<uuid:pk>/acknowledge/', views.AlertAcknowledgeView.as_view(), name='alert-acknowledge'),
    path('analyze/', views.DetectionAnalyzeView.as_view(), name='analyze'),
    path('stream/<str:action>/', views.DetectionStreamControlView.as_view(), name='stream-control'),
]
