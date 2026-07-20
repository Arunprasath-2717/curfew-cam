"""Admin configs for outpass app."""
from django.contrib import admin
from .models import Outpass

@admin.register(Outpass)
class OutpassAdmin(admin.ModelAdmin):
    list_display = ('student', 'outpass_type', 'status', 'exit_date', 'expected_return_date', 'created_at')
    list_filter = ('status', 'outpass_type', 'exit_date')
    search_fields = ('student__register_number', 'student__user__first_name', 'destination')
    date_hierarchy = 'created_at'
    
    actions = ['approve_outpasses', 'reject_outpasses']
    
    @admin.action(description='Approve selected outpasses')
    def approve_outpasses(self, request, queryset):
        # We don't assign warden here because it's bulk, but could do request.user.warden_profile
        queryset.update(status=Outpass.Status.APPROVED)
        
    @admin.action(description='Reject selected outpasses')
    def reject_outpasses(self, request, queryset):
        queryset.update(status=Outpass.Status.REJECTED)
