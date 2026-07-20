from django.core.management.base import BaseCommand
from apps.accounts.models import User
from apps.wardens.models import WardenProfile

class Command(BaseCommand):
    help = 'Designates a specific warden as the Main Warden by email'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email address of the warden')

    def handle(self, *args, **options):
        email = options['email']
        try:
            user = User.objects.get(email=email)
            if user.role != 'warden':
                self.stdout.write(self.style.ERROR(f'User {email} is not a warden (role: {user.role})'))
                return

            try:
                profile = user.warden_profile
                profile.is_main_warden = True
                profile.save()
                self.stdout.write(self.style.SUCCESS(f'Successfully designated {email} as the Main Warden'))
            except WardenProfile.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'User {email} does not have a WardenProfile'))

        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'User with email {email} does not exist'))
