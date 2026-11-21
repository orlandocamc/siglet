# Este archivo contiene todos los modelos mapeados a tu DB de AWS RDS.
from django.db import models
from django.utils import timezone # Importado para manejo de fechas en __str__

# --- CLASES PRINCIPALES ---

class Equipment(models.Model):
    equipment_type = models.ForeignKey('EquipmentType', models.DO_NOTHING)
    lab = models.ForeignKey('Lab', models.DO_NOTHING, blank=True, null=True)
    equipment_status = models.ForeignKey('EquipmentStatus', models.DO_NOTHING)
    retirement_cause = models.ForeignKey('RetirementCause', models.DO_NOTHING, blank=True, null=True)
    inventory_tag = models.CharField(unique=True, max_length=120)
    serial_number = models.CharField(unique=True, max_length=120, blank=True, null=True)
    purchase_date = models.DateField(blank=True, null=True)
    cost = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    decomissioned = models.IntegerField()
    retirement_date = models.DateTimeField(blank=True, null=True)

    station_number = models.PositiveIntegerField(
        default=1,
        verbose_name="Número de Mesa/Estación",
        help_text="Número de la mesa física en el plano del salón (Ej. 1, 2, 3...)"
    )

    class Meta:
        managed = False
        db_table = 'equipment'

    def __str__(self):
        return f"{self.equipment_type.name} - Tag: {self.inventory_tag}"


class EquipmentMovements(models.Model):
    equipment = models.ForeignKey(Equipment, models.DO_NOTHING)
    lab_origin = models.ForeignKey('Lab', models.DO_NOTHING, blank=True, null=True)
    loan_origin = models.ForeignKey('Loan', models.DO_NOTHING, blank=True, null=True)
    lab_destination = models.ForeignKey('Lab', models.DO_NOTHING, related_name='equipmentmovements_lab_destination_set', blank=True, null=True)
    loan_destination = models.ForeignKey('Loan', models.DO_NOTHING, related_name='equipmentmovements_loan_destination_set', blank=True, null=True)
    movement_date = models.DateTimeField()
    note = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'equipment_movements'

    def __str__(self):
        return f"Movimiento {self.id} de {self.equipment.inventory_tag}"


class Incident(models.Model):
    equipment = models.ForeignKey(Equipment, models.DO_NOTHING, blank=True, null=True)
    lab = models.ForeignKey('Lab', models.DO_NOTHING, blank=True, null=True)
    user_reporter = models.ForeignKey('User', models.DO_NOTHING)
    user_assigned = models.ForeignKey('User', models.DO_NOTHING, related_name='incident_user_assigned_set', blank=True, null=True)
    loan = models.ForeignKey('Loan', models.DO_NOTHING)
    incident_type = models.ForeignKey('IncidentType', models.DO_NOTHING)
    severity = models.ForeignKey('Severity', models.DO_NOTHING)
    description = models.TextField()
    reported_at = models.DateTimeField()
    incident_status = models.CharField(max_length=11)
    closed_at = models.DateTimeField(blank=True, null=True)
    resolution = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'incident'

    def __str__(self):
        return f"Incidente #{self.id} - {self.incident_type.name} ({self.incident_status.upper()})"


class Lab(models.Model):
    name = models.CharField(max_length=120)
    building = models.CharField(max_length=120, blank=True, null=True)
    floor = models.IntegerField(blank=True, null=True)
    capacity = models.IntegerField(blank=True, null=True)
    description = models.CharField(max_length=255, blank=True, null=True)
    active = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'lab'

    def __str__(self):
        return self.name


class LabReservation(models.Model):
    lab = models.ForeignKey(Lab, models.DO_NOTHING)
    user = models.ForeignKey('User', models.DO_NOTHING)
    reservation_reason = models.ForeignKey('ReservationReason', models.DO_NOTHING)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    reservation_status = models.CharField(max_length=8)
    comment = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'lab_reservation'

    def __str__(self):
        return f"Reserva {self.lab.name} por {self.user.name} ({self.start_time.strftime('%Y-%m-%d')})"


class Loan(models.Model):
    equipment = models.ForeignKey(Equipment, models.DO_NOTHING)
    user_requester_field = models.ForeignKey('User', models.DO_NOTHING, db_column='user_requester__id')
    user_issuer_field = models.ForeignKey('User', models.DO_NOTHING, db_column='user_issuer__id', related_name='loan_user_issuer_field_set')
    user_receiver = models.ForeignKey('User', models.DO_NOTHING, related_name='loan_user_receiver_set', blank=True, null=True)
    loan_date = models.DateTimeField()
    due_date = models.DateTimeField()
    return_date = models.DateTimeField(blank=True, null=True)
    loan_status = models.CharField(max_length=8)
    remarks = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'loan'

    def __str__(self):
        return f"Préstamo #{self.id} | {self.equipment.inventory_tag} ({self.loan_status.upper()})"


