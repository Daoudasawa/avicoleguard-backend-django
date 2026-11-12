import 'package:flutter_test/flutter_test.dart';
import 'package:avicoleguard_mobile/features/mortality/data/models/mortality_model.dart';
import 'package:avicoleguard_mobile/features/observations/data/models/observation_model.dart';
import 'package:avicoleguard_mobile/features/assistance/data/models/ticket_model.dart';

void main() {
  group('MortalityModel Tests (RM1, RM11)', () {
    test('MortalityModel correctly detects cancelled status (RM11)', () {
      final activeMortality = MortalityModel(
        id: 'mort-1',
        flockId: 'flock-1',
        date: DateTime(2026, 1, 1),
        deadCount: 5,
        clientUuid: 'uuid-1',
      );
      expect(activeMortality.isCancelled, isFalse);

      final cancelledMortality = MortalityModel(
        id: 'mort-2',
        flockId: 'flock-1',
        date: DateTime(2026, 1, 1),
        deadCount: 5,
        clientUuid: 'uuid-2',
        cancelledAt: DateTime.now(),
        cancelReason: 'Erreur de saisie / doublon',
      );
      expect(cancelledMortality.isCancelled, isTrue);
      expect(cancelledMortality.cancelReason, 'Erreur de saisie / doublon');
    });

    test('MortalityModel serialization & deserialization', () {
      final m = MortalityModel(
        id: 'mort-3',
        flockId: 'flock-1',
        date: DateTime(2026, 1, 2),
        deadCount: 3,
        presumedCause: 'Chaleur',
        clientUuid: 'uuid-3',
        syncStatus: 'pending',
      );
      final json = m.toJson();
      final fromJson = MortalityModel.fromJson(json);

      expect(fromJson.id, 'mort-3');
      expect(fromJson.deadCount, 3);
      expect(fromJson.presumedCause, 'Chaleur');
      expect(fromJson.isCancelled, isFalse);
    });
  });

  group('ObservationModel Tests (E3)', () {
    test('ObservationModel typeLabels and formatting', () {
      final obs = ObservationModel(
        id: 'obs-1',
        flockId: 'flock-1',
        date: DateTime(2026, 1, 1),
        type: 'respiratory',
        description: 'Toux et râles observés',
        clientUuid: 'uuid-obs-1',
      );

      expect(obs.typeLabel, 'Respiratoire');
      expect(obs.isCancelled, isFalse);
    });
  });

  group('Assistance TicketModel Tests (E2)', () {
    test('TicketModel isOpen logic', () {
      final openTicket = TicketModel(
        id: 'ticket-1',
        flockId: 'flock-1',
        subject: 'Baisse consommation',
        description: 'Baisse hydrique',
        status: 'open',
        createdAt: DateTime.now(),
        clientUuid: 'uuid-ticket-1',
      );
      expect(openTicket.isOpen, isTrue);

      final inProgressTicket = TicketModel(
        id: 'ticket-2',
        flockId: 'flock-1',
        subject: 'Visite demandée',
        description: 'Besoin passage vétérinaire',
        status: 'in_progress',
        createdAt: DateTime.now(),
        clientUuid: 'uuid-ticket-2',
      );
      expect(inProgressTicket.isOpen, isTrue);

      final closedTicket = TicketModel(
        id: 'ticket-3',
        flockId: 'flock-1',
        subject: 'Résolu',
        description: 'Résolu',
        status: 'closed',
        createdAt: DateTime.now(),
        clientUuid: 'uuid-ticket-3',
      );
      expect(closedTicket.isOpen, isFalse);
    });
  });
}
