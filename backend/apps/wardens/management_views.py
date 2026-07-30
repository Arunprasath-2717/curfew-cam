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
            password=data['password'],
            first_name=data['first_name'],
            last_name=data.get('last_name', ''),
            phone_number=data.get('phone_number', ''),
            role=UserRole.WARDEN,
            is_verified=True
        )
        
        profile = user.warden_profile
        profile.employee_id = data['employee_id']
        profile.hostel_name = data.get('hostel_name', '')
        profile.assigned_year = data.get('assigned_year')
        profile.is_chief_warden = data.get('is_chief_warden', False)
        profile.save()
        
        AuditLog.objects.create(
            action='create_warden',
            performed_by=request.user,
            target_email=email
        )
        
        return success_response(message='Warden account created successfully.')

class ManageWardenDetailView(APIView):
    permission_classes = (permissions.IsAuthenticated, IsAdminWarden)
    
    def patch(self, request, pk):
        try:
            warden = WardenProfile.objects.select_related('user').get(pk=pk)
        except WardenProfile.DoesNotExist:
            return error_response('Warden not found.', status_code=404)
            
        data = request.data
        if 'hostel_name' in data:
            warden.hostel_name = data['hostel_name']
        if 'assigned_year' in data:
            warden.assigned_year = data['assigned_year']
        if 'is_chief_warden' in data:
            warden.is_chief_warden = data['is_chief_warden']
            
        warden.save()
        return success_response(message='Warden profile updated successfully.')

    def delete(self, request, pk):
        try:
            warden = WardenProfile.objects.select_related('user').get(pk=pk)
        except WardenProfile.DoesNotExist:
            return error_response('Warden not found.', status_code=404)
            
        if request.user.id == warden.user.id:
            return error_response('Cannot delete your own account.')
            
        from apps.outpass.models import Outpass
        pending_count = Outpass.objects.filter(
            status=Outpass.Status.PENDING,
            student__hostel_block=warden.hostel_name
        ).count()
        if pending_count > 0:
            return error_response(f'Cannot delete warden: they have {pending_count} pending request(s) assigned to their hostel ({warden.hostel_name}).')
            
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

class RunPromotionView(APIView):
    """Manually trigger yearly promotion."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request):
        from apps.students.tasks import run_yearly_promotion
        counts = run_yearly_promotion()
        return success_response(
            data=counts,
            message='Promotion cycle completed successfully.'
        )

class BulkImportStudentsView(APIView):
    """Bulk import students via CSV/Excel file."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request):
        import csv
        import io

        file_data = None
        if 'file' in request.FILES:
            uploaded_file = request.FILES['file']
            file_data = uploaded_file.read().decode('utf-8-sig')
        elif 'csv_content' in request.data:
            file_data = request.data['csv_content']

        if not file_data:
            return error_response('Please upload a CSV file or provide csv_content.')

        try:
            io_string = io.StringIO(file_data)
            reader = csv.DictReader(io_string)

            created_count = 0
            updated_count = 0
            skipped_count = 0
            errors = []

            for row_idx, row in enumerate(reader, start=2):
                # Clean headers and values
                clean_row = {k.strip().lower(): v.strip() for k, v in row.items() if k}
                
                email = clean_row.get('email')
                reg_no = clean_row.get('register_number') or clean_row.get('reg_no') or clean_row.get('roll_no')
                first_name = clean_row.get('first_name') or clean_row.get('name')
                last_name = clean_row.get('last_name', '')
                dept = clean_row.get('department') or clean_row.get('dept', 'General')
                year_str = clean_row.get('year', '1')
                hostel = clean_row.get('hostel_block') or clean_row.get('hostel') or clean_row.get('block', 'TBD')
                room = clean_row.get('room_number') or clean_row.get('room', 'TBD')
                password = clean_row.get('password') or 'Student@123'

                if not email or not reg_no or not first_name:
                    errors.append(f'Row {row_idx}: Missing required fields (email, register_number, first_name)')
                    skipped_count += 1
                    continue

                try:
                    year_val = int(year_str) if year_str.isdigit() else 1
                except ValueError:
                    year_val = 1

                # Check if user already exists
                user = User.objects.filter(email=email).first()
                if not user:
                    # Check if student with reg_no exists
                    profile_by_reg = StudentProfile.objects.filter(register_number=reg_no).first()
                    if profile_by_reg:
                        user = profile_by_reg.user

                if not user:
                    user = User.objects.create_user(
                        email=email,
                        password=password,
                        first_name=first_name,
                        last_name=last_name,
                        role=UserRole.STUDENT,
                        is_verified=True,
                    )
                    profile = getattr(user, 'student_profile', None)
                    if not profile:
                        profile = StudentProfile.objects.create(
                            user=user,
                            register_number=reg_no,
                            department=dept,
                            year=year_val,
                            hostel_block=hostel,
                            room_number=room,
                        )
                    else:
                        profile.register_number = reg_no
                        profile.department = dept
                        profile.year = year_val
                        profile.hostel_block = hostel
                        profile.room_number = room
                        profile.save()
                    created_count += 1
                else:
                    # Update existing profile
                    user.first_name = first_name
                    if last_name:
                        user.last_name = last_name
                    user.save()

                    profile, _ = StudentProfile.objects.get_or_create(user=user, defaults={
                        'register_number': reg_no,
                        'department': dept,
                        'year': year_val,
                        'hostel_block': hostel,
                        'room_number': room,
                    })
                    profile.register_number = reg_no
                    profile.department = dept
                    profile.year = year_val
                    profile.hostel_block = hostel
                    profile.room_number = room
                    profile.save()
                    updated_count += 1

            AuditLog.objects.create(
                action='bulk_import_students',
                performed_by=request.user,
                target_email=f'Imported {created_count} created, {updated_count} updated',
            )

            return success_response(
                data={
                    'created': created_count,
                    'updated': updated_count,
                    'skipped': skipped_count,
                    'errors': errors,
                },
                message=f'Bulk import completed: {created_count} created, {updated_count} updated.',
            )

        except Exception as e:
            return error_response(f'Failed to parse CSV file: {str(e)}')


class DeletePassedOutStudentsView(APIView):
    """Delete / archive passed out students (4th year / inactive)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request):
        graduates = StudentProfile.objects.filter(year__gte=4)
        deleted_count = 0

        for student in graduates:
            email = student.user.email
            student.user.delete()
            deleted_count += 1

            AuditLog.objects.create(
                action='delete_passed_out',
                performed_by=request.user,
                target_email=email,
            )

        return success_response(
            data={'deleted_count': deleted_count},
            message=f'Deleted {deleted_count} passed-out student accounts.',
        )



