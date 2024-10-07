import requests
import json
from datetime import datetime, timedelta
import os
import sys
import time
from google.cloud import storage


ALFRESCO_PASSWORD = os.getenv('ALFRESCO_PASSWORD')
ALFRESCO_USERNAME = os.getenv('ALFRESCO_USERNAME')
BUCKET_NAME = os.getenv('BUCKET_NAME')
ALFRESCO_BASE_URL = os.getenv('ALFRESCO_BASE_URL')
DAYS_BACK = int(os.getenv('DAYS_BACK'))
DELETE_AFTER_EXPORT = os.getenv('DELETE_AFTER_EXPORT')

auth = (ALFRESCO_USERNAME, ALFRESCO_PASSWORD)
headers = {
    "Content-Type": "application/json"
}


current_date = datetime.now()


storage_client = storage.Client()
bucket = storage_client.bucket(BUCKET_NAME)

# Configuración del mecanismo de reintento
max_retries = 5
retry_delay = 10

# Iterar sobre cada uno de los días desde el `days_back` hasta ayer
for day in range(1, DAYS_BACK + 1):
    # Calcular el día específico
    target_date = current_date - timedelta(days=day)
    date_str = target_date.strftime("%Y-%m-%d")
    start_date = datetime.strptime(date_str, "%Y-%m-%d")

    all_entries = []
    successful_exports = True

    # Iterar por cada hora del día
    for hour in range(24):
        # Calcular las marcas de tiempo para la hora de inicio y la siguiente hora
        from_time = (start_date + timedelta(hours=hour)).strftime("%Y-%m-%dT%H:%M:%S.000%z")
        to_time = (start_date + timedelta(hours=hour + 1)).strftime("%Y-%m-%dT%H:%M:%S.000%z")

        url = f"https://{ALFRESCO_BASE_URL}/alfresco/api/-default-/public/alfresco/versions/1/audit-applications/alfresco-access/audit-entries?where=(createdAt BETWEEN ('{from_time}%2B0000','{to_time}%2B0000'))&include=values&maxItems=1000000"
        print(url)

        # Mecanismo de reintento
        for attempt in range(max_retries):
            try:
                response = requests.get(url, headers=headers, auth=auth, timeout=60)  # Timeout de 60 segundos
                response.raise_for_status()
                print(f"Solicitud exitosa: {response.status_code}")
                break
            except (requests.exceptions.ConnectTimeout, requests.exceptions.ReadTimeout):
                if attempt < max_retries - 1:
                    print(f"Timeout alcanzado, reintentando en {retry_delay} segundos... (Intento {attempt + 1} de {max_retries})")
                    time.sleep(retry_delay)
                else:
                    print("Número máximo de reintentos alcanzado. Abortando.")
                    successful_exports = False
                    sys.exit(1)
            except requests.exceptions.RequestException as e:
                print(f"Ocurrió un error con la solicitud: {e}")
                successful_exports = False
                sys.exit(1)

        if response.status_code == 200:
            data = response.json()
            if "list" in data and "entries" in data["list"]:
                all_entries.extend(data["list"]["entries"])
        else:
            print(f"Error {response.status_code} al obtener datos para la hora {hour}:00 - {hour+1}:00 del día {date_str}")
            successful_exports = False

    json_data = json.dumps(all_entries, ensure_ascii=False, indent=4)

    # Sube los datos al bucket de Google Cloud Storage
    blob_name = f"audit_entries_{date_str}.json"
    blob = bucket.blob(blob_name)
    try:
        blob.upload_from_string(json_data, content_type='application/json')
        print(f"Datos guardados en el bucket {BUCKET_NAME} con el nombre {blob_name} para el día {date_str}")
    except Exception as e:
        print(f"Error al subir los datos al bucket {BUCKET_NAME}: {e}")
        successful_exports = False

    # Si DELETE_AFTER_EXPORT es True y todos los exports han sido exitosos, se eliminan los registros
    if DELETE_AFTER_EXPORT and successful_exports:
        delete_url = f"https://{ALFRESCO_BASE_URL}/alfresco/api/-default-/public/alfresco/versions/1/audit-applications/alfresco-access/audit-entries?where=(createdAt BETWEEN ('{date_str}T00:00:00.000%2B0000','{date_str}T23:59:59.999%2B0000'))"
        delete_attempts = 0
        while delete_attempts < max_retries:
            try:
                delete_response = requests.delete(delete_url, headers=headers, auth=auth, timeout=60)
                delete_response.raise_for_status()  # Si no es exitoso (200-299), lanza error
                print(f"Registros de auditoría para el día {date_str} eliminados exitosamente.")
                break
            except requests.exceptions.RequestException as e:
                delete_attempts += 1
                if delete_attempts < max_retries:
                    print(f"Error al borrar registros, reintentando en {retry_delay} segundos... (Intento {delete_attempts} de {max_retries})")
                    time.sleep(retry_delay)
                else:
                    print(f"No se pudo borrar los registros de auditoría para el día {date_str}. Error: {e}")

