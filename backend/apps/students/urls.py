from django.urls import path
from . import views

app_name = 'students'

urlpatterns = [
    path('profile/', views.StudentProfileDetailView.as_view(), name='profile'),
    path('profile/create/', views.StudentProfileCreateView.as_view(), name='profile-create'),
    path('list/', views.StudentListView.as_view(), name='student-list'),
    path('search/', views.StudentSearchView.as_view(), name='student-search'),
    path('verify-location/', views.VerifyLocationView.as_view(), name='verify-location'),
    path('<uuid:pk>/', views.StudentDetailByIdView.as_view(), name='student-detail'),
    path('<uuid:pk>/violations/', views.StudentViolationsView.as_view(), name='student-violations'),
    path('guardians/', views.GuardianListView.as_view(), name='guardian-list'),
    path('guardians/add/', views.GuardianCreateView.as_view(), name='guardian-add'),
]