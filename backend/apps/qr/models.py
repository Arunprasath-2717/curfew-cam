"""QR Pass models."""
from django.db import models
from apps.common.models import TimeStampedModel


class QRPass(TimeStampedModel):
    """QR code pass linked to an approved outpass."""
    outpass = models.OneToOneField(
        'outpass.Outpass', on_delete=models.CASCADE, related_name='qr_pass',
    )
    token = models.CharField(max_length=512, unique=True, db_index=True)
    hmac_signature = models.CharField(max_length=128)
    encrypted_payload = models.TextField(blank=True)
    qr_image = models.ImageField(upload_to='qr_codes/', blank=True, null=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    max_scans = models.PositiveIntegerField(default=1)
    scan_count = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f'QR-{self.outpass.student.register_number}'

    @property
    def is_expired(self):
        from django.utils import timezone
        return timezone.now() > self.expires_at

    @property
    def is_valid(self):
        return not self.is_expired and not self.is_used and self.scan_count < self.max_scans