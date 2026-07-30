from rest_framework import serializers
from django.utils import timezone
from .models import Complaint, ComplaintCategory, ComplaintPriority, ComplaintStatus


class ComplaintSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    student_register_number = serializers.SerializerMethodField()
    student_room = serializers.SerializerMethodField()
    student_block = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    priority_display = serializers.CharField(source='get_priority_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    assigned_warden_name = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
        fields = (
            'id', 'student', 'student_name', 'student_register_number',
            'student_room', 'student_block', 'title', 'category',
            'category_display', 'priority', 'priority_display',
            'description', 'status', 'status_display', 'is_anonymous',
            'warden_response', 'assigned_warden', 'assigned_warden_name',
            'resolved_at', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'student', 'created_at', 'updated_at', 'resolved_at')

    def get_student_name(self, obj):
        if obj.is_anonymous:
            return "Anonymous Student"
        if hasattr(obj.student, 'full_name'):
            return obj.student.full_name
        return obj.student.email

    def get_student_register_number(self, obj):
        if obj.is_anonymous:
            return "N/A"
        if hasattr(obj.student, 'student_profile'):
            return obj.student.student_profile.register_number
        return ""

    def get_student_room(self, obj):
        if hasattr(obj.student, 'student_profile'):
            return obj.student.student_profile.room_number
        return ""

    def get_student_block(self, obj):
        if hasattr(obj.student, 'student_profile'):
            return obj.student.student_profile.hostel_block
        return ""

    def get_assigned_warden_name(self, obj):
        if obj.assigned_warden:
            return getattr(obj.assigned_warden, 'full_name', obj.assigned_warden.email)
        return None


class ComplaintCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = ('title', 'category', 'priority', 'description', 'is_anonymous')

    def validate_title(self, value):
        if not value.strip():
            raise serializers.ValidationError("Title cannot be empty.")
        return value.strip()

    def validate_description(self, value):
        if not value.strip():
            raise serializers.ValidationError("Description cannot be empty.")
        return value.strip()


class ComplaintStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = ('status', 'warden_response')

    def update(self, instance, validated_data):
        new_status = validated_data.get('status', instance.status)
        instance.status = new_status
        instance.warden_response = validated_data.get('warden_response', instance.warden_response)
        
        request_user = self.context.get('request').user if self.context.get('request') else None
        if request_user and request_user.role in ['warden', 'admin_warden', 'admin']:
            instance.assigned_warden = request_user

        if new_status in [ComplaintStatus.RESOLVED, ComplaintStatus.REJECTED]:
            if not instance.resolved_at:
                instance.resolved_at = timezone.now()
        else:
            instance.resolved_at = None

        instance.save()
        return instance
