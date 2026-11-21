import os
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login as django_login
from django.contrib.auth import logout as django_logout # Renombramos para no confundir
from .models import User, Lab, Equipment, ReservationReason
from collections import defaultdict
from django.contrib import messages
from django.db import connection
from django.utils import timezone
from django.db.models import Q
import datetime
from django.http import JsonResponse
from openai import OpenAI
import json



# ==========================================
# 1. AUTENTICACIÓN Y LOGOUT
# ==========================================

def login_view(request):
    error_message = None

    if request.method == 'POST':
        usuario_form = request.POST.get('username')
        password_form = request.POST.get('password')

        print(f"---- INTENTO DE LOGIN AUTOMÁTICO: {usuario_form} ----")

        # A) Intentar como ADMIN DE DJANGO
        user = authenticate(request, username=usuario_form, password=password_form)
        if user is not None:
            django_login(request, user)
            print("--> Rol detectado: ADMIN DE SISTEMA (Django)")
            return redirect('admin_hub') # <--- Ahora va al Centro de Mando

        # B) Intentar como USUARIO DE AWS (Core)
        try:
            usuario_encontrado = User.objects.get(name=usuario_form, password=password_form)
            
            # --- PARCHE DE SEGURIDAD CRÍTICO ---
            # Si había una sesión de Admin activa, la matamos aquí mismo.
            if request.user.is_authenticated:
                django_logout(request) 
            # -----------------------------------

            # Consultar roles
            roles_detectados = []
            with connection.cursor() as cursor:
                # ... (resto del código igual) ...
                cursor.execute("""
                    SELECT r.name FROM role r 
                    JOIN user_role ur ON ur.role_id = r.id 
                    WHERE ur.user_id = %s
                """, [usuario_encontrado.id])
                roles_detectados = [row[0] for row in cursor.fetchall()]
            
            print(f"--> Usuario encontrado. Roles en DB: {roles_detectados}")

            # Guardar sesión
            request.session['usuario_id'] = usuario_encontrado.id
            request.session['usuario_nombre'] = usuario_encontrado.name
            request.session['roles_usuario'] = roles_detectados # Guardamos todos los roles

            # Semáforo de Redirección (Prioridad)
            if 'professor' in roles_detectados:
                request.session['usuario_rol'] = 'professor'  # <--- ¡FALTABA ESTA!
                return redirect('reservas')
            
            elif 'labtech' in roles_detectados:
                request.session['usuario_rol'] = 'labtech'    # <--- ¡FALTABA ESTA!
                return redirect('tecnico')
            
            elif 'student' in roles_detectados:
                request.session['usuario_rol'] = 'student'    # <--- ¡FALTABA ESTA!
                return redirect('inventario')
            else:
                error_message = "Usuario sin rol asignado. Contacta a soporte."

        except User.DoesNotExist:
            print("--> FALLO: No se encontró en Django Admin ni en AWS Core.")
            error_message = "Usuario o contraseña incorrectos."
        except Exception as e:
            print(f"--> ERROR CRÍTICO: {e}")
            error_message = "Error del sistema."

    return render(request, 'index.html', {'error': error_message})

def logout_view(request):
    request.session.flush()
    return redirect('login')

# ==========================================
# 2. MÓDULO ALUMNO (Inventario y Préstamos)
# ==========================================

def inventario_view(request):
    if not request.session.get('usuario_id'): return redirect('login')

    # SEGURIDAD MULTI-ROL
    # Asumimos que Student es el rol base, pero igual validamos y cambiamos
    roles_usuario = request.session.get('roles_usuario', [])
    if 'student' in roles_usuario:
        request.session['usuario_rol'] = 'student'

    laboratorios = Lab.objects.all()
    
    # Filtros
    lab_id_filtro = request.GET.get('lab_id') 
    query = request.GET.get('q')

    # --- CAMBIO APLICADO AQUÍ ---
    # Agregamos .filter(equipment_status_id=1) para traer SOLO lo disponible
    # 2. Base del Queryset (TRAEMOS TODO, ya no filtramos por status 1)
    equipos_qs = Equipment.objects.select_related('equipment_type', 'lab', 'equipment_status')

    if lab_id_filtro:
        equipos_qs = equipos_qs.filter(lab_id=lab_id_filtro)

    if query:
        equipos_qs = equipos_qs.filter(
            Q(inventory_tag__icontains=query) |
            Q(serial_number__icontains=query) |
            Q(equipment_type__name__icontains=query)
        )
    
    equipos = equipos_qs.all()

    return render(request, 'inventario.html', {
        'labs': laboratorios,
        'equipos': equipos,
        'usuario_nombre': request.session.get('usuario_nombre'),
        'lab_seleccionado': int(lab_id_filtro) if lab_id_filtro else None
    })

