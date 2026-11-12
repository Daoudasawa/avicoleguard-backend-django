class FarmModel {
  final String id;
  final String name;
  final String locationText;
  final int? capacity;
  final String clientUuid;
  final String syncStatus;

  FarmModel({
    required this.id,
    required this.name,
    this.locationText = '',
    this.capacity,
    required this.clientUuid,
    this.syncStatus = 'synced',
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      locationText: json['location_text'] ?? '',
      capacity: json['capacity'] as int?,
      clientUuid: json['client_uuid']?.toString() ?? '',
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location_text': locationText,
      'capacity': capacity,
      'client_uuid': clientUuid,
      'sync_status': syncStatus,
    };
  }
}
