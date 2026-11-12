class ObservationModel {
  final String id;
  final String flockId;
  final DateTime date;
  final String type;
  final String description;
  final String clientUuid;
  final String syncStatus;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? createdAt;

  ObservationModel({
    required this.id,
    required this.flockId,
    required this.date,
    required this.type,
    this.description = '',
    required this.clientUuid,
    this.syncStatus = 'pending',
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
  });

  bool get isCancelled => cancelledAt != null;

  static const Map<String, String> typeLabels = {
    'abnormal_behavior': 'Comportement anormal',
    'respiratory': 'Respiratoire',
    'feeding': 'Alimentation',
    'digestive': 'Digestif',
    'plumage': 'Plumage',
    'locomotor': 'Locomoteur',
    'other': 'Autre',
  };

  static const Map<String, String> typeIcons = {
    'abnormal_behavior': '🧠',
    'respiratory': '💨',
    'feeding': '🌾',
    'digestive': '💊',
    'plumage': '🪶',
    'locomotor': '🦵',
    'other': '📋',
  };

  String get typeLabel => typeLabels[type] ?? type;
  String get typeIcon => typeIcons[type] ?? '📋';

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    return ObservationModel(
      id: json['id']?.toString() ?? '',
      flockId:
          json['flock']?.toString() ?? json['flock_id']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['type'] ?? 'other',
      description: json['description'] ?? '',
      clientUuid: json['client_uuid']?.toString() ?? '',
      syncStatus: json['sync_status'] ?? 'synced',
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      cancelReason: json['cancel_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock': flockId,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'client_uuid': clientUuid,
      'sync_status': syncStatus,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancel_reason': cancelReason,
    };
  }
}
