# FROM python:3.12-slim

# ENV PYTHONDONTWRITEBYTECODE=1 \
#     PYTHONUNBUFFERED=1

# WORKDIR /app
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     build-essential \
#     libpq-dev \
#     curl \
#     && rm -rf /var/lib/apt/lists/*

# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# COPY . .

# RUN useradd --create-home --shell /bin/bash app \
#     && chown -R app:app /app
# USER app

# EXPOSE 8000
# CMD sh -c "python manage.py migrate --noinput && \
#            python manage.py collectstatic --noinput  && \
#            gunicorn app.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120"


FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SUPERUSER_USERNAME=samuel \
    DJANGO_SUPERUSER_EMAIL=samuel@example.com \
    DJANGO_SUPERUSER_PASSWORD=teste

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

EXPOSE 8000

# CMD atualizado para criar o superuser automaticamente
CMD sh -c "python manage.py migrate --noinput && \
           python manage.py collectstatic --noinput && \
           python manage.py shell -c 'from django.contrib.auth import get_user_model; \
           User = get_user_model(); \
           User.objects.filter(username=\"$DJANGO_SUPERUSER_USERNAME\").exists() or \
           User.objects.create_superuser(username=\"$DJANGO_SUPERUSER_USERNAME\", email=\"$DJANGO_SUPERUSER_EMAIL\", password=\"$DJANGO_SUPERUSER_PASSWORD\")' && \
           gunicorn app.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120 --keep-alive 0"
