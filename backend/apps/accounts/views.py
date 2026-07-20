"""Account views — register, login, logout, password, OTP, profile."""
import logging
from rest_framework import generics, permissions, status
from rest_framework.exceptions import APIException
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

from apps.common.responses import success_response, error_response, created_response
from .serializers import (
    UserRegistrationSerializer, UserLoginSerializer, UserSerializer,
    UpdateProfileSerializer, ChangePasswordSerializer,
    ForgotPasswordSerializer, VerifyOTPSerializer,
)
from .services import register_user, get_tokens_for_user
from .otp import verify_otp
from .models import User, UserRole

logger = logging.getLogger(__name__)


class RegisterView(APIView):
    """Register a new user."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user, tokens = register_user(serializer.validated_data)
        return created_response(
            data={
                'user': UserSerializer(user).data,
                'tokens': tokens,
            },
            message='Registration successful. Please verify your email.',
        )


class StudentRegisterView(APIView):
    """Register a new student or warden with domain check."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        from .serializers import UnifiedRegisterSerializer
        from .services import register_user_with_domain_check

        serializer = UnifiedRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user, tokens = register_user_with_domain_check(serializer.validated_data)
        return created_response(
            data={
                'user': UserSerializer(user).data,
                'tokens': tokens,
            },
            message='Registration successful. Please verify your email.',
        )


class LoginView(APIView):
    """Login with email and password, returns JWT tokens."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        try:
            serializer = UserLoginSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            role = serializer.validated_data['role']

            user = authenticate(
                request=request,
                username=email,
                password=password,
            )
            if user is None:
                return Response(
                    {'success': False, 'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED,
                )
                
            if user.role != role and not (role == 'warden' and user.role == 'admin_warden'):
                return Response(
                    {'success': False, 'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

            tokens = get_tokens_for_user(user)
            return Response(
                {
                    'success': True,
                    'role': user.role,
                    'user': UserSerializer(user).data,
                    'tokens': tokens,
                },
                status=status.HTTP_200_OK,
            )
        except APIException:
            raise
        except Exception as exc:
            logger.exception('Login failed unexpectedly', exc_info=exc)
            return Response(
                {'success': False, 'error': 'An unexpected error occurred.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class LogoutView(APIView):
    """Blacklist refresh token."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        try:
            refresh = request.data.get('refresh')
            if not refresh:
                return error_response('Refresh token is required')
            token = RefreshToken(refresh)
            token.blacklist()
            return success_response(message='Logged out successfully')
        except Exception:
            return error_response('Invalid token')


class RefreshTokenView(APIView):
    """Refresh access token."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = TokenRefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return success_response(data=serializer.validated_data)


class MeView(APIView):
    """Get current user profile."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        return success_response(data=UserSerializer(request.user).data)


class ProfileUpdateView(generics.UpdateAPIView):
    """Update user profile."""
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UpdateProfileSerializer

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', request.method == 'PATCH')
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return success_response(data=UserSerializer(instance).data, message='Profile updated')


class ChangePasswordView(APIView):
    """Change password (authenticated)."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return error_response('Current password is incorrect')
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return success_response(message='Password changed successfully')


class PasswordResetRequestView(APIView):
    """Request password reset code."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        from .services import request_password_reset
        session_token = request_password_reset(serializer.validated_data['email'])
        return success_response(
            message='If an account exists with this email, you will receive a reset code.',
            data={'reset_session': session_token}
        )


class PasswordResetVerifyOTPView(APIView):
    """Verify password reset OTP without resetting the password."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        from .services import check_password_reset_otp
        
        session_token = request.data.get('session_token')
        code = request.data.get('code')
        
        if not session_token or not code:
            return error_response('session_token and code are required')

        success, msg = check_password_reset_otp(session_token, code)
        if not success:
            return error_response(msg, status_code=status.HTTP_400_BAD_REQUEST)
        return success_response(message=msg)


class VerifyOTPView(APIView):
    """Verify OTP for email verification."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']
        purpose = serializer.validated_data['purpose']

        ok, msg = verify_otp(email, otp, purpose)
        if not ok:
            return error_response(msg)

        if purpose == 'email_verification':
            try:
                user = User.objects.get(email__iexact=email)
                user.is_verified = True
                user.save()
            except User.DoesNotExist:
                return error_response('User not found', status_code=status.HTTP_404_NOT_FOUND)

        return success_response(message='OTP verified successfully')


class PasswordResetConfirmView(APIView):
    """Reset password with token and code."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        from .serializers import ResetPasswordConfirmSerializer
        from .services import confirm_password_reset
        
        serializer = ResetPasswordConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session_token = serializer.validated_data['session_token']
        code = serializer.validated_data['code']

        success, msg = confirm_password_reset(
            session_token, 
            code, 
            serializer.validated_data['new_password']
        )
        if not success:
            return error_response(msg, status_code=status.HTTP_400_BAD_REQUEST)
        return success_response(message=msg)