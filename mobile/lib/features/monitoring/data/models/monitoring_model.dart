class DailyMonitoringModel {
  final String id;
  final String flockId;
  final DateTime date;
  final double? temperature;
  final double? waterConsumption;
  final double? feedConsumption;
  final double? averageWeight;
  final String clientUuid;
  final String syncStatus;
  final DateTime? cancelledAt;
  final String? cancelReason;

  DailyMonitoringModel({
    required this.id,
    required this.flockId,
    required this.date,
    this.temperature,
    this.waterConsumption,
    this.feedConsumption,
    this.averageWeight,
    required this.clientUuid,
    this.syncStatus = 'pending',
    this.cancelledAt,
    this.cancelReason,
  });

  /// RM11 — un enregistrement annulé n'est jamais supprimé physiquement.
  bool get isCancelled => cancelledAt != null;

  factory DailyMonitoringModel.fromJson(Map<String, dynamic> json) {
    return DailyMonitoringModel(
      id: json['id']?.toString() ?? '',
      flockId: json['flock']?.toString() ?? json['flock_id']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      waterConsumption: (json['water_consumption'] as num?)?.toDouble(),
      feedConsumption: (json['feed_consumption'] as num?)?.toDouble(),
      averageWeight: (json['average_weight'] as num?)?.toDouble(),
      clientUuid: json['client_uuid']?.toString() ?? '',
      syncStatus: json['sync_status'] ?? 'synced',
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      cancelReason: json['cancel_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock': flockId,
      'date': date.toIso8601String().split('T').first,
      'temperature': temperature,
      'water_consumption': waterConsumption,
      'feed_consumption': feedConsumption,
      'average_weight': averageWeight,
      'client_uuid': clientUuid,
      'sync_status': syncStatus,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancel_reason': cancelReason,
    };
  }
}
