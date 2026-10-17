"""
Django settings for the app project.

Every environment-specific value comes from environment variables. In AWS they
are set by the ECS task definition (secrets via Secrets Manager); locally they
come from .env (see .env.example) or docker-compose.yml.
"""

import os
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def env_list(name, default=""):
    return [value.strip() for value in os.getenv(name, default).split(",") if value.strip()]


DEBUG = os.getenv("DEBUG", "false").lower() == "true"

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    if not DEBUG:
        raise ImproperlyConfigured("SECRET_KEY must be set when DEBUG is false")
    SECRET_KEY = "django-insecure-local-development-only"

ALLOWED_HOSTS = env_list("ALLOWED_HOSTS", "localhost,127.0.0.1")
CSRF_TRUSTED_ORIGINS = env_list("CSRF_TRUSTED_ORIGINS")


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "core",
]

MIDDLEWARE = [
    "app.middleware.HealthCheckMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "app.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "app.wsgi.application"


# Database

if os.getenv("DATABASE_URL"):
    import dj_database_url

    DATABASES = {"default": dj_database_url.parse(os.environ["DATABASE_URL"])}
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "HOST": os.getenv("DB_HOST", "localhost"),
            "PORT": os.getenv("DB_PORT", "5432"),
            "NAME": os.getenv("DB_NAME", "app"),
            "USER": os.getenv("DB_USER", "app"),
            "PASSWORD": os.getenv("DB_PASSWORD", ""),
            # Reuse connections between requests; health checks detect
            # connections broken by an RDS failover.
            "CONN_MAX_AGE": 60,
            "CONN_HEALTH_CHECKS": True,
        }
    }


# Password validation

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]


# Internationalization

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True


# Static files
#
# In AWS, `collectstatic` (run by the release task) uploads the files to S3
# under static/, and CloudFront serves them from the application domain at
# /static/* — same origin, no CORS, cached at the edge. The manifest storage
# adds a content hash to every file name (app.3f2a1b.js), so a release never
# serves stale cached assets and no CloudFront invalidation is needed.

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}

if os.getenv("USE_S3", "false").lower() == "true":
    STORAGES["staticfiles"] = {
        "BACKEND": "storages.backends.s3.S3ManifestStaticStorage",
        "OPTIONS": {
            "bucket_name": os.environ["AWS_STORAGE_BUCKET_NAME"],
            "region_name": os.getenv("AWS_REGION", "us-east-1"),
            "location": "static",
            "custom_domain": os.getenv("STATIC_CUSTOM_DOMAIN"),
            "querystring_auth": False,
        },
    }

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# Security (production only)
#
# TLS terminates at CloudFront and again at the ALB, which sets
# X-Forwarded-Proto. Health checks never get here (HealthCheckMiddleware).

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

# HSTS preload is a commitment for the whole parent domain, not a per-app setting
SILENCED_SYSTEM_CHECKS = ["security.W021"]


# Logging: everything to stdout, collected by the awslogs driver

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "simple": {"format": "{levelname} {name} {message}", "style": "{"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "simple"},
    },
    "root": {"handlers": ["console"], "level": os.getenv("LOG_LEVEL", "INFO")},
}
