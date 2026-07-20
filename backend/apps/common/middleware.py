"""Request logging middleware."""
import logging
import time

logger = logging.getLogger('apps.common.middleware')


class RequestLoggingMiddleware:
    """Log all API requests with timing."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.monotonic()
        response = self.get_response(request)
        duration = time.monotonic() - start

        if request.path.startswith('/api/'):
            logger.info(
                '%s %s %s %.3fs',
                request.method,
                request.path,
                response.status_code,
                duration,
            )

        return response
