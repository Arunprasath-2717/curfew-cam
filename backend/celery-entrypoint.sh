#!/bin/bash

# Wait for redis
echo "Waiting for redis..."
while ! nc -z $REDIS_HOST $REDIS_PORT; do
  sleep 0.1
done
echo "Redis started"

echo "Starting Celery worker..."
exec celery -A src.config worker -l info
