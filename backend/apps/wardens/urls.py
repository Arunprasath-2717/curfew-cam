from django.urls import path
from . import views
from . import management_views

app_name = 'wardens'

urlpatterns = [
    path('dashboard/', views.WardenDashboardView.as_view(), name='dashboard'),
    path('pending/', views.PendingOutpassListView.as_view(), name='pending'),
    path('outpass/<uuid:pk>/approve/', views.OutpassApprovalView.as_view(), name='approve'),
    path('outpass/<uuid:pk>/override/', views.OutpassOverrideView.as_view(), name='override'),
    path('late-students/', views.LateStudentsView.as_view(), name='late-students'),
    path('movement-logs/', views.MovementLogListView.as_view(), name='movement-logs'),
    path('reports/', views.WardenReportsView.as_view(), name='reports'),
    path('history/', views.WardenOutpassHistoryView.as_view(), name='history'),

    # Management
    path('manage/students/', management_views.ManageStudentsView.as_view(), name='manage-students'),
    path('manage/students/<uuid:pk>/', management_views.ManageStudentDetailView.as_view(), name='manage-student-detail'),
    path('manage/wardens/', management_views.ManageWardensView.as_view(), name='manage-wardens'),
    path('manage/wardens/<uuid:pk>/', management_views.ManageWardenDetailView.as_view(), name='manage-warden-detail'),
    path('manage/run-promotion/', management_views.RunPromotionView.as_view(), name='manage-run-promotion'),
    path('manage/audit-log/', management_views.AuditLogListView.as_view(), name='manage-audit-log'),

    # Warden Setup (Onboarding)
    path('setup/signup/', management_views.WardenSignupView.as_view(), name='setup-signup'),
]
