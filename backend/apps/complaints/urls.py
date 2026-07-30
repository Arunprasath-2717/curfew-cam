from django.urls import path
from . import views

app_name = 'complaints'

urlpatterns = [
    path('', views.ComplaintListCreateView.as_view(), name='complaint-list-create'),
    path('stats/', views.ComplaintStatsView.as_view(), name='complaint-stats'),
    path('<uuid:pk>/', views.ComplaintDetailView.as_view(), name='complaint-detail'),
    path('<uuid:pk>/status/', views.ComplaintStatusUpdateView.as_view(), name='complaint-status-update'),
]
