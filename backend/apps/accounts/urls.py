from django.urls import path
from . import views

app_name = 'accounts'

urlpatterns = [
    path('register/', views.RegisterView.as_view(), name='register'),
    path('register/student/', views.StudentRegisterView.as_view(), name='register-student'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('refresh/', views.RefreshTokenView.as_view(), name='token-refresh'),
    path('me/', views.MeView.as_view(), name='me'),
    path('profile/', views.ProfileUpdateView.as_view(), name='profile-update'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    path('verify-otp/', views.VerifyOTPView.as_view(), name='verify-otp'),
    path('password-reset/request/', views.PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/verify-otp/', views.PasswordResetVerifyOTPView.as_view(), name='password-reset-verify-otp'),
    path('password-reset/confirm/', views.PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
]