class Alert {
  final String id;
  final String alertType;
  final String description;
  final bool active;
  final int verifiedCount;
  final String? photoUrl;
  final double lat;
  final double lon;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Alert({
    required this.id,
    required this.alertType,
    required this.description,
    required this.active,
    required this.verifiedCount,
    this.photoUrl,
    required this.lat,
    required this.lon,
    required this.createdAt,
    this.updatedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      alertType: json['alert_type'],
      description: json['description'],
      active: json['active'],
      verifiedCount: json['verified_count'] ?? 0,
      photoUrl: json['photo_url'],
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  String get typeLabel {
    switch (alertType) {
      case 'porton':
        return 'Porton Cerrado';
      case 'robo':
        return 'Robo';
      case 'obstaculo':
        return 'Obstaculo';
      case 'barro':
        return 'Barro';
      case 'talco':
        return 'Talco';
      case 'arbol_caido':
        return 'Arbol Caido';
      default:
        return alertType;
    }
  }

  String get typeIcon {
    switch (alertType) {
      case 'porton':
        return '🚪';
      case 'robo':
        return '⚠️';
      case 'obstaculo':
        return '🚧';
      case 'barro':
        return '💧';
      case 'talco':
        return '🌫️';
      case 'arbol_caido':
        return '🌲';
      default:
        return '📍';
    }
  }
}
