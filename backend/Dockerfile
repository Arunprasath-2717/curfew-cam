FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE src.config.settings.production

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements/base.txt ./
# We could use production.txt if we had one, but base is fine
RUN pip install --upgrade pip
RUN pip install -r base.txt
RUN pip install gunicorn psycopg2-binary celery redis

# Copy project files
COPY . .

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Collect static files
# Note: In a real environment, you'd provide secret keys via build args or environment variables
# For now, we'll run this in the entrypoint script

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
