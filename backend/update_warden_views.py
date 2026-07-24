import re

with open('apps/wardens/views.py', 'r') as f:
    content = f.read()

# Replace block 1: WardenDashboardView
old_block1 = """        if hostel and request.user.role != UserRole.ADMIN_WARDEN:
            students_qs = students_qs.filter(hostel_block=hostel)
            outpass_qs = outpass_qs.filter(student__hostel_block=hostel)"""
new_block1 = """        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if hostel:
                students_qs = students_qs.filter(hostel_block=hostel)
                outpass_qs = outpass_qs.filter(student__hostel_block=hostel)
            if warden_profile.assigned_year:
                students_qs = students_qs.filter(year=warden_profile.assigned_year)
                outpass_qs = outpass_qs.filter(student__year=warden_profile.assigned_year)"""
content = content.replace(old_block1, new_block1)

# Replace block 2: PendingOutpassListView, LateStudentsView, WardenOutpassHistoryView
old_block2 = """        if warden_profile and self.request.user.role != UserRole.ADMIN_WARDEN:
            qs = qs.filter(student__hostel_block=warden_profile.hostel_name)"""
new_block2 = """        if warden_profile and not warden_profile.is_chief_warden and self.request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)"""
content = content.replace(old_block2, new_block2)

# Replace block 3: WardenReportsView
old_block3 = """        if warden_profile and request.user.role != UserRole.ADMIN_WARDEN:
            outpass_qs = outpass_qs.filter(student__hostel_block=warden_profile.hostel_name)"""
new_block3 = """        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                outpass_qs = outpass_qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                outpass_qs = outpass_qs.filter(student__year=warden_profile.assigned_year)"""
content = content.replace(old_block3, new_block3)

# Replace block 4: OutsideStudentsView
old_block4 = """        if warden_profile and self.request.user.role != UserRole.ADMIN_WARDEN:
            qs = qs.filter(student__hostel_block=warden_profile.hostel_name)"""
new_block4 = """        if warden_profile and not warden_profile.is_chief_warden and self.request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)"""
content = content.replace(old_block4, new_block4)

with open('apps/wardens/views.py', 'w') as f:
    f.write(content)
