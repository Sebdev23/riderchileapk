# MRIDER - Waze + Strava para Ciclistas

Plataforma colaborativa de ciclismo que combina navegacion, seguridad, planificacion y comunidad.

> **Roadmap completo:** [ROADMAP.md](ROADMAP.md) - 70 funcionalidades en 6 fases

---

## Que hace hoy (Fase 1 - 100% completada)

- **Mapa** con 4 capas mostrando rutas MTB, puntos de interes y alertas de camino
- **Grabacion GPS** de rodadas con stats en vivo y resumen post-ruta
- **Compartir rutas** y subir archivos GPX
- **Alertas comunitarias** tipo Waze con 6 categorias, verificaciones y fotos
- **Presencia en tiempo real** de otros ciclistas en el mapa
- **Punto de ubicacion personalizable** con 8 colores a eleccion
- **Clima** en ubicacion actual via Open-Meteo
- **Emergencia**: numeros directos SAMU, Bomberos, Carabineros, PDI
- **Login** con email

## Stack

- Flutter 3.7+ / Dart
- flutter_map + OpenStreetMap/Mapbox
- Supabase (PostgreSQL + PostGIS + Auth + Storage)
- Provider (ChangeNotifier)

## Compilar

```bash
flutter clean
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## Base de Datos

Ejecutar `migration.sql` en el SQL Editor de Supabase para crear tablas, indices y funciones RPC.
