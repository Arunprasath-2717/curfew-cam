from django.urls import path
from . import views

app_name = 'camera'

urlpatterns = [
    path('', views.CameraListCreateView.as_view(), name='list-create'),
    path('<uuid:pk>/', views.CameraDetailView.as_view(), name='detail'),
    path('<uuid:pk>/health/', views.CameraHealthCheckView.as_view(), name='health-check'),
    path('status/', views.CameraStatusView.as_view(), name='status'),
]
