from django.urls import path
from . import views

app_name = 'watchmen'

urlpatterns = [
    path('dashboard/', views.WatchmanDashboardView.as_view(), name='dashboard'),
    path('shift/start/', views.ShiftStartView.as_view(), name='shift-start'),
    path('shift/end/', views.ShiftEndView.as_view(), name='shift-end'),
    path('scan/', views.QRScanView.as_view(), name='qr-scan'),
    path('logs/', views.ScanLogsView.as_view(), name='scan-logs'),
    path('stats/', views.ScanStatsView.as_view(), name='scan-stats'),
    path('manual-verify/', views.ManualVerifyView.as_view(), name='manual-verify'),
    path('active-passes/', views.ActivePassesView.as_view(), name='active-passes'),
    path('overdue/', views.OverdueStudentsView.as_view(), name='overdue'),
    path('shift-summary/', views.ShiftSummaryView.as_view(), name='shift-summary'),
]
