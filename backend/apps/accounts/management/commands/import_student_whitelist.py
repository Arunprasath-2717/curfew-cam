import csv
import argparse
from django.core.management.base import BaseCommand
from apps.accounts.models import StudentWhitelist


class Command(BaseCommand):
    help = 'Import student whitelist from a CSV file.'

    def add_arguments(self, parser):
        parser.add_argument('csv_file', type=argparse.FileType('r'), help='Path to the CSV file')

    def handle(self, *args, **options):
        csv_file = options['csv_file']
        reader = csv.DictReader(csv_file)
        
        # We expect columns: name, register_number, room_number
        required_columns = {'name', 'register_number', 'room_number'}
        if not required_columns.issubset(set(reader.fieldnames or [])):
            self.stdout.write(self.style.ERROR(
                f"CSV must contain headers: {', '.join(required_columns)}"
            ))
            return

        created_count = 0
        updated_count = 0
        
        for row in reader:
            name = row['name'].strip()
            register_number = row['register_number'].strip()
            room_number = row['room_number'].strip()

            if not name or not register_number:
                self.stdout.write(self.style.WARNING(f"Skipping row with missing name or register_number: {row}"))
                continue

            # Update or create based on register_number
            obj, created = StudentWhitelist.objects.update_or_create(
                register_number=register_number,
                defaults={
                    'name': name,
                    'room_number': room_number,
                }
            )
            
            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(self.style.SUCCESS(
            f'Successfully imported whitelist. Created: {created_count}, Updated: {updated_count}'
        ))
