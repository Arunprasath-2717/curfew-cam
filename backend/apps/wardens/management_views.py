from rest_framework import generics, permissions
from rest_framework.views import APIView
from apps.common.responses import success_response, error_response
from apps.accounts.permissions import IsAdminOrWarden, IsAdminWarden
from apps.students.models import StudentProfile
from apps.students.serializers import StudentProfileSerializer
from apps.wardens.models import AuditLog, WardenProfile
from apps.wardens.serializers import (
    AuditLogSerializer, ManageStudentSerializer, ManageWardenSerializer, WardenProfileSerializer
)
from apps.accounts.models import User, UserRole

class ManageStudentsView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        students = StudentProfile.objects.select_related('user').all()
        return success_response(data=StudentProfileSerializer(students, many=True).data)

    def post(self, request):
        serializer = ManageStudentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        
        email = data['email']
        if User.objects.filter(email=email).exists():
            return error_response('User with this email already exists.')
            
        user = User.objects.create_user(
            email=email,
            password=data['password'],
            first_name=data['first_name'],
            last_name=data.get('last_name', ''),
            role=UserRole.STUDENT,
            is_verified=True
        )
        
        profile = user.student_profile
        profile.register_number = data['register_number']
        profile.department = data['department']
        profile.year = data['year']
        profile.hostel_block = 'TBD'
        profile.room_number = 'TBD'
        profile.save()
        
        AuditLog.objects.create(
            action='create_student',
            performed_by=request.user,
            target_email=email
        )
        
        return success_response(message='Student account created successfully.')

class ManageStudentDetailView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    
    def delete(self, request, pk):
        try:
            student = StudentProfile.objects.select_related('user').get(pk=pk)
        except StudentProfile.DoesNotExist:
            return error_response('Student not found.', status_code=404)
            
        email = student.user.email
        student.user.delete()
        
        AuditLog.objects.create(
            action='delete_student',
            performed_by=request.user,
            target_email=email
        )
        
        return success_response(message='Student account deleted successfully.')

class ManageWardensView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminWarden)
    
    def get(self, request):
        wardens = WardenProfile.objects.select_related('user').all()
        return success_response(data=WardenProfileSerializer(wardens, many=True).data)

    def post(self, request):
        serializer = ManageWardenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        
        email = data['email']
        if User.objects.filter(email=email).exists():
            return error_response('User with this email already exists.')
            
        user = User.objects.create_user(
            email=email,
            password=data.get('password'),
            first_name=data['first_name'],
            last_name=data.get('last_name', ''),
            role=UserRole.WARDEN,
            is_verified=True
        )
        if not data.get('password'):
            user.set_unusable_password()
            user.save()
        
        profile = user.warden_profile
        profile.employee_id = data['employee_id']
        profile.hostel_name = data.get('hostel_name', '')
        profile.save()
        
        AuditLog.objects.create(
            action='create_warden',
            performed_by=request.user,
            target_email=email
        )
        
        if not data.get('password'):
            from apps.accounts.services import request_password_reset
            request_password_reset(email)
            return success_response(message='Warden account created successfully. An email invite has been sent.')
        
        return success_response(message='Warden account created successfully.')

class ManageWardenDetailView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminWarden)
    
    def delete(self, request, pk):
        try:
            warden = WardenProfile.objects.select_related('user').get(pk=pk)
        except WardenProfile.DoesNotExist:
            return error_response('Warden not found.', status_code=404)
            
        if request.user.id == warden.user.id:
            return error_response('Cannot delete your own account.')
            
        email = warden.user.email
        warden.user.is_active = False
        warden.user.save()
        
        AuditLog.objects.create(
            action='delete_warden',
            performed_by=request.user,
            target_email=email
        )
        
        return success_response(message='Warden account deactivated successfully.')

class AuditLogListView(generics.ListAPIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.select_related('performed_by').all()
    
    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        serializer = self.get_serializer(qs, many=True)
        return success_response(data=serializer.data)
