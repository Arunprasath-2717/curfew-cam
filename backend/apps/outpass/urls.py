from django.urls import path
from . import views

app_name = 'outpass'

urlpatterns = [
    path('request/', views.OutpassRequestView.as_view(), name='request'),
    path('history/', views.OutpassHistoryView.as_view(), name='history'),
    path('current/', views.OutpassCurrentView.as_view(), name='current'),
    path('bulk-approve/', views.BulkApproveView.as_view(), name='bulk-approve'),
    path('active/', views.OutsideStudentsView.as_view(), name='active'),
    path('<uuid:pk>/', views.OutpassDetailView.as_view(), name='detail'),
    path('<uuid:pk>/cancel/', views.OutpassCancelView.as_view(), name='cancel'),
    path('<uuid:pk>/return/', views.OutpassReturnView.as_view(), name='return'),
]
