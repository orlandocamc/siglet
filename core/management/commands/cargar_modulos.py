import csv
import os
from django.core.management.base import BaseCommand
from core.models import Equipment, Lab, EquipmentType, EquipmentStatus

class Command(BaseCommand):
    help = 'Carga masiva de módulos con corrección de Series Duplicadas'

    def add_arguments(self, parser):
        parser.add_argument('csv_file', type=str, help='Ruta al archivo CSV')

    def handle(self, *args, **kwargs):
        csv_file_path = kwargs['csv_file']
        
        if not os.path.exists(csv_file_path):
            self.stdout.write(self.style.ERROR(f'❌ No encuentro el archivo: {csv_file_path}'))
            return

        print(f"📂 Leyendo archivo: {csv_file_path}...")

        # Aseguramos el estado "Disponible"
        estado_ok, _ = EquipmentStatus.objects.get_or_create(name="Disponible")
        
        with open(csv_file_path, 'r', encoding='utf-8-sig') as file:
            reader = csv.DictReader(file)
            
            total_procesados = 0
            
            for i, row in enumerate(reader):
                nombre_salon = row.get('Salon', 'CPB01')
                num_mesa = row.get('Mesa', 1)
                tipo_equipo = row.get('Tipo', 'Generico')
                # marca = row.get('Marca', 'Generica')
                serie_raw = row.get('Serie', 'S/N').strip() # Quitamos espacios

                # --- 🚑 LÓGICA ANTI-DUPLICADOS ---
                # Si la serie es genérica, le pegamos un ID único para que MySQL no se queje
                series_genericas = ['S/N', 's/n', 'NA', 'N/A', 'SIN SERIE', '', '0']
                
                if serie_raw in series_genericas:
                    # Creamos una serie única tipo: S/N-CPB01-M1-45
                    serie_final = f"S/N-{nombre_salon}-M{num_mesa}-{i}"
                else:
                    # Si parece real, intentamos usarla. Si falla por duplicado, el try/catch lo atrapa.
                    serie_final = serie_raw
                # ---------------------------------

                # 1. Laboratorio
                lab, _ = Lab.objects.get_or_create(
                    name=nombre_salon,
                    defaults={'description': f'Laboratorio {nombre_salon}', 'active': 1}
                )

                # 2. Tipo de Equipo
                tipo, _ = EquipmentType.objects.get_or_create(
                    name=tipo_equipo,
                    defaults={'requires_calibration': False}
                )

                # 3. Crear el Equipo
                try:
                    Equipment.objects.create(
                        lab=lab,
                        equipment_type=tipo,
                        equipment_status=estado_ok,
                        inventory_tag=f"INV-{nombre_salon}-{num_mesa}-{i}",
                        serial_number=serie_final, # <--- Usamos la serie corregida
                        station_number=int(num_mesa),
                        cost=0,
                        decomissioned=0
                    )
                    total_procesados += 1
                    if total_procesados % 10 == 0:
                        print(f"   ✅ Procesados {total_procesados} equipos...")
                
                except Exception as e:
                    # Si aún así falla (ej. serie real duplicada), avisamos y seguimos
                    if "Duplicate entry" in str(e):
                        print(f"   ⚠️ Serie Duplicada Real en fila {i}: {serie_final} (Saltando...)")
                    else:
                        print(f"   ❌ Error en fila {i}: {e}")

            self.stdout.write(self.style.SUCCESS(f'🎉 ¡LISTO! Se importaron {total_procesados} equipos correctamente.'))