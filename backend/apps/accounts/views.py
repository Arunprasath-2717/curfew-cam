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
    VerifyOTPSerializer,
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

            if role == 'watchman' and '@' not in email:
                # Input is a phone number — resolve to email
                try:
                    from apps.watchmen.models import WatchmanProfile
                    watchman = WatchmanProfile.objects.get(user__phone_number=email)
                    email = watchman.user.email
                except WatchmanProfile.DoesNotExist:
                    try:
                        from apps.accounts.models import User
                        user = User.objects.get(phone_number=email, role='watchman')
                        email = user.email
                    except User.DoesNotExist:
                        return Response(
                            {'success': False, 'error': 'Invalid credentials'},
                            status=status.HTTP_401_UNAUTHORIZED,
                        )

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
                
            is_warden_match = role in ('warden', 'admin_warden') and user.role in ('warden', 'admin_warden')
            if user.role != role and not is_warden_match:
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

class UpdateFCMTokenView(APIView):
    """Update FCM token for push notifications."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        fcm_token = request.data.get('fcm_token')
        if not fcm_token:
            return error_response('fcm_token is required')
            
        request.user.fcm_token = fcm_token
        request.user.save(update_fields=['fcm_token'])
        return success_response(message='FCM token updated successfully')

import pandas as pd
from django.db import transaction

class StudentBulkUploadView(APIView):
    """Upload CSV/Excel of students and populate StudentWhitelist."""
    permission_classes = (permissions.AllowAny,)  # For testing, you can change this to IsAdminUser later

    def post(self, request):
        file = request.FILES.get('file')
        if not file:
            return error_response('No file uploaded.')
            
        try:
            if file.name.endswith('.csv'):
                df = pd.read_csv(file)
            elif file.name.endswith('.xlsx'):
                df = pd.read_excel(file)
            else:
                return error_response('Unsupported file format. Please upload .csv or .xlsx')
                
            required_columns = {'name', 'register_number', 'department', 'year', 'hostel_block', 'room_number'}
            if not required_columns.issubset(set(df.columns)):
                return error_response(f'Missing required columns. Expected: {", ".join(required_columns)}')
            
            # Sort/Extract by year as requested
            df = df.sort_values(by='year')
            
            from apps.accounts.models import StudentWhitelist
            
            added = 0
            updated = 0
            
            with transaction.atomic():
                for _, row in df.iterrows():
                    obj, created = StudentWhitelist.objects.update_or_create(
                        register_number=str(row['register_number']).strip(),
                        defaults={
                            'name': str(row['name']).strip(),
                            'department': str(row['department']).strip(),
                            'year': int(row['year']),
                            'hostel_block': str(row['hostel_block']).strip(),
                            'room_number': str(row['room_number']).strip(),
                        }
                    )
                    if created:
                        added += 1
                    else:
                        updated += 1
                        
            return success_response(message=f'Successfully processed file. Added {added}, updated {updated} students.')
            
        except Exception as e:
            logger.exception("Error processing file")
            return error_response(f'Error processing file: {str(e)}')
