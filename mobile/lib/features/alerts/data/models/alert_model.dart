class AlertModel {
  final String id;
  final String flockId;
  final String? flockReference;
  final String ruleCode;
  final String title;
  final String level; // information, attention, preoccupant, critique
  final String status; // open, acknowledged, closed
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.flockId,
    this.flockReference,
    required this.ruleCode,
    required this.title,
    required this.level,
    this.status = 'open',
    required this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isCritical => level == 'critique';
  bool get isPreoccupant => level == 'preoccupant';

  // Règle Métier RM9 : mention obligatoire, ne remplace pas un avis vétérinaire
  static const String rm9Disclaimer =
      "Signal détecté automatiquement, ne remplace pas un avis vétérinaire.";

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      flockId: json['flock']?.toString() ?? json['flock_id']?.toString() ?? '',
      flockReference: json['flock_reference'] ?? json['flock_name'],
      ruleCode: json['rule_code'] ?? '',
      title: json['title'] ?? 'Alerte Sanitaire',
      level: json['level'] ?? 'attention',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock': flockId,
      'flock_reference': flockReference,
      'rule_code': ruleCode,
      'title': title,
      'level': level,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
