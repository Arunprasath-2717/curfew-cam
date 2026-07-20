"""Admin configs for camera app."""
from django.contrib import admin
from .models import Camera

@admin.register(Camera)
class CameraAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'ip_address', 'status', 'is_active', 'last_health_check')
    list_filter = ('status', 'is_active', 'assigned_gate', 'assigned_hostel')
    search_fields = ('name', 'ip_address', 'location')
