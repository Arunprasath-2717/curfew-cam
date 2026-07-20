"""Admin configs for qr app."""
from django.contrib import admin
from .models import QRPass

@admin.register(QRPass)
class QRPassAdmin(admin.ModelAdmin):
    list_display = ('outpass', 'expires_at', 'is_used', 'scan_count', 'max_scans')
    list_filter = ('is_used', 'expires_at')
    search_fields = ('outpass__student__register_number',)
    readonly_fields = ('token', 'hmac_signature', 'encrypted_payload')
