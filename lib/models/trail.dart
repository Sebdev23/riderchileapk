class Trail {
  final String id;
  final String name;
  final String discipline;
  final String difficulty;
  final String? description;
  final double? lengthKm;
  final double? elevationGainM;
  final List<List<double>> coordinates;
  final bool isPublic;
  final String? canonicalTrailId;
  final double rating;
  final int ratingCount;
  final int timesRidden;
  final DateTime createdAt;

  Trail({
    required this.id,
    required this.name,
    required this.discipline,
    required this.difficulty,
    this.description,
    this.lengthKm,
    this.elevationGainM,
    this.coordinates = const [],
    this.isPublic = true,
    this.canonicalTrailId,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.timesRidden = 0,
    required this.createdAt,
  });

  factory Trail.fromJson(Map<String, dynamic> json) {
    return Trail(
      id: json['id'],
      name: json['name'],
      discipline: json['discipline'],
      difficulty: json['difficulty'],
      description: json['description'],
      lengthKm: (json['length_km'] as num?)?.toDouble(),
      elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble(),
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((c) => [(c as List<dynamic>)[0] as double, c[1] as double])
              .toList() ?? [],
      isPublic: json['is_public'] ?? true,
      canonicalTrailId: json['canonical_trail_id'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      timesRidden: json['times_ridden'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
