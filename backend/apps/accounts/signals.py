from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.accounts.models import User, UserRole

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        if instance.role == UserRole.STUDENT:
            from apps.students.models import StudentProfile
            StudentProfile.objects.create(
                user=instance,
                register_number=f'REG-{instance.id}'[:30],
                department='Unknown',
                year=1,
                hostel_block='A-Block',
                room_number='000'
            )
        elif instance.role in [UserRole.WARDEN, UserRole.ADMIN_WARDEN]:
            from apps.wardens.models import WardenProfile
            WardenProfile.objects.create(
                user=instance,
                employee_id=f'EMP-{instance.id}'[:30],
                hostel_name='A-Block'
            )
