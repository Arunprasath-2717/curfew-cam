import re

with open('apps/watchmen/views.py', 'r') as f:
    content = f.read()

# Replace block 1: ActivePassesView
old_block1 = """    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user').order_by('-actual_exit_time')
        return success_response(data=OutpassSerializer(qs, many=True).data)"""
new_block1 = """    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user').order_by('-actual_exit_time')
        
        from apps.accounts.models import UserRole
        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
                
        return success_response(data=OutpassSerializer(qs, many=True).data)"""
content = content.replace(old_block1, new_block1)

# Replace block 2: OverdueStudentsView
old_block2 = """    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user')
        late = [op for op in qs if op.is_late]
        return success_response(data=OutpassSerializer(late, many=True).data)"""
new_block2 = """    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user')
        
        from apps.accounts.models import UserRole
        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
                
        late = [op for op in qs if op.is_late]
        return success_response(data=OutpassSerializer(late, many=True).data)"""
content = content.replace(old_block2, new_block2)

with open('apps/watchmen/views.py', 'w') as f:
    f.write(content)
