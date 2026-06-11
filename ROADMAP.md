# MRIDER - Roadmap

> **Vision:** Plataforma colaborativa que combina Waze + Strava para ciclistas. Navegacion, planificacion, seguridad y comunidad en una sola app.

---

## Pilares de la App

| Pilar | Inspiracion | Objetivo |
|---|---|---|
| **Navegacion** | Google Maps | Planificar rutas para bici, mapas offline, GPS turn-by-turn |
| **Seguridad** | Waze | Alertas colaborativas, ver otros ciclistas en tiempo real, asistencia |
| **Comunidad** | Strava | Registrar rodadas, descubrir rutas, rankings, compartir |
| **Planificacion** | Propio | Clima por fecha/hora, condiciones de ruta antes de salir |

---

## FASE 1: Fundacion - Completado

> MVP funcional con mapa, rutas, alertas basicas y presencia en tiempo real.

| ID | Funcionalidad | Estado |
|---|---|---|
| F1.1 | Mapa interactivo multilayers (OSM, Topo, Satelite, Mapbox) | Listo |
| F1.2 | GPS: ubicacion en tiempo real con tracking | Listo |
| F1.3 | Grabacion de rodadas (distancia, velocidad, elevacion) | Listo |
| F1.4 | Guardar ruta con disciplina (XC, Trail, Enduro, DH, Gravel) y dificultad | Listo |
| F1.5 | Subida de archivos GPX | Listo |
| F1.6 | Listado de rutas con filtros por disciplina y busqueda | Listo |
| F1.7 | Favoritos locales (SharedPreferences) | Listo |
| F1.8 | Rating de rutas | Listo |
| F1.9 | Deteccion de rutas duplicadas (mejorar existente) | Listo |
| F1.10 | Resumen post-ruta (stats, elevacion, clima, compartir) | Listo |
| F1.11 | Alertas comunitarias: 6 tipos (porton, robo, obstaculo, barro, talco, arbol) | Listo |
| F1.12 | Verificar alertas ("Yo tambien lo vi") | Listo |
| F1.13 | Fotos en alertas (evidencia visual) | Listo |
| F1.14 | Puntos de interes (comida, taller, agua, estacionamiento, tienda) | Listo |
| F1.15 | Clima en ubicacion actual (Open-Meteo) | Listo |
| F1.16 | Numeros de emergencia Chile (SAMU, Bomberos, Carabineros, PDI) | Listo |
| F1.17 | Autenticacion con email | Listo |
| F1.18 | Presencia de ciclistas en el mapa (tipo Waze) | Listo |
| F1.19 | Punto de ubicacion personalizable (8 colores) | Listo |
| F1.20 | Perfil de usuario basico | Listo |

**Progreso Fase 1: 20/20 (100%)**

---

## FASE 2: Seguridad y Comunidad - En progreso

> Fortalecer el aspecto colaborativo y de seguridad en ruta.

| ID | Funcionalidad | Estado | Prioridad |
|---|---|---|---|
| F2.1 | Boton SOS: alerta de emergencia a contactos con ubicacion | Pendiente | Alta |
| F2.2 | Compartir ubicacion en vivo con contacto especifico (no publico) | Pendiente | Alta |
| F2.3 | Deteccion de caida/accidente (usando acelerometro) | Pendiente | Media |
| F2.4 | "Estoy en problemas": notificar a ciclistas cercanos que necesitas ayuda | Pendiente | Alta |
| F2.5 | Caducidad automatica de alertas (si nadie verifica en X dias) | Pendiente | Media |
| F2.6 | Ranking de verificadores: quienes mas confirman alertas | Pendiente | Baja |
| F2.7 | Notificacion push de alerta nueva en ruta que vas a tomar | Pendiente | Alta |
| F2.8 | Chat entre ciclistas cercanos (solo si ambos aceptan) | Pendiente | Media |
| F2.9 | Grupos de ruta: crear salida grupal con hora y punto de encuentro | Pendiente | Alta |
| F2.10 | Comentarios en rutas (tabla trail_comments ya creada) | Pendiente | Media |
| F2.11 | Fotos en rutas (galeria por ruta) | Pendiente | Baja |
| F2.12 | "Ruta verificada": ciclistas confirman que la ruta existe y esta transitable | Pendiente | Media |

**Progreso Fase 2: 1/12 (8%)**

---

## FASE 3: Planificacion Inteligente

> Planificar salidas con datos reales de clima, ruta y condiciones.

| ID | Funcionalidad | Estado | Prioridad |
|---|---|---|---|
| F3.1 | Planificador de salida: elegir ruta + dia + hora | Pendiente | Alta |
| F3.2 | Pronostico del tiempo para fecha/hora especifica de la ruta | Pendiente | Alta |
| F3.3 | Datos: temperatura, prob. lluvia, viento, humedad, indice UV | Pendiente | Alta |
| F3.4 | Recomendacion: "Condiciones favorables / regulares / no recomendado" | Pendiente | Media |
| F3.5 | Estado de la ruta: alertas activas en el recorrido planificado | Pendiente | Alta |
| F3.6 | Tiempo estimado de ruta basado en distancia + desnivel + ritmo personal | Pendiente | Media |
| F3.7 | Notificacion recordatoria 1 dia antes de la salida planificada | Pendiente | Baja |
| F3.8 | Historial de salidas planificadas vs realizadas | Pendiente | Baja |
| F3.9 | Sugerencia de rutas alternativas si la planificada tiene alertas | Pendiente | Baja |
| F3.10 | Integracion con calendario del telefono | Pendiente | Baja |