def mis_prestamos(request):
    if not request.session.get('usuario_id'): return redirect('login')
    
    usuario_id = request.session.get('usuario_id')
    lista_prestamos = []

    with connection.cursor() as cursor:
        cursor.callproc('sp_get_user_loans', [usuario_id])
        resultados = cursor.fetchall()
        
        for row in resultados:
            try:
                equipo = Equipment.objects.select_related('equipment_type').get(id=row[1])
                nombre_equipo = equipo.equipment_type.name
                serie_equipo = equipo.serial_number
            except:
                nombre_equipo = "Equipo Desconocido"; serie_equipo = "---"

            lista_prestamos.append({
                'id': row[0], 'equipo': nombre_equipo, 'serie': serie_equipo,
                'fecha_solicitud': row[5], 'fecha_entrega': row[6],
                'estado': row[8], 'comentarios': row[9]
            })

    return render(request, 'prestamos.html', {
        'prestamos': lista_prestamos,
        'usuario_nombre': request.session.get('usuario_nombre')
    })

def reportar_incidente_view(request, loan_id):
    if not request.session.get('usuario_id'): return redirect('login')
    usuario_id = request.session.get('usuario_id')

    # Obtener datos básicos
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT e.inventory_tag, et.name, e.id, e.lab_id 
            FROM loan l 
            JOIN equipment e ON l.equipment_id = e.id 
            JOIN equipment_type et ON e.equipment_type_id = et.id
            WHERE l.id = %s
        """, [loan_id])
        equipo_data = cursor.fetchone()

    if request.method == 'POST':
        tipo_id = request.POST.get('tipo_id')
        severidad_id = request.POST.get('severidad_id')
        descripcion = request.POST.get('descripcion')

        try:
            with connection.cursor() as cursor:
                cursor.callproc('sp_create_incident', [
                    equipo_data[2], equipo_data[3], usuario_id, loan_id,
                    tipo_id, severidad_id, descripcion
                ])
            messages.success(request, "Reporte de incidencia enviado correctamente.")
            return redirect('mis_prestamos')
        except Exception as e:
            messages.error(request, f"Error al reportar: {e}")

    # Cargar catálogos
    tipos = []; severidades = []
    with connection.cursor() as cursor:
        cursor.execute("SELECT id, name FROM incident_type"); tipos = cursor.fetchall()
        cursor.execute("SELECT id, name FROM severity"); severidades = cursor.fetchall()

    return render(request, 'reportar_incidente.html', {
        'equipo_nombre': equipo_data[1], 'equipo_tag': equipo_data[0],
        'tipos': tipos, 'severidades': severidades,
        'usuario_nombre': request.session.get('usuario_nombre')
    })

# ==========================================
# 3. MÓDULO CARRITO
# ==========================================

def agregar_al_carrito(request):
    if request.method == 'POST':
        equipo_id = request.POST.get('equipo_id')
        carrito = request.session.get('carrito', [])
        if equipo_id not in carrito:
            carrito.append(equipo_id)
            request.session['carrito'] = carrito
            messages.success(request, "Equipo agregado al carrito.")
    return redirect('inventario')

def ver_carrito(request):
    if not request.session.get('usuario_id'): return redirect('login')
    carrito_ids = request.session.get('carrito', [])
    equipos_en_carrito = Equipment.objects.filter(id__in=carrito_ids).select_related('equipment_type', 'lab')
    
    return render(request, 'solicitud.html', {
        'items_carrito': equipos_en_carrito, 'carrito_count': len(carrito_ids),
        'usuario_nombre': request.session.get('usuario_nombre')
    })

def quitar_del_carrito(request):
    if request.method == 'POST':
        equipo_id = request.POST.get('equipo_id')
        carrito = request.session.get('carrito', [])
        if equipo_id in carrito:
            carrito.remove(equipo_id)
            request.session['carrito'] = carrito
    return redirect('ver_carrito')

def confirmar_solicitud(request):
    if request.method == 'POST':
        usuario_id = request.session.get('usuario_id')
        carrito_ids = request.session.get('carrito', [])
        fecha_entrega = request.POST.get('fecha_entrega')
        
        if not carrito_ids: return redirect('inventario')

        # --- VALIDACIÓN DE FECHA (ANTIRROBO DE TIEMPO) ---
        try:
            fecha_obj = datetime.datetime.strptime(fecha_entrega, '%Y-%m-%dT%H:%M')
            if timezone.is_naive(fecha_obj):
                fecha_obj = timezone.make_aware(fecha_obj)
            
            if fecha_obj < timezone.now():
                messages.error(request, "❌ Error: No puedes seleccionar una fecha en el pasado.")
                return redirect('ver_carrito')
        except ValueError:
            messages.error(request, "❌ Error: Formato de fecha inválido.")
            return redirect('ver_carrito')
        # ------------------------------------------------

        try:
            with connection.cursor() as cursor:
                for equipo_id in carrito_ids:
                    cursor.callproc('sp_create_equipment_loan', [
                        equipo_id, usuario_id, usuario_id, fecha_entrega, 'Solicitud web'
                    ])
            request.session['carrito'] = []
            messages.success(request, "¡Solicitud creada exitosamente!")
            return redirect('inventario')
        except Exception as e:
            messages.error(request, f"Error al crear la solicitud: {e}")
            return redirect('ver_carrito')
    return redirect('ver_carrito')

# ==========================================
# 4. MÓDULO PROFESOR (Reservas)
# ==========================================

def reservas_view(request):
    # 1. Seguridad Básica
    if not request.session.get('usuario_id'): return redirect('login')
    
    # 2. Seguridad Multi-Rol
    roles_usuario = request.session.get('roles_usuario', [])
    if 'professor' not in roles_usuario:
        return redirect('inventario')
    
    request.session['usuario_rol'] = 'professor'
    usuario_id = request.session.get('usuario_id')

    # 3. Procesar Solicitud (POST)
    if request.method == 'POST':
        lab_id = request.POST.get('lab_id')
        reason_id = request.POST.get('reason_id')
        comment = request.POST.get('comment')
        
        # Obtenemos las cadenas crudas del HTML
        start_time_str = request.POST.get('start_time')
        end_time_str = request.POST.get('end_time')
        
        # --- VALIDACIÓN DE FECHA (EL PARCHE QUE FALTABA) ---
        try:
            # Convertimos texto a objeto fecha para comparar
            inicio_obj = datetime.datetime.strptime(start_time_str, '%Y-%m-%dT%H:%M')
            
            # Hacemos la fecha "consciente" de la zona horaria del servidor
            if timezone.is_naive(inicio_obj): 
                inicio_obj = timezone.make_aware(inicio_obj)
            
            # COMPARACIÓN: ¿La fecha elegida es menor a ahorita?
            if inicio_obj < timezone.now():
                messages.error(request, "❌ Error: No puedes reservar en una fecha pasada.")
            else:
                # SOLO SI LA FECHA ES VÁLIDA, PROCEDEMOS CON LA BD
                start_time = start_time_str.replace('T', ' ')
                end_time = end_time_str.replace('T', ' ')
                
                try:
                    with connection.cursor() as cursor:
                        # A. Verificar conflictos de horario (SP)
                        cursor.callproc('sp_get_reservation_conflicts', [lab_id, start_time, end_time])
                        conflictos = cursor.fetchall()

                        if conflictos:
                            messages.error(request, f"❌ Error: El laboratorio ya está ocupado en ese horario.")
                        else:
                            # B. Crear reserva (SP)
                            cursor.nextset()
                            cursor.callproc('sp_create_lab_reservation', [
                                lab_id, usuario_id, reason_id, start_time, end_time, comment
                            ])
                            messages.success(request, "¡Reserva creada exitosamente!")
                            
                except Exception as e:
                    messages.error(request, f"Error técnico: {e}")

        except ValueError:
            messages.error(request, "Error de formato de fecha.")

    # 4. Cargar datos para la vista (GET)
    laboratorios = Lab.objects.filter(active=True)
    razones = ReservationReason.objects.all()
    
    mis_reservas = []
    with connection.cursor() as cursor:
        cursor.callproc('sp_get_lab_reservations_by_user', [usuario_id])
        rows = cursor.fetchall()
        for row in rows:
            lab_name = "Lab ID " + str(row[1])
            try: l = Lab.objects.get(id=row[1]); lab_name = l.name
            except: pass
            mis_reservas.append({
                'lab': lab_name, 'inicio': row[4], 'fin': row[5],
                'estado': row[6], 'comentario': row[7]
            })

    return render(request, 'reservas.html', {
        'labs': laboratorios, 'razones': razones, 'reservas': mis_reservas,
        'usuario_nombre': request.session.get('usuario_nombre')
    })

# ==========================================
# 5. MÓDULO TÉCNICO (Gestión)
# ==========================================

def tecnico_view(request):

   # --- CHISMOSO DE DIAGNÓSTICO ---
    print(f"---- ENTRANDO A VISTA TÉCNICO ----")
    roles_usuario = request.session.get('roles_usuario', []) # Obtenemos la lista completa
    print(f"Roles disponibles: {roles_usuario}")
    
    # 1. SEGURIDAD HÍBRIDA MEJORADA:
    # Verificamos si 'labtech' está en la LISTA de roles, no solo si es el activo
    tiene_permiso_tecnico = 'labtech' in roles_usuario
    es_admin = request.user.is_authenticated and request.user.is_staff
    
    if not (tiene_permiso_tecnico or es_admin):
        print("--> ACCESO DENEGADO: No tienes permiso de técnico.")
        return redirect('login')

    # CAMBIO DE SOMBRERO AUTOMÁTICO
    # Si tiene permiso y entró aquí, actualizamos su rol activo a 'labtech'
    if tiene_permiso_tecnico:
        request.session['usuario_rol'] = 'labtech'
        
    # 2. IDENTIFICACIÓN PARA LOS PROCEDIMIENTOS (SPs):
    # Los SPs de Mario exigen un ID de usuario para registrar quién hizo la acción.
    usuario_id = request.session.get('usuario_id')
    
    # Si es el Admin y entró directo desde el Hub (sin login de alumno), 
    # no tiene ID en la sesión. Usamos el ID 1 (Admin Principal) por defecto.
    if not usuario_id and es_admin:
        usuario_id = 1 

    # Determinar qué pestaña ver (Por defecto: pendientes)
    tab_actual = request.GET.get('tab', 'pendientes')

    # --- ACCIONES (POST) ---
    if request.method == 'POST':
        accion = request.POST.get('accion')
        
        # A) DEVOLVER EQUIPO
        if accion == 'devolver':
            loan_id = request.POST.get('loan_id')
            remarks = request.POST.get('remarks') or "Devolución normal"
            ahora = timezone.now().strftime('%Y-%m-%d %H:%M:%S')
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('sp_close_equipment_loan', [loan_id, ahora, usuario_id, remarks])
                messages.success(request, f"Préstamo #{loan_id} marcado como devuelto.")
            except Exception as e:
                messages.error(request, f"Error: {e}")

        # B) GESTIONAR RESERVA
        elif accion in ['aprobar_reserva', 'rechazar_reserva']:
            reserva_id = request.POST.get('reserva_id')
            nuevo_estado = 'approved' if accion == 'aprobar_reserva' else 'rejected'
            try:
                with connection.cursor() as cursor:
                    cursor.execute("UPDATE lab_reservation SET reservation_status = %s WHERE id = %s", [nuevo_estado, reserva_id])
                messages.success(request, f"Reserva #{reserva_id} actualizada.")
            except Exception as e: messages.error(request, f"Error: {e}")

        # C) CAMBIO MANUAL DE ESTATUS
        elif accion == 'cambiar_estatus_equipo':
            tag_equipo = request.POST.get('inventory_tag')
            nuevo_status_id = request.POST.get('status_id')
            try:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT id FROM equipment WHERE inventory_tag = %s", [tag_equipo])
                    res = cursor.fetchone()
                    if res:
                        cursor.execute("UPDATE equipment SET equipment_status_id = %s WHERE id = %s", [nuevo_status_id, res[0]])
                        messages.success(request, f"Equipo {tag_equipo} actualizado.")
                    else: messages.error(request, "Equipo no encontrado.")
            except Exception as e: messages.error(request, f"Error: {e}")

        return redirect(f'/tecnico/?tab={tab_actual}') # Recargar en la misma pestaña

    # --- CARGA DE DATOS (GET) ---
    prestamos_activos = []
    historial_completo = []
    incidentes_reportados = []
    reservas_pendientes = [] # Siempre cargamos reservas para el contador o vista rápida

    with connection.cursor() as cursor:
        # 1. Cargar Reservas (Siempre útil)
        cursor.execute("""
            SELECT lr.id, l.name, u.name, u.first_lastname, lr.start_time, lr.end_time, rr.name, lr.comment
            FROM lab_reservation lr
            JOIN lab l ON lr.lab_id = l.id JOIN user u ON lr.user_id = u.id JOIN reservation_reason rr ON lr.reservation_reason_id = rr.id
            WHERE lr.reservation_status = 'pending' ORDER BY lr.start_time ASC
        """)
        rows = cursor.fetchall()
        for row in rows:
            reservas_pendientes.append({'id': row[0], 'laboratorio': row[1], 'profesor': f"{row[2]} {row[3]}", 'inicio': row[4], 'fin': row[5], 'motivo': row[6], 'comentario': row[7]})

        # 2. Cargar Datos según la Pestaña
        if tab_actual == 'pendientes':
            cursor.callproc('sp_get_active_loans')
            rows = cursor.fetchall()
            for row in rows:
                try:
                    eq = Equipment.objects.select_related('equipment_type').get(id=row[1])
                    nm_eq = eq.equipment_type.name; sn = eq.serial_number
                    usr = User.objects.get(id=row[2])
                    nm_usr = f"{usr.name} {usr.first_lastname}"
                except: nm_eq="Err"; nm_usr="Err"; sn="--"
                
                vencido = False
                if row[6]:
                    dt = row[6] if timezone.is_aware(row[6]) else timezone.make_aware(row[6])
                    if dt < timezone.now(): vencido = True

                prestamos_activos.append({'id': row[0], 'equipo': nm_eq, 'serie': sn, 'solicitante': nm_usr, 'fecha_limite': row[6], 'vencido': vencido})

        elif tab_actual == 'historial':
            # Traemos TODO el historial (últimos 100)
            cursor.execute("""
                SELECT l.id, et.name, e.serial_number, u.name, u.first_lastname, l.loan_date, l.return_date, l.loan_status
                FROM loan l
                JOIN equipment e ON l.equipment_id = e.id
                JOIN equipment_type et ON e.equipment_type_id = et.id
                JOIN user u ON l.user_requester__id = u.id
                ORDER BY l.loan_date DESC LIMIT 100
            """)
            rows = cursor.fetchall()
            for row in rows:
                historial_completo.append({
                    'id': row[0], 'equipo': row[1], 'serie': row[2], 
                    'solicitante': f"{row[3]} {row[4]}", 
                    'fecha_inicio': row[5], 'fecha_fin': row[6], 'estado': row[7]
                })

        elif tab_actual == 'incidentes':
            # Traemos incidentes
            cursor.execute("""
                SELECT i.id, et.name, e.inventory_tag, u.name, u.first_lastname, it.name, s.name, i.description, i.incident_status, i.reported_at
                FROM incident i
                JOIN equipment e ON i.equipment_id = e.id
                JOIN equipment_type et ON e.equipment_type_id = et.id
                JOIN user u ON i.user_reporter_id = u.id
                JOIN incident_type it ON i.incident_type_id = it.id
                JOIN severity s ON i.severity_id = s.id
                ORDER BY i.reported_at DESC
            """)
            rows = cursor.fetchall()
            for row in rows:
                incidentes_reportados.append({
                    'id': row[0], 'equipo': row[1], 'tag': row[2],
                    'reportador': f"{row[3]} {row[4]}",
                    'tipo': row[5], 'severidad': row[6], 'desc': row[7],
                    'estado': row[8], 'fecha': row[9]
                })

        elif tab_actual == 'inventario_tech':
            # Traemos TODO el inventario para que el técnico lo gestione
            equipos_gestion = Equipment.objects.select_related('equipment_type', 'lab', 'equipment_status').all().order_by('id')
            
            # Lo pasamos al template en una variable nueva
            contexto_extra = {'equipos_gestion': equipos_gestion}

    # Cargar lista estatus para menú manual
    lista_estatus = []
    with connection.cursor() as cursor:
        cursor.execute("SELECT id, name FROM equipment_status")
        lista_estatus = cursor.fetchall()

    # Diccionario base de contexto
    contexto = {
        'tab_actual': tab_actual,
        'prestamos': prestamos_activos,
        'historial': historial_completo,
        'incidentes': incidentes_reportados,
        'reservas': reservas_pendientes,
        'lista_estatus': lista_estatus,
        'usuario_nombre': request.session.get('usuario_nombre')
    }

    # Si definimos datos extra para la nueva pestaña, los agregamos
    if 'equipos_gestion' in locals():
        contexto['equipos_gestion'] = equipos_gestion

    return render(request, 'tecnico.html', contexto)



# ==========================================
# 6. MÓDULO ADMIN (Reportes)
# ==========================================

def admin_hub_view(request):
    # Seguridad: Solo Staff (Admins)
    if not request.user.is_authenticated or not request.user.is_staff:
        return redirect('login')
    
    return render(request, 'admin_hub.html', {
        'usuario_nombre': request.user.username
    })

def reportes_view(request):
    if not request.user.is_authenticated or not request.user.is_staff:
        return redirect('login')

    hoy = datetime.datetime.now()
    hace_un_mes = hoy - datetime.timedelta(days=30)
    
    fecha_inicio = request.GET.get('inicio', hace_un_mes.strftime('%Y-%m-%dT00:00'))
    fecha_fin = request.GET.get('fin', hoy.strftime('%Y-%m-%dT23:59'))
    lab_id = request.GET.get('lab_id') # Puede ser None o un ID string

    datos_uso = []
    datos_incidentes = []
    
    # Títulos dinámicos
    titulo_incidentes = "📊 Resumen Global de Incidentes"
    titulo_actividad = "📅 Actividad Detallada (Selecciona un Laboratorio)"

    start_sql = fecha_inicio.replace('T', ' ')
    end_sql = fecha_fin.replace('T', ' ')

    with connection.cursor() as cursor:
        # 1. REPORTE DE USO (Solo si hay lab seleccionado)
        if lab_id:
            try:
                cursor.callproc('sp_report_lab_usage', [lab_id, start_sql, end_sql])
                datos_uso = cursor.fetchall() 
                # Buscamos el nombre del lab para el título
                nombre_lab = Lab.objects.get(id=lab_id).name
                titulo_actividad = f"📅 Actividad Detallada: {nombre_lab}"
                titulo_incidentes = f"📊 Incidentes en: {nombre_lab}"
            except Exception as e: 
                print(f"Error reporte uso: {e}")

        # 2. REPORTE DE INCIDENTES (Global o Filtrado)
        try:
            cursor.nextset()
            # Ahora pasamos lab_id (puede ser None si es global)
            cursor.callproc('sp_report_incidents_by_severity', [start_sql, end_sql, lab_id])
            datos_incidentes = cursor.fetchall()
        except Exception as e: 
            print(f"Error reporte incidentes: {e}")

    laboratorios = Lab.objects.filter(active=True)

    return render(request, 'reportes.html', {
        'laboratorios': laboratorios, 
        'datos_uso': datos_uso,
        'datos_incidentes': datos_incidentes, 
        'fecha_inicio': fecha_inicio,
        'fecha_fin': fecha_fin, 
        'lab_seleccionado': int(lab_id) if lab_id else None,
        'titulo_incidentes': titulo_incidentes,
        'titulo_actividad': titulo_actividad,
        'hay_lab': bool(lab_id) # Bandera para el HTML
    })

def chat_ia_view(request):
    if request.method == 'POST':
        try:
            # --- CORRECCIÓN: CONEXIÓN DENTRO DE LA FUNCIÓN ---
            # La clave se lee de la variable de entorno OPENAI_API_KEY
            client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])  # set in the environment, never in code 
            # -------------------------------------------------

            data = json.loads(request.body)
            pregunta_usuario = data.get('mensaje', '')

            # 1. Contexto de Datos
            labs = Lab.objects.filter(active=1).count()
            equipos_libres = Equipment.objects.filter(equipment_status_id=1).count()
            
            contexto_db = f"Estado del Sistema SIGLET:\n- {labs} laboratorios operativos.\n- {equipos_libres} equipos disponibles."

            # 2. Prompt
            prompt_sistema = f"""
            Eres 'Siggy', el asistente virtual de SIGLET.
            INFORMACIÓN EN TIEMPO REAL: {contexto_db}
            Responde conciso.
            """

            # 3. Llamada a la API
            respuesta = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": prompt_sistema},
                    {"role": "user", "content": pregunta_usuario}
                ]
            )
            
            texto_respuesta = respuesta.choices[0].message.content
            return JsonResponse({'respuesta': texto_respuesta})

        except Exception as e:
            # Esto te dirá exactamente qué falló
            return JsonResponse({'respuesta': f"Error técnico: {str(e)}"}, status=500)
    
    return JsonResponse({'error': 'Método no permitido'}, status=400)

def mapa_interactivo(request):
    # Por defecto mostramos el primer laboratorio activo (ej. CPB01)
    lab = Lab.objects.filter(active=1).first()
    
    if not lab:
        return render(request, 'core/error.html', {'mensaje': 'No hay laboratorios activos.'})

    # Traemos todos los equipos de este lab
    equipos = Equipment.objects.filter(lab=lab).select_related('equipment_status', 'equipment_type')

    # Diccionario para agrupar:  mesas[1] = [PC, Monitor...]
    mesas = defaultdict(list)
    for eq in equipos:
        mesas[eq.station_number].append(eq)

    # Preparamos la info visual para el HTML
    mapa_visual = {}
    
    # Asumimos que hay hasta 6 mesas (o el máximo que hayas cargado)
    max_mesas = max(mesas.keys()) if mesas else 6
    
    for i in range(1, max_mesas + 1):
        lista_equipos = mesas.get(i, [])
        estado_color = 'success' # Verde por defecto
        alerta = False

        # Regla de Negocio: Si UN equipo falla, la mesa está Roja
        for eq in lista_equipos:
            nombre_status = eq.equipment_status.name.lower()
            if nombre_status in ['dañado', 'mantenimiento', 'falla', 'roto', 'reparación']:
                estado_color = 'danger' # Rojo
                alerta = True
                break
        
        # Si la mesa está vacía, la ponemos gris
        if not lista_equipos:
            estado_color = 'secondary'

        mapa_visual[i] = {
            'equipos': lista_equipos,
            'color': estado_color,
            'alerta': alerta
        }

    return render(request, 'mapa_inventario.html', {
        'lab': lab,
        'mapa': mapa_visual,
        'rango_mesas': range(1, max_mesas + 1) # Para iterar en el template
    })