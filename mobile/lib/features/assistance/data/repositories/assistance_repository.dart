import 'package:uuid/uuid.dart';
import 'package:avicoleguard_mobile/core/api/api_endpoints.dart';
import 'package:avicoleguard_mobile/core/api/dio_client.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import '../models/ticket_model.dart';

class AssistanceRepository {
  final DioClient _dioClient;
  final _uuid = const Uuid();

  AssistanceRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<TicketModel> getCachedTickets() {
    try {
      final box = LocalStorageService.getTicketsBox();
      final list = <TicketModel>[];
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          list.add(TicketModel.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<TicketModel>> fetchTickets() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.tickets);
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final box = LocalStorageService.getTicketsBox();
        final list = <TicketModel>[];
        for (var item in raw) {
          final t = TicketModel.fromJson(Map<String, dynamic>.from(item));
          list.add(t);
          await box.put(t.id, t.toJson());
        }
        return list;
      }
    } catch (_) {}
    return getCachedTickets();
  }

  Future<TicketModel> createTicket({
    required String flockId,
    required String subject,
    required String description,
  }) async {
    final clientUuid = _uuid.v4();
    final ticket = TicketModel(
      id: clientUuid,
      flockId: flockId,
      subject: subject,
      description: description,
      status: 'open',
      createdAt: DateTime.now(),
      clientUuid: clientUuid,
      syncStatus: 'pending',
    );

    final box = LocalStorageService.getTicketsBox();
    await box.put(ticket.id, ticket.toJson());

    await LocalStorageService.getSyncQueueBox().put(clientUuid, {
      'type': 'create_ticket',
      'payload': ticket.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    });

    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.tickets,
        data: ticket.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverTicket = TicketModel.fromJson(
            Map<String, dynamic>.from(response.data));
        await box.put(serverTicket.id, serverTicket.toJson());
        await LocalStorageService.getSyncQueueBox().delete(clientUuid);
        return serverTicket;
      }
    } catch (_) {}

    return ticket;
  }

  Future<List<TicketMessageModel>> fetchMessages(String ticketId) async {
    try {
      final response = await _dioClient.dio.get('${ApiEndpoints.tickets}$ticketId/messages/');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return raw
            .map((m) => TicketMessageModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<TicketMessageModel?> sendMessage({
    required String ticketId,
    required String content,
  }) async {
    final clientUuid = _uuid.v4();
    try {
      final response = await _dioClient.dio.post(
        '${ApiEndpoints.tickets}$ticketId/messages/',
        data: {
          'content': content,
          'client_uuid': clientUuid,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return TicketMessageModel.fromJson(
            Map<String, dynamic>.from(response.data));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> closeTicket(String ticketId) async {
    try {
      final response = await _dioClient.dio.post('${ApiEndpoints.tickets}$ticketId/close/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
