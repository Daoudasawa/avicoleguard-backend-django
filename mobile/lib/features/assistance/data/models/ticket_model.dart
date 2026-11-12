class TicketMessageModel {
  final String id;
  final String ticketId;
  final String content;
  final String? authorName;
  final DateTime createdAt;
  final String? clientUuid;
  final String syncStatus;

  TicketMessageModel({
    required this.id,
    required this.ticketId,
    required this.content,
    this.authorName,
    required this.createdAt,
    this.clientUuid,
    this.syncStatus = 'synced',
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket']?.toString() ?? json['ticket_id']?.toString() ?? '',
      content: json['content'] ?? '',
      authorName: json['author_name'] ?? json['author']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      clientUuid: json['client_uuid']?.toString(),
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket': ticketId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'client_uuid': clientUuid,
        'sync_status': syncStatus,
      };
}

class TicketModel {
  final String id;
  final String flockId;
  final String subject;
  final String description;
  final String status;
  final DateTime createdAt;
  final String clientUuid;
  final String syncStatus;
  final List<TicketMessageModel> messages;

  TicketModel({
    required this.id,
    required this.flockId,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.clientUuid,
    this.syncStatus = 'pending',
    this.messages = const [],
  });

  bool get isOpen => status == 'open' || status == 'in_progress';

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id']?.toString() ?? '',
      flockId: json['flock']?.toString() ?? json['flock_id']?.toString() ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      clientUuid: json['client_uuid']?.toString() ?? '',
      syncStatus: json['sync_status'] ?? 'synced',
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => TicketMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'flock': flockId,
        'subject': subject,
        'description': description,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'client_uuid': clientUuid,
        'sync_status': syncStatus,
      };
}
