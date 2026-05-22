# Alertas de secretos en GitHub (Firebase API keys)

GitHub detectó claves en `lib/firebase_options.dart` del commit inicial. Esas claves son **API keys de cliente** de Firebase (van en la app), no la cuenta de servicio del backend (`service-account.json`, que no debe subirse).

Aun así conviene **restringirlas y, si quieres máxima seguridad, rotarlas**, porque quedaron en el historial público del repo.

## Qué hacer ahora

### 1. Restringir claves en Google Cloud (obligatorio)

1. [Google Cloud Console](https://console.cloud.google.com/) → proyecto `melodaiapp`.
2. **APIs y servicios** → **Credenciales**.
3. Para cada API key expuesta:
   - **Restricciones de aplicación**: Android (package + SHA-1), iOS (bundle id), o referrers HTTP para web/Windows.
   - **Restricciones de API**: solo las que uses (Identity Toolkit, Firebase, etc.).

### 2. Rotar (recomendado si el repo es público)

En Firebase Console → Configuración del proyecto → tus apps → regenera o crea nuevas claves y actualiza:

- `lib/firebase_options.dart` (local, no en git)
- `android/app/google-services.json` (local)
- `backend/.env` → `FIREBASE_WEB_API_KEY` (misma web key que Windows)

### 3. Configuración local (ya no se suben al repo)

```powershell
# Desde la raíz del proyecto
copy lib\firebase_options.example.dart lib\firebase_options.dart
copy android\app\google-services.json.example android\app\google-services.json
# Rellena con tus claves o ejecuta:
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart` y `google-services.json` están en `.gitignore`.

### 4. Historial de Git

El commit `f5d5f1e` **sigue conteniendo las claves** en GitHub aunque las quites del código actual. Opciones:

- Rotar claves (suficiente en la mayoría de casos).
- Reescribir historial con [git-filter-repo](https://github.com/newren/git-filter-repo) o GitHub “secret scanning” remediation (si GitHub lo ofrece en la alerta).

## Qué nunca debe estar en GitHub

| Archivo | Motivo |
|---------|--------|
| `backend/.env` | Web API key, MongoDB, Redis, `WORKER_API_KEY` |
| `backend/service-account.json` | Credencial de servidor GCS/Admin |
| `worker/.env` | Claves del worker |
| `lib/firebase_options.dart` | API keys de cliente (ahora ignorado) |
| `android/app/google-services.json` | API key Android (ahora ignorado) |

Sí pueden estar en el repo: `*.example`, `firebase_options.example.dart`, `google-services.json.example`.
