"""Development settings for CurfewCam."""
from .base import *  # noqa: F401,F403

DEBUG = True

# Local development uses a persistent SQLite file instead of Postgres.
# This removes the dependency on a separately-running Postgres service/
# container, which was causing intermittent "connection refused" errors
# and confusing data-loss symptoms whenever Postgres wasn't running.
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
ALLOWED_HOSTS = ['*', '10.42.0.1']

# Console email
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
RESEND_API_KEY = env('RESEND_API_KEY', default='')

# Disable password validators in dev
AUTH_PASSWORD_VALIDATORS = []

# Celery eager mode (synchronous in dev)
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

# CORS allow all in dev
CORS_ALLOW_ALL_ORIGINS = True

# Add browsable API renderer in dev
REST_FRAMEWORK['DEFAULT_RENDERER_CLASSES'] = [  # noqa: F405
    'rest_framework.renderers.JSONRenderer',
    'rest_framework.renderers.BrowsableAPIRenderer',
]

# Use local memory cache in dev
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'curfewcam-dev-cache',
    }
}