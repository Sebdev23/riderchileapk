# MRIDER - Plataforma Comunitaria de Ciclismo de Montana

Plataforma colaborativa para ciclistas de montana en Chile. Descubre rutas, reporta condiciones del camino, ve otros ciclistas en tiempo real y registra tus rodadas.

---

## Roadmap de Funcionalidades

### 1. Exploracion y Mapa

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Mapa interactivo con 4 capas | Listo | OSM, Topografico, Satelital, Mapbox Outdoors |
| Ubicacion GPS en tiempo real | Listo | Punto azul con halo en el mapa |
| Personalizacion del punto de ubicacion | Pendiente | Color, icono, tamano, animacion |
| Flecha de direccion (heading) | Pendiente | Indicador que apunta hacia donde miras |
| Clima en ubicacion actual | Listo | Temperatura, viento, condicion via Open-Meteo |
| Mapas offline | Pendiente | Premium |

### 2. Rutas y Grabacion

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Grabacion GPS de rodadas | Listo | Distancia, velocidad, elevacion en vivo |
| Guardar ruta con disciplina y dificultad | Listo | XC, Trail, Enduro, DH, Gravel |
| Subir archivos GPX | Listo | Parseo XML, conversion a WKT |
| Deteccion de rutas duplicadas | Listo | Sugiere mejorar ruta existente |
| Listado y busqueda de rutas | Listo | Filtro por disciplina, busqueda por nombre |
| Favoritos locales | Listo | Guardados en SharedPreferences |
| Rating de rutas | Listo | Estrellas via RPC |
| Resumen post-ruta con graficos | Listo | Elevacion, stats, clima, compartir |
| Comentarios en rutas | Pendiente | Comunidad |
| Fotos en rutas | Listo | Camara durante grabacion |

### 3. Alertas Comunitarias (tipo Waze)

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Reportar alertas de camino | Listo | 6 tipos: porton, robo, obstaculo, barro, talco, arbol |
| Ver alertas cercanas en mapa | Listo | Radio 10km, marcadores rojos |
| Notificacion de nuevas alertas | Listo | Snackbar cada 15s si hay alertas nuevas |
| Verificar/confirmar alertas | Pendiente | Boton "Yo tambien lo vi" |
| Fotos en alertas | Pendiente | Evidencia visual |
| Caducidad automatica de alertas | Pendiente | Si nadie verifica en X dias, se desactivan |

### 4. Puntos de Interes (POI)

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Agregar servicios al mapa | Listo | Comida, taller, agua, estacionamiento, tienda |
| Filtro por categoria | Listo | Chips en barra superior |
| Detalle con telefono y direccion | Listo | Llamada directa |
| Promociones para ciclistas | Parcial | Campo existe en BD pero sin UI de administracion |

### 5. Comunidad en Tiempo Real

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Ver otros ciclistas en el mapa | Listo | Puntos verdes con nombre (PresenceService) |
| Pausar al minimizar la app | Listo | WidgetsBindingObserver |
| Limpiar ubicacion al salir | Listo | DELETE automatico |
| Filtro espacial real | Listo | RPC nearby_user_locations |
| Chat entre ciclistas cercanos | Pendiente | Futuro |

### 6. Autenticacion y Perfil

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Login con email | Listo | Auto-registro con contrasena |
| Login con Google | Parcial | Configurado pero necesita OAuth en Supabase |
| Login con Apple | Pendiente | Placeholder |
| Perfil de usuario | Basico | Muestra nombre, email, badge premium |
| Estadisticas personales | Pendiente | KMs recorridos, rutas completadas |
| Personalizar color/icono en mapa | Pendiente | Desde perfil |

### 7. Premium

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Badge PREMIUM | Listo | Hardcodeado true (todos son premium) |
| Sistema de pago real | Pendiente | RevenueCat, Stripe o codigos |
| Mapas offline | Pendiente | Premium |
| GPS turn-by-turn | Pendiente | Premium |
| Sin anuncios | Pendiente | Premium |
| Rutas ilimitadas | Pendiente | Premium |

### 8. Emergencia

| Funcionalidad | Estado | Descripcion |
|---|---|---|
| Numeros de emergencia Chile | Listo | SAMU 131, Bomberos 132, Carabineros 133, PDI 134 |
| Boton SOS en mapa | Listo | Chip rojo en barra de filtros |

---

## Estado General: 60% completado

- **Listo:** 22 funcionalidades
- **Parcial:** 3 funcionalidades
- **Pendiente:** 15 funcionalidades

---

## Stack Tecnico

- **Frontend:** Flutter 3.7+ (Dart)
- **Mapa:** flutter_map + OpenStreetMap/Mapbox
- **Backend:** Supabase (PostgreSQL + PostGIS + Auth)
- **Estado:** Provider (ChangeNotifier)
- **GPS:** Geolocator

## Base de Datos (Supabase)

Ejecutar `migration.sql` en el SQL Editor para crear:
- Tabla `user_locations` con RLS, indice y RPC espacial
- Realtime habilitado para ubicaciones y alertas

## Compilar APK

```bash
flutter clean
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```
