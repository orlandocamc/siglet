from django.contrib import admin
from django.urls import path
from core import views

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # 1. La página principal es el LOGIN
    path('', views.login_view, name='login'),
    
    # 2. La página de adentro es el INVENTARIO (Ya no 'lista_laboratorios')
    path('inventario/', views.inventario_view, name='inventario'),

    # Rutas del Carrito
    path('carrito/agregar/', views.agregar_al_carrito, name='agregar_al_carrito'),
    path('carrito/', views.ver_carrito, name='ver_carrito'),
    path('carrito/quitar/', views.quitar_del_carrito, name='quitar_del_carrito'),
    path('carrito/confirmar/', views.confirmar_solicitud, name='confirmar_solicitud'),
    path('mis-prestamos/', views.mis_prestamos, name='mis_prestamos'),
    path('logout/', views.logout_view, name='logout'),
    path('reservas/', views.reservas_view, name='reservas'),
    path('tecnico/', views.tecnico_view, name='tecnico'),
    path('reportes/', views.reportes_view, name='reportes'),
    path('reportar/<int:loan_id>/', views.reportar_incidente_view, name='reportar_incidente'),
    path('admin-hub/', views.admin_hub_view, name='admin_hub'),
    # ... tus otras rutas ...
    path('api/chat/', views.chat_ia_view, name='api_chat'),
    path('mapa/', views.mapa_interactivo, name='mapa_interactivo'),
]