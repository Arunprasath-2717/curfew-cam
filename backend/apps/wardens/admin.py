"""Admin configs for wardens app."""
from django.contrib import admin
from .models import WardenProfile

@admin.register(WardenProfile)
class WardenProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'employee_id', 'hostel_name', 'designation', 'is_chief_warden')
    list_filter = ('hostel_name', 'is_chief_warden', 'designation')
    search_fields = ('employee_id', 'user__first_name', 'user__last_name', 'user__email')
