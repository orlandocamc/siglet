import os
import django
# --- PARCHE PARA WINDOWS ---
import pymysql
pymysql.install_as_MySQLdb()
# ---------------------------
from django.db import connection

# Configurar entorno
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'siglet_web.settings')
django.setup()

def arreglar_procedures():
    print("⏳ Iniciando actualización de Procedimientos Almacenados...")
    
    with connection.cursor() as cursor:
        # PASO 1: Borrar el viejo (Si existe)
        print("🗑️  Eliminando versión anterior del SP...")
        try:
            cursor.execute("DROP PROCEDURE IF EXISTS sp_create_equipment;")
            print("✅ SP eliminado correctamente.")
        except Exception as e:
            print(f"⚠️ Alerta al borrar: {e}")

        # PASO 2: Crear el nuevo (Con la columna station_number)
        print("🔨 Creando nuevo Procedimiento Almacenado...")
        sql_create = """
        CREATE PROCEDURE sp_create_equipment(
            IN p_equipment_type_id INT, 
            IN p_lab_id INT, 
            IN p_equipment_status_id INT,
            IN p_inventory_tag VARCHAR(50), 
            IN p_serial_number VARCHAR(50),
            IN p_purchase_date DATE, 
            IN p_cost DECIMAL(10, 2),
            IN p_station_number INT
        )
        BEGIN
            INSERT INTO equipment (
                equipment_type_id, 
                lab_id, 
                equipment_status_id, 
                inventory_tag, 
                serial_number, 
                purchase_date, 
                cost, 
                decomissioned, 
                station_number
            ) 
            VALUES (
                p_equipment_type_id, 
                p_lab_id, 
                p_equipment_status_id, 
                p_inventory_tag, 
                p_serial_number, 
                p_purchase_date, 
                p_cost, 
                0, 
                p_station_number
            );
            SELECT LAST_INSERT_ID() as id;
        END;
        """
        try:
            cursor.execute(sql_create)
            print("🎉 ¡ÉXITO TOTAL! Procedimiento actualizado.")
        except Exception as e:
            print(f"❌ ERROR AL CREAR: {e}")

if __name__ == '__main__':
    arreglar_procedures()