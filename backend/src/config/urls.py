"""CurfewCam URL Configuration with API versioning."""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)


def health_check(request):
    """Health check endpoint."""
    return JsonResponse({
        'status': 'healthy',
        'service': 'curfewcam-api',
        'version': '1.0.0',
    })


# API v1 URL patterns
api_v1_patterns = [
    path('auth/', include('apps.accounts.urls')),
    path('students/', include('apps.students.urls')),
    path('outpass/', include('apps.outpass.urls')),
    path('wardens/', include('apps.wardens.urls')),
    path('watchmen/', include('apps.watchmen.urls')),
    path('qr/', include('apps.qr.urls')),
    path('cameras/', include('apps.camera.urls')),
    path('detection/', include('apps.detection.urls')),
    path('notifications/', include('apps.notifications.urls')),
    path('complaints/', include('apps.complaints.urls')),
]

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # Health
    path('api/health/', health_check, name='health-check'),

    # API v1
    path('api/v1/', include((api_v1_patterns, 'api-v1'))),

    # Swagger / OpenAPI
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]

# Serve static/media in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)