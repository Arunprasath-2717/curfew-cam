"""Admin configs for students app."""
from django.contrib import admin
from .models import StudentProfile, Guardian

class GuardianInline(admin.StackedInline):
    model = Guardian
    extra = 1


@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'register_number', 'department', 'year', 'hostel_block', 'is_in_hostel')
    list_filter = ('year', 'department', 'hostel_block', 'is_in_hostel')
    search_fields = ('register_number', 'user__first_name', 'user__last_name', 'user__email')
    inlines = [GuardianInline]


@admin.register(Guardian)
class GuardianAdmin(admin.ModelAdmin):
    list_display = ('name', 'student', 'relationship', 'phone', 'is_primary')
    search_fields = ('name', 'student__register_number')
    list_filter = ('is_primary', 'relationship')
