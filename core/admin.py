from django.contrib import admin
from django.db import connection
from django.contrib import messages
from django.apps import apps
from .models import User, UserRole, Equipment, Lab, Loan

# ========================================================
# 1. CONFIGURACIÓN DE USUARIOS (CON SPs Y ROLES)
# ========================================================
class UserRoleInline(admin.TabularInline):
    model = UserRole
    extra = 1

class UserAdmin(admin.ModelAdmin):
    inlines = [UserRoleInline]
    list_display = ('name', 'first_lastname', 'active', 'created_at', 'id')
    exclude = ('created_at',)
    search_fields = ('name', 'first_lastname')

    def save_model(self, request, obj, form, change):
        try:
            with connection.cursor() as cursor:
                if not change:
                    # CREAR (sp_create_user)
                    cursor.callproc('sp_create_user', [
                        obj.name, obj.first_lastname, obj.second_lastname,
                        1 if obj.active else 0, obj.password
                    ])
                    cursor.execute("SELECT LAST_INSERT_ID()")
                    new_id = cursor.fetchone()[0]
                    obj.id = new_id 
                    messages.success(request, f"Usuario {obj.name} creado vía SP (ID: {new_id}).")
                else:
                    # ACTUALIZAR (sp_update_user)
                    cursor.callproc('sp_update_user', [
                        obj.id, obj.name, obj.first_lastname, obj.second_lastname,
                        1 if obj.active else 0, obj.password
                    ])
                    messages.success(request, f"Usuario {obj.name} actualizado vía SP.")
        except Exception as e:
            messages.error(request, f"Error al guardar Usuario: {e}")

try: admin.site.register(User, UserAdmin)
except admin.sites.AlreadyRegistered: pass

# ========================================================
# 2. CONFIGURACIÓN DE EQUIPOS (CON SPs)
# ========================================================
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ('inventory_tag', 'equipment_type', 'lab', 'equipment_status', 'serial_number')
    search_fields = ('inventory_tag', 'serial_number')
    list_filter = ('equipment_type', 'lab', 'equipment_status')

    def save_model(self, request, obj, form, change):
        try:
            with connection.cursor() as cursor:
                if not change:
                    cursor.callproc('sp_create_equipment', [
                        obj.equipment_type.id, obj.lab.id if obj.lab else None,
                        obj.equipment_status.id, obj.retirement_cause.id if obj.retirement_cause else None,
                        obj.inventory_tag, obj.serial_number, obj.purchase_date,
                        obj.cost, 1 if obj.decomissioned else 0, obj.retirement_date
                    ])
                    messages.success(request, f"Equipo {obj.inventory_tag} creado vía SP.")
                else:
                    cursor.callproc('sp_update_equipment', [
                        obj.id, obj.equipment_type.id, obj.lab.id if obj.lab else None,
                        obj.equipment_status.id, obj.retirement_cause.id if obj.retirement_cause else None,
                        obj.inventory_tag, obj.serial_number, obj.purchase_date,
                        obj.cost, 1 if obj.decomissioned else 0, obj.retirement_date
                    ])
                    messages.success(request, f"Equipo {obj.inventory_tag} actualizado vía SP.")
        except Exception as e:
            messages.error(request, f"Error al guardar Equipo: {e}")

try: admin.site.register(Equipment, EquipmentAdmin)
except admin.sites.AlreadyRegistered: pass

# ========================================================
# 3. CONFIGURACIÓN DE LABORATORIOS (CON SPs)
# ========================================================
class LabAdmin(admin.ModelAdmin):
    list_display = ('name', 'building', 'floor', 'active')
    search_fields = ('name', 'building')

    def save_model(self, request, obj, form, change):
        try:
            with connection.cursor() as cursor:
                if not change:
                    cursor.callproc('sp_create_lab', [
                        obj.name, obj.building, obj.floor, obj.capacity,
                        obj.description, 1 if obj.active else 0
                    ])
                    messages.success(request, f"Laboratorio {obj.name} creado vía SP.")
                else:
                    cursor.callproc('sp_update_lab', [
                        obj.id, obj.name, obj.building, obj.floor, obj.capacity,
                        obj.description, 1 if obj.active else 0
                    ])
                    messages.success(request, f"Laboratorio {obj.name} actualizado vía SP.")
        except Exception as e:
            messages.error(request, f"Error al guardar Laboratorio: {e}")

try: admin.site.register(Lab, LabAdmin)
except admin.sites.AlreadyRegistered: pass

# ========================================================
# 4. CONFIGURACIÓN DE PRÉSTAMOS (LOAN) - ¡CRÍTICO!
# ========================================================
class LoanAdmin(admin.ModelAdmin):
    list_display = ('id', 'equipment', 'user_requester_field', 'loan_date', 'loan_status')
    list_filter = ('loan_status', 'loan_date')
    search_fields = ('equipment__inventory_tag', 'user_requester_field__name')
    # Ocultamos campos automáticos en la creación
    exclude = ('created_at', 'loan_date') 

    def save_model(self, request, obj, form, change):
        try:
            with connection.cursor() as cursor:
                if not change:
                    # --- CREAR PRÉSTAMO (sp_create_equipment_loan) ---
                    # Al crear, el SP pone la fecha actual y cambia estatus del equipo a 'Ocupado'
                    cursor.callproc('sp_create_equipment_loan', [
                        obj.equipment.id,
                        obj.user_requester_field.id,
                        obj.user_issuer_field.id,
                        obj.due_date,
                        obj.remarks or ''
                    ])
                    messages.success(request, "Préstamo creado y equipo marcado como OCUPADO (Vía SP).")
                else:
                    # --- ACTUALIZAR ---
                    # Si el admin marca como 'returned', usamos el SP de cierre
                    if obj.loan_status == 'returned' and obj.return_date:
                        cursor.callproc('sp_close_equipment_loan', [
                            obj.id,
                            obj.return_date,
                            obj.user_receiver.id if obj.user_receiver else request.user.id,
                            obj.remarks or ''
                        ])
                        messages.success(request, "Préstamo CERRADO y equipo LIBERADO (Vía SP).")
                    else:
                        # Edición menor (ej. cambiar fecha límite o comentarios)
                        # Usamos SQL directo porque no hay SP para "editar sin cerrar"
                        cursor.execute("""
                            UPDATE loan SET 
                            due_date=%s, remarks=%s, loan_status=%s 
                            WHERE id=%s
                        """, [obj.due_date, obj.remarks, obj.loan_status, obj.id])
                        messages.warning(request, "Actualización de datos realizada (Sin cambio de estatus de equipo).")

        except Exception as e:
            messages.error(request, f"Error en Préstamo: {e}")

try: admin.site.register(Loan, LoanAdmin)
except admin.sites.AlreadyRegistered: pass

# ========================================================
# 5. REGISTRO AUTOMÁTICO DEL RESTO
# ========================================================
app_config = apps.get_app_config('core')

modelos_a_ignorar = [
    'user', 'equipment', 'lab', 'loan', # Ya registrados manualmente arriba
    'userrole', 'rolepermission',       # Problemáticos
]

for model_name, model in app_config.models.items():
    if model_name.lower() in modelos_a_ignorar:
        continue
    try: admin.site.register(model)
    except Exception: pass