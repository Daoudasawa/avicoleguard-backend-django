import 'package:flutter/foundation.dart';
import '../../data/models/ticket_model.dart';
import '../../data/repositories/assistance_repository.dart';

class AssistanceProvider extends ChangeNotifier {
  final AssistanceRepository _repo;

  List<TicketModel> _tickets = [];
  List<TicketMessageModel> _currentMessages = [];
  bool _isLoading = false;
  String? _errorMessage;

  AssistanceProvider(this._repo) {
    _tickets = _repo.getCachedTickets();
  }

  List<TicketModel> get tickets => _tickets;
  List<TicketMessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get openTicketsCount => _tickets.where((t) => t.isOpen).length;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _tickets = await _repo.fetchTickets();
    } catch (_) {
      _tickets = _repo.getCachedTickets();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketModel?> createTicket({
    required String flockId,
    required String subject,
    required String description,
  }) async {
    try {
      final t = await _repo.createTicket(
        flockId: flockId,
        subject: subject,
        description: description,
      );
      _tickets.insert(0, t);
      notifyListeners();
      return t;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(String ticketId) async {
    _currentMessages = await _repo.fetchMessages(ticketId);
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String ticketId,
    required String content,
  }) async {
    final msg = await _repo.sendMessage(
      ticketId: ticketId,
      content: content,
    );
    if (msg != null) {
      _currentMessages.add(msg);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> closeTicket(String ticketId) async {
    final ok = await _repo.closeTicket(ticketId);
    if (ok) {
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _tickets[idx] = TicketModel(
          id: _tickets[idx].id,
          flockId: _tickets[idx].flockId,
          subject: _tickets[idx].subject,
          description: _tickets[idx].description,
          status: 'closed',
          createdAt: _tickets[idx].createdAt,
          clientUuid: _tickets[idx].clientUuid,
        );
        notifyListeners();
      }
    }
    return ok;
  }
}
