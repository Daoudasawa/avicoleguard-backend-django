class FlockModel {
  final String id;
  final String farmId;
  final String reference;
  final String breed;
  final String sex;
  final int initialCount;
  final int currentCount;
  final DateTime arrivalDate;
  final DateTime? endDate;
  final String status; // active, closed
  final String clientUuid;
  final String syncStatus;

  FlockModel({
    required this.id,
    required this.farmId,
    required this.reference,
    this.breed = '',
    this.sex = 'mixed',
    required this.initialCount,
    required this.currentCount,
    required this.arrivalDate,
    this.endDate,
    this.status = 'active',
    required this.clientUuid,
    this.syncStatus = 'synced',
  });

  bool get isActive => status.toLowerCase() == 'active';

  double get mortalityRate {
    if (initialCount <= 0) return 0.0;
    return ((initialCount - currentCount) / initialCount) * 100.0;
  }

  int get totalDead => initialCount - currentCount;

  factory FlockModel.fromJson(Map<String, dynamic> json) {
    return FlockModel(
      id: json['id']?.toString() ?? '',
      farmId: json['farm']?.toString() ?? json['farm_id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      breed: json['breed'] ?? '',
      sex: json['sex'] ?? 'mixed',
      initialCount: (json['initial_count'] as num?)?.toInt() ?? 0,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      arrivalDate: json['arrival_date'] != null
          ? DateTime.tryParse(json['arrival_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      status: json['status'] ?? 'active',
      clientUuid: json['client_uuid']?.toString() ?? '',
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm': farmId,
      'reference': reference,
      'breed': breed,
      'sex': sex,
      'initial_count': initialCount,
      'current_count': currentCount,
      'arrival_date': arrivalDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'status': status,
      'client_uuid': clientUuid,
      'sync_status': syncStatus,
    };
  }

  FlockModel copyWith({
    String? id,
    String? farmId,
    String? reference,
    String? breed,
    String? sex,
    int? initialCount,
    int? currentCount,
    DateTime? arrivalDate,
    DateTime? endDate,
    String? status,
    String? clientUuid,
    String? syncStatus,
  }) {
    return FlockModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      reference: reference ?? this.reference,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      initialCount: initialCount ?? this.initialCount,
      currentCount: currentCount ?? this.currentCount,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      clientUuid: clientUuid ?? this.clientUuid,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
