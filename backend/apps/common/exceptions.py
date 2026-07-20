"""Global exception handler for DRF."""
import logging
from rest_framework.views import exception_handler
from rest_framework.exceptions import (
    AuthenticationFailed, NotAuthenticated, PermissionDenied,
    ValidationError, NotFound,
)
from django.http import Http404
from django.core.exceptions import ObjectDoesNotExist

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """Custom exception handler that wraps all errors in standard format."""
    response = exception_handler(exc, context)

    if response is None:
        # Handle non-DRF exceptions
        logger.exception(f'Unhandled exception: {exc}', exc_info=exc)
        from rest_framework.response import Response
        from rest_framework import status
        return Response(
            {
                'success': False,
                'error': 'An unexpected error occurred.',
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    response.data = {
        'success': False,
        'error': _get_error_message(exc, response.data),
    }

    return response


def _get_error_message(exc, data=None):
    """Get human-readable error message from exception."""
    if isinstance(exc, ValidationError):
        if isinstance(data, dict):
            flattened = []
            for key, value in data.items():
                if isinstance(value, list):
                    flattened.extend(f'{key}: {item}' for item in value)
                else:
                    flattened.append(f'{key}: {value}')
            if flattened:
                return '; '.join(flattened)
        if isinstance(data, list):
            return '; '.join(str(item) for item in data)
        return 'Validation error'
    elif isinstance(exc, (AuthenticationFailed, NotAuthenticated)):
        return 'Authentication failed'
    elif isinstance(exc, PermissionDenied):
        return 'Permission denied'
    elif isinstance(exc, (NotFound, Http404, ObjectDoesNotExist)):
        return 'Resource not found'
    return str(exc.detail) if hasattr(exc, 'detail') else 'An error occurred'