class Maintenance(models.Model):
    equipment = models.ForeignKey(Equipment, models.DO_NOTHING)
    maintenance_type = models.CharField(max_length=10)
    description = models.TextField(blank=True, null=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(blank=True, null=True)
    cost = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    performed_by = models.CharField(max_length=150, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'maintenance'

    def __str__(self):
        return f"Mantenimiento {self.equipment.inventory_tag} ({self.maintenance_type})"


# --- CLASES DE CATÁLOGO Y RELACIONES ---

class EquipmentStatus(models.Model):
    name = models.CharField(unique=True, max_length=50)
    
    class Meta:
        managed = False
        db_table = 'equipment_status'
    
    def __str__(self):
        return self.name


class EquipmentType(models.Model):
    name = models.CharField(unique=True, max_length=120)
    requires_calibration = models.IntegerField()
    
    class Meta:
        managed = False
        db_table = 'equipment_type'
    
    def __str__(self):
        return self.name


class IncidentType(models.Model):
    name = models.CharField(max_length=120)
    description = models.CharField(max_length=255, blank=True, null=True)
    
    class Meta:
        managed = False
        db_table = 'incident_type'
    
    def __str__(self):
        return self.name


class ReservationReason(models.Model):
    name = models.CharField(unique=True, max_length=120)
    
    class Meta:
        managed = False
        db_table = 'reservation_reason'
    
    def __str__(self):
        return self.name


class RetirementCause(models.Model):
    name = models.CharField(unique=True, max_length=120)
    description = models.CharField(max_length=250, blank=True, null=True)
    
    class Meta:
        managed = False
        db_table = 'retirement_cause'
    
    def __str__(self):
        return self.name


class Role(models.Model):
    name = models.CharField(unique=True, max_length=50)
    
    class Meta:
        managed = False
        db_table = 'role'
    
    def __str__(self):
        return self.name


class Severity(models.Model):
    name = models.CharField(max_length=50)
    sla_hours = models.IntegerField()
    
    class Meta:
        managed = False
        db_table = 'severity'
    
    def __str__(self):
        return self.name


class User(models.Model):
    name = models.CharField(max_length=50)
    first_lastname = models.CharField(max_length=50)
    second_lastname = models.CharField(max_length=50, blank=True, null=True)
    active = models.IntegerField()
    created_at = models.DateTimeField()
    password = models.CharField(max_length=120)

    class Meta:
        managed = False
        db_table = 'user'

    def __str__(self):
        return f"{self.name} {self.first_lastname}"


class Permission(models.Model):
    name = models.CharField(unique=True, max_length=50)

    class Meta:
        managed = False
        db_table = 'permission'

    def __str__(self):
        return self.name


# --- RELACIONES COMPUESTAS (SIN MÉTODO __str__ Y SIN REGISTRO EN ADMIN) ---
# Se dejan como están para evitar errores de llave compuesta en el admin.

class RolePermission(models.Model):
    role = models.ForeignKey(Role, models.DO_NOTHING)
    permission = models.ForeignKey(Permission, models.DO_NOTHING)
    # Note: pk is composite, handled by ORM/DB

    class Meta:
        managed = False
        db_table = 'role_permission'


class UserRole(models.Model):
    user = models.ForeignKey(User, models.DO_NOTHING)
    role = models.ForeignKey(Role, models.DO_NOTHING)
    # Note: pk is composite, handled by ORM/DB

    class Meta:
        managed = False
        db_table = 'user_role'


class ReservationConflict(models.Model):
    lab_reservation_a = models.ForeignKey(LabReservation, models.DO_NOTHING)
    lab_reservation_b = models.ForeignKey(LabReservation, models.DO_NOTHING, related_name='reservationconflict_lab_reservation_b_set')
    detected_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'reservation_conflict'


class UserMail(models.Model):
    user = models.ForeignKey(User, models.DO_NOTHING)
    mail = models.CharField(unique=True, max_length=50)

    class Meta:
        managed = False
        db_table = 'user_mail'

    def __str__(self):
        return f"{self.user.name}'s mail: {self.mail}"


class UserPhone(models.Model):
    user = models.ForeignKey(User, models.DO_NOTHING)
    phone = models.IntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'user_phone'
    
    def __str__(self):
        return f"{self.user.name}'s phone: {self.phone}"