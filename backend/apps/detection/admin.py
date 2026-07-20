"""Admin configs for detection app."""
from django.contrib import admin
from .models import Detection, Alert

@admin.register(Detection)
class DetectionAdmin(admin.ModelAdmin):
    list_display = ('detection_type', 'camera', 'confidence', 'matched_student', 'created_at')
    list_filter = ('detection_type', 'camera', 'created_at')
    search_fields = ('matched_student__register_number', 'camera__name')
    date_hierarchy = 'created_at'


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ('title', 'level', 'status', 'created_at', 'acknowledged_by')
    list_filter = ('level', 'status', 'created_at')
    search_fields = ('title', 'message')
    date_hierarchy = 'created_at'
