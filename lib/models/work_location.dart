class WorkLocation {
  final String? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkLocation({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50.0,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkLocation.fromMap(Map<String, dynamic> map, String docId) {
    return WorkLocation(
      id: docId,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radiusMeters: (map['radiusMeters'] ?? 50.0).toDouble(),
      organizationId: map['organizationId'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
