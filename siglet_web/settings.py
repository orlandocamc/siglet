"""
Django settings for siglet_web project.
MODIFIED FOR RAILWAY DEPLOYMENT
"""
import os
from pathlib import Path
import dj_database_url # Herramienta para leer la DB de Railway

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# =========================================================
# CONFIGURACIÓN DE SEGURIDAD (PRODUCCIÓN VS LOCAL)
# =========================================================

# Si existe la variable en Railway, la usa. Si no, usa la insegura para local.
SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-only-insecure-key-change-me')

# En Railway definiremos la variable DEBUG = False. En local será True.
DEBUG = os.environ.get('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = ['*']

# IMPORTANTE: Esto permite que los formularios funcionen en Railway con HTTPS
CSRF_TRUSTED_ORIGINS = ['https://*.railway.app', 'https://*.up.railway.app']

# Application definition
INSTALLED_APPS = [
    'jazzmin', # Panel administrativo bonito
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles', # WhiteNoise necesita esto
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    "whitenoise.middleware.WhiteNoiseMiddleware", # <--- CRÍTICO: Debe ir aquí para servir CSS en Railway
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'siglet_web.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                # Tus context processors personalizados:
                'core.context_processors.carrito_contador',
                'core.context_processors.roles_disponibles',
            ],
        },
    },
]

WSGI_APPLICATION = 'siglet_web.wsgi.application'

# =========================================================
# BASE DE DATOS (LÓGICA HÍBRIDA)
# =========================================================

# 1. Configuración por defecto (Tu PC Local)
# Si estás en casa y quieres trabajar, asegúrate de tener un MySQL local corriendo
# con estos datos, o cámbialos por los de tu MySQL local.
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'SIGLETdB',       # Base de datos local
        'USER': 'root',           # Usuario local
        'PASSWORD': '',           # Password local
        'HOST': 'localhost',
        'PORT': '3306',
    }
}

# 2. Configuración de Producción (Railway)
# Si dj_database_url detecta la variable DATABASE_URL (que configuramos en Railway),
# reemplaza automáticamente la configuración local.
db_from_env = dj_database_url.config(conn_max_age=500)
if db_from_env:
    DATABASES['default'] = db_from_env

# =========================================================


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    { 'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator', },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# =========================================================
# ARCHIVOS ESTÁTICOS (WHITENOISE)
# =========================================================
STATIC_URL = 'static/'

# Carpetas donde buscas estáticos en desarrollo
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'core', 'static'),
]

# Carpeta donde WhiteNoise recolectará todo para producción
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Motor de almacenamiento para comprimir y servir archivos eficientemente
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"


DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ==========================================
# CONFIGURACIÓN DE JAZZMIN (TEMA IBERO)
# ==========================================
JAZZMIN_SETTINGS = {
    "site_title": "SIGLET Admin",
    "site_header": "SIGLET",
    "site_brand": "SIGLET Ibero",
    "welcome_sign": "Bienvenido al Panel de Control SIGLET",
    "copyright": "Universidad Iberoamericana",
    "search_model": ["core.User", "core.Equipment"],
    "topmenu_links": [
        {"name": "Inicio", "url": "admin:index", "permissions": ["auth.view_user"]},
        {"name": "🔙 Volver al Centro de Mando", "url": "/admin-hub/", "new_window": False},
        {"name": "👁️ Ver Sitio Público", "url": "/", "new_window": True},
    ],
    "show_sidebar": True,
    "navigation_expanded": True,
    "icons": {
        "auth": "fas fa-users-cog",
        "core.User": "fas fa-user",
        "core.Lab": "fas fa-flask",
        "core.Equipment": "fas fa-microscope",
        "core.Loan": "fas fa-exchange-alt",
        "core.Incident": "fas fa-exclamation-triangle",
        "core.LabReservation": "fas fa-calendar-check",
    },
}

JAZZMIN_UI_TWEAKS = {
    "navbar_small_text": False,
    "footer_small_text": False,
    "body_small_text": False,
    "brand_small_text": False,
    "brand_colour": "danger",
    "accent": "accent-danger",
    "navbar": "navbar-danger navbar-dark",
    "no_navbar_border": False,
    "navbar_fixed": False,
    "layout_boxed": False,
    "footer_fixed": False,
    "sidebar_fixed": True,
    "sidebar": "sidebar-light-danger",
    "sidebar_nav_small_text": False,
    "theme": "flatly",
    "button_classes": {
        "primary": "btn-danger",
        "secondary": "btn-outline-danger",
        "info": "btn-info",
        "warning": "btn-warning",
        "danger": "btn-danger",
        "success": "btn-success"
    }
}