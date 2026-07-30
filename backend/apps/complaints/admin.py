from django.contrib import admin
from .models import Complaint


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('title', 'student', 'category', 'priority', 'status', 'is_anonymous', 'created_at')
    list_filter = ('status', 'category', 'priority', 'is_anonymous')
    search_fields = ('title', 'description', 'student__email')
    readonly_fields = ('id', 'created_at', 'updated_at')
