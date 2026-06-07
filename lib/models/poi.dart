class Poi {
  final String id;
  final String category;
  final String name;
  final String? description;
  final String? phone;
  final String? address;
  final String? website;
  final String? promotion;
  final double rating;
  final int ratingCount;
  final double lat;
  final double lon;

  Poi({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    this.phone,
    this.address,
    this.website,
    this.promotion,
    required this.rating,
    required this.ratingCount,
    required this.lat,
    required this.lon,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'],
      category: json['category'],
      name: json['name'],
      description: json['description'],
      phone: json['phone'],
      address: json['address'],
      website: json['website'],
      promotion: json['promotion'],
      rating: (json['rating'] as num).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  String get categoryIcon {
    switch (category) {
      case 'emergency': return '🏥';
      case 'food': return '🍔';
      case 'workshop': return '🔧';
      case 'hydration': return '💧';
      case 'parking': return '🅿️';
      case 'shop': return '🛒';
      default: return '📍';
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'emergency': return 'Emergencia';
      case 'food': return 'Comida';
      case 'workshop': return 'Taller';
      case 'hydration': return 'Agua';
      case 'parking': return 'Estacionamiento';
      case 'shop': return 'Tienda';
      default: return category;
    }
  }

  String get categoryColor {
    switch (category) {
      case 'emergency': return '#E53935';
      case 'food': return '#FF9800';
      case 'workshop': return '#2196F3';
      case 'hydration': return '#00BCD4';
      case 'parking': return '#4CAF50';
      case 'shop': return '#9C27B0';
      default: return '#757575';
    }
  }
}
