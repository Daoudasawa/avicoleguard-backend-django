class MortalityModel {
  final String id;
  final String flockId;
  final String? flockReference;
  final DateTime date;
  final int deadCount;
  final String presumedCause;
  final String notes;
  final String clientUuid;
  final String syncStatus;
  final DateTime? cancelledAt;
  final String? cancelReason;

  MortalityModel({
    required this.id,
    required this.flockId,
    this.flockReference,
    required this.date,
    required this.deadCount,
    this.presumedCause = '',
    this.notes = '',
    required this.clientUuid,
    this.syncStatus = 'pending',
    this.cancelledAt,
    this.cancelReason,
  });

  bool get isCancelled => cancelledAt != null;

  factory MortalityModel.fromJson(Map<String, dynamic> json) {
    return MortalityModel(
      id: json['id']?.toString() ?? '',
      flockId: json['flock']?.toString() ?? json['flock_id']?.toString() ?? '',
      flockReference: json['flock_reference'] ?? json['flock_name'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deadCount: (json['dead_count'] as num?)?.toInt() ?? 0,
      presumedCause: json['presumed_cause'] ?? '',
      notes: json['notes'] ?? '',
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
      'flock_reference': flockReference,
      'date': date.toIso8601String().split('T').first,
      'dead_count': deadCount,
      'presumed_cause': presumedCause,
      'notes': notes,
      'client_uuid': clientUuid,
      'sync_status': syncStatus,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancel_reason': cancelReason,
    };
  }
}
