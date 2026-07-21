"""Account serializers."""
from rest_framework import serializers
from .models import User, UserRole


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ('email', 'password', 'password2', 'first_name', 'last_name', 'role', 'phone_number')
        extra_kwargs = {
            'first_name': {'required': False},
            'last_name': {'required': False},
            'role': {'required': False},
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({'password': "Passwords don't match."})
        return attrs


class UnifiedRegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8, style={'input_type': 'password'})
    phone_number = serializers.CharField(max_length=15, required=False, allow_blank=True)
    
    # Optional fields depending on role (validated in service)
    register_number = serializers.CharField(max_length=30, required=False, allow_blank=True)
    block = serializers.CharField(max_length=50, required=False, allow_blank=True)
    department = serializers.CharField(max_length=100, required=False, allow_blank=True)
    year = serializers.IntegerField(required=False, min_value=1, max_value=5, allow_null=True)
    room_number = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_password(self, value):
        from django.contrib.auth.password_validation import validate_password
        validate_password(value)
        return value


class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    role = serializers.ChoiceField(choices=UserRole.choices)


class UserSerializer(serializers.ModelSerializer):
    is_main_warden = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'email', 'username', 'first_name', 'last_name',
            'role', 'phone_number', 'date_of_birth', 'avatar',
            'is_verified', 'date_joined', 'created_at', 'is_main_warden',
        )
        read_only_fields = ('id', 'email', 'is_verified', 'date_joined', 'created_at')

    def get_is_main_warden(self, obj):
        if obj.role == 'warden' and hasattr(obj, 'warden_profile'):
            return getattr(obj.warden_profile, 'is_main_warden', False)
        return False


class UpdateProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'phone_number', 'date_of_birth', 'avatar')


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=8)
    new_password2 = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({'new_password': "Passwords don't match."})
        return attrs


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=6, min_length=6)
    purpose = serializers.ChoiceField(
        choices=['email_verification'],
        default='email_verification',
    )

