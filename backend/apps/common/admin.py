"""Admin configs for common app."""
from django.contrib import admin
from .models import MovementLog

@admin.register(MovementLog)
class MovementLogAdmin(admin.ModelAdmin):
    list_display = ('student', 'action', 'gate', 'created_at')
    list_filter = ('action', 'gate', 'created_at')
    search_fields = ('student__user__first_name', 'student__user__last_name', 'student__register_number')
    date_hierarchy = 'created_at'
