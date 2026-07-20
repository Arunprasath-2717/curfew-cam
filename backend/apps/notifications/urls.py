from django.urls import path
from . import views

app_name = 'notifications'

urlpatterns = [
    path('', views.NotificationListView.as_view(), name='list'),
    path('unread-count/', views.NotificationUnreadCountView.as_view(), name='unread-count'),
    path('mark-read/', views.NotificationMarkReadView.as_view(), name='mark-read'),
    path('mark-all-read/', views.NotificationMarkAllReadView.as_view(), name='mark-all-read'),
    path('emergency/', views.EmergencyNotificationView.as_view(), name='emergency'),
]
