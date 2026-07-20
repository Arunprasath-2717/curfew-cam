from django.core.management.base import BaseCommand
from django.conf import settings
from apps.detection.yolo_engine import engine
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Starts the YOLO detection stream processing'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting YOLO detection pipeline...'))
        
        # Start processing the stream
        # process_stream() handles the stream_url setting and fallback logic
        try:
            engine.is_running = True
            engine.process_stream()
        except KeyboardInterrupt:
            engine.is_running = False
            self.stdout.write(self.style.WARNING('Detection stream stopped.'))
        except Exception as e:
            logger.exception("Error in detection stream pipeline")
            self.stderr.write(self.style.ERROR(f'Pipeline error: {e}'))
