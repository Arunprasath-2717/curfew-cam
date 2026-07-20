"""Admin configs for watchmen app."""
from django.contrib import admin
from .models import WatchmanProfile, ShiftLog, GateScan

@admin.register(WatchmanProfile)
class WatchmanProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'employee_id', 'assigned_gate', 'is_on_duty')
    list_filter = ('assigned_gate', 'is_on_duty')
    search_fields = ('employee_id', 'user__first_name', 'user__last_name')


@admin.register(ShiftLog)
class ShiftLogAdmin(admin.ModelAdmin):
    list_display = ('watchman', 'gate', 'shift_start', 'shift_end')
    list_filter = ('gate', 'shift_start')
    date_hierarchy = 'shift_start'


@admin.register(GateScan)
class GateScanAdmin(admin.ModelAdmin):
    list_display = ('qr_pass', 'watchman', 'scan_type', 'gate', 'created_at')
    list_filter = ('scan_type', 'gate', 'created_at')
    search_fields = ('qr_pass__token',)
    date_hierarchy = 'created_at'
