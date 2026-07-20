"""Base API response utilities."""
from rest_framework.response import Response
from rest_framework import status


def success_response(data=None, message='Success', status_code=status.HTTP_200_OK, **kwargs):
    """Standard success response."""
    payload = {
        'success': True,
        'message': message,
    }
    if data is not None:
        payload['data'] = data
    payload.update(kwargs)
    return Response(payload, status=status_code)


def created_response(data=None, message='Created successfully'):
    """201 Created response."""
    return success_response(data=data, message=message, status_code=status.HTTP_201_CREATED)


def error_response(message='An error occurred', errors=None, status_code=status.HTTP_400_BAD_REQUEST):
    """Standard error response."""
    payload = {
        'success': False,
        'error': message,
    }
    if errors is not None:
        payload['errors'] = errors
    return Response(payload, status=status_code)


def paginated_response(paginator, serializer_class, queryset, request, message='Success'):
    """Paginated list response."""
    page = paginator.paginate_queryset(queryset, request)
    if page is not None:
        serializer = serializer_class(page, many=True, context={'request': request})
        paginated = paginator.get_paginated_response(serializer.data)
        return Response({
            'success': True,
            'message': message,
            'data': paginated.data,
        })
    serializer = serializer_class(queryset, many=True, context={'request': request})
    return success_response(data=serializer.data, message=message)
