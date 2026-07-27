"""Production settings for CurfewCam."""
from .base import *  # noqa: F401,F403
import dj_database_url
import os

DEBUG = False

# Must be set in the Render environment variables
SECRET_KEY = env('SECRET_KEY')
QR_HMAC_SECRET = env('QR_HMAC_SECRET')
REDIS_URL = env('REDIS_URL')
CELERY_BROKER_URL = env('CELERY_BROKER_URL')
CELERY_RESULT_BACKEND = env('CELERY_RESULT_BACKEND')
RESEND_API_KEY = env('RESEND_API_KEY')

# Allow Render domain and any other hosts passed via env
ALLOWED_HOSTS = env('ALLOWED_HOSTS', default='.onrender.com', cast=Csv())

# Render's managed Postgres
DATABASES = {
    'default': dj_database_url.config(
        default=env('DATABASE_URL'),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# Static files (Whitenoise)
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Insert Whitenoise middleware right after SecurityMiddleware
try:
    _security_idx = MIDDLEWARE.index('django.middleware.security.SecurityMiddleware')
    MIDDLEWARE.insert(_security_idx + 1, 'whitenoise.middleware.WhiteNoiseMiddleware')
except ValueError:
    MIDDLEWARE.insert(0, 'whitenoise.middleware.WhiteNoiseMiddleware')

# Security / CORS
CORS_ALLOWED_ORIGINS = env('CORS_ALLOWED_ORIGINS', default='https://curfewcam.onrender.com', cast=Csv())
CSRF_TRUSTED_ORIGINS = env('CSRF_TRUSTED_ORIGINS', default='https://curfewcam.onrender.com', cast=Csv())
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')