**Progreso Fase 3: 0/10 (0%)**

---

## FASE 4: Descubrimiento y Social

> Conectar ciclistas, descubrir nuevas rutas, gamificacion.

| ID | Funcionalidad | Estado | Prioridad |
|---|---|---|---|
| F4.1 | Feed social: rutas destacadas, nuevos records, fotos | Pendiente | Alta |
| F4.2 | Segmentos tipo Strava: competir por tiempos en tramos especificos | Pendiente | Alta |
| F4.3 | Perfil publico con estadisticas (KMs, desnivel acumulado, rutas) | Pendiente | Media |
| F4.4 | Logros/medallas (primeros 100km, 1000m desnivel, 10 rutas, etc.) | Pendiente | Media |
| F4.5 | Ranking semanal/mensual por disciplina | Pendiente | Baja |
| F4.6 | Retos comunitarios (ej: "100km de XC este mes") | Pendiente | Baja |
| F4.7 | Importar/exportar rutas de Strava, Komoot, Wikiloc | Pendiente | Media |
| F4.8 | Compartir ruta en vivo durante la rodada | Pendiente | Media |
| F4.9 | Eventos y competencias (calendario comunitario) | Pendiente | Baja |
| F4.10 | Seguir a otros ciclistas y ver su actividad | Pendiente | Media |

**Progreso Fase 4: 0/10 (0%)**

---

## FASE 5: Navegacion Avanzada

> Mapas offline, GPS turn-by-turn, calculo de rutas.

| ID | Funcionalidad | Estado | Prioridad |
|---|---|---|---|
| F5.1 | Calculo de ruta punto A -> B optimizada para bici | Pendiente | Alta |
| F5.2 | Mapas offline (descarga de tiles por region) | Pendiente | Alta |
| F5.3 | Navegacion turn-by-turn con indicaciones de voz | Pendiente | Alta |
| F5.4 | Perfil de elevacion durante navegacion | Pendiente | Media |
| F5.5 | Evitar calles peligrosas / preferir ciclovias | Pendiente | Media |
| F5.6 | Waypoints personalizados en ruta | Pendiente | Baja |
| F5.7 | Modo "descubrimiento": mostrar rutas cercanas no exploradas | Pendiente | Baja |
| F5.8 | Navegacion offline completa | Pendiente | Alta |

**Progreso Fase 5: 0/8 (0%)**

---

## FASE 6: Premium y Monetizacion

> Modelo de negocio sostenible sin afectar funciones basicas.

| ID | Funcionalidad | Estado | Prioridad |
|---|---|---|---|
| F6.1 | Sistema de suscripcion (RevenueCat o Stripe) | Pendiente | Alta |
| F6.2 | Planes: Free / Pro ($3.990/mes) / Equipo (descuento grupos) | Pendiente | Alta |
| F6.3 | Premium: mapas offline | Pendiente | Alta |
| F6.4 | Premium: navegacion turn-by-turn | Pendiente | Alta |
| F6.5 | Premium: segmentos y rankings | Pendiente | Media |
| F6.6 | Premium: planificador de salidas con clima | Pendiente | Media |
| F6.7 | Premium: rutas ilimitadas guardadas | Pendiente | Baja |
| F6.8 | Premium: sin anuncios | Pendiente | Baja |
| F6.9 | Codigos de patrocinio (marcas de bici regalan Premium) | Pendiente | Baja |
| F6.10 | Dashboard para tiendas/talleres (gestionar POIs y promociones) | Pendiente | Baja |

**Progreso Fase 6: 1/10 (10%)** - Solo badge visual, sin logica real

---

## Resumen General

| Fase | Nombre | Completado | Funcionalidades |
|---|---|---|---|
| Fase 1 | Fundacion | 100% | 20 de 20 |
| Fase 2 | Seguridad y Comunidad | 8% | 1 de 12 |
| Fase 3 | Planificacion Inteligente | 0% | 0 de 10 |
| Fase 4 | Descubrimiento y Social | 0% | 0 de 10 |
| Fase 5 | Navegacion Avanzada | 0% | 0 de 8 |
| Fase 6 | Premium y Monetizacion | 10% | 1 de 10 |
| **Total** | | **33%** | **23 de 70** |

---

## Proxima Iteracion Recomendada (Fase 2)

Prioridad para el proximo sprint:

1. **Boton SOS** (F2.1): alerta de emergencia que envia ubicacion a contactos predefinidos
2. **Grupos de ruta** (F2.9): crear salidas grupales con punto de encuentro y hora
3. **Notificacion push de alertas** (F2.7): aviso cuando aparece alerta en ruta que planeas
4. **Compartir ubicacion con contacto** (F2.2): modo seguro para salidas solitarias
5. **Caducidad automatica de alertas** (F2.5): limpiar alertas viejas no verificadas
