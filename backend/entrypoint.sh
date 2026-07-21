#!/bin/bash

# Wait for database to be ready
echo "Waiting for postgres..."
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
  sleep 0.1
done
echo "PostgreSQL started"

# Wait for redis
echo "Waiting for redis..."
while ! nc -z $REDIS_HOST $REDIS_PORT; do
  sleep 0.1
done
echo "Redis started"

# Apply migrations
echo "Applying database migrations..."
python manage.py migrate --noinput

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

if [ "$#" -eq 0 ]; then
    echo "Starting Gunicorn server..."
    exec gunicorn src.config.wsgi:application --bind 0.0.0.0:8000 --workers 3
else
    exec "$@"
fi
