import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/mortality/data/models/mortality_model.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/providers/mortality_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/stat_card.dart';
import 'package:avicoleguard_mobile/shared/widgets/status_badge.dart';

class FlockDetailScreen extends StatefulWidget {
  final FlockModel flock;

  const FlockDetailScreen({super.key, required this.flock});

  @override
  State<FlockDetailScreen> createState() => _FlockDetailScreenState();
}

class _FlockDetailScreenState extends State<FlockDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MortalityProvider>().refresh(widget.flock.id);
    });
  }

  /// RM11 — Dialog de confirmation d'annulation d'une mortalité.
  Future<void> _showCancelDialog(
    BuildContext context,
    MortalityModel mortality,
    FlockModel flock,
  ) async {
    final reasonController = TextEditingController();
    final mortalityProvider = context.read<MortalityProvider>();
    final farmFlockProvider = context.read<FarmFlockProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette saisie ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est tracée (RM11). L\'effectif du lot sera recalculé de +${mortality.deadCount} sujet(s).',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motif obligatoire *',
                hintText: 'ex: doublon de saisie, erreur de comptage',
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Le motif est obligatoire.')),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await mortalityProvider.cancelMortality(
        flockId: flock.id,
        mortalityId: mortality.id,
        reason: reasonController.text.trim(),
      );

      if (success) {
        // Recalcule l'effectif local (+deadCount car annulation)
        farmFlockProvider.onMortalityAdded(flock.id, -mortality.deadCount);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Saisie annulée — effectif recalculé (RM11).'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                mortalityProvider.errorMessage ??
                    'Erreur lors de l\'annulation.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// US-FLOCK-002 — Dialog de confirmation de clôture de lot. RM7 : irréversible.
  Future<void> _showCloseFlockDialog(
      BuildContext context, FlockModel flock) async {
    final farmFlockProvider = context.read<FarmFlockProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer ce lot ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le lot "${flock.reference}" sera marqué comme clôturé. '
              'Aucune saisie (mortalité, suivi, observation) ne sera plus possible (RM7).',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est définitive.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Clôturer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await farmFlockProvider.closeFlock(flock.id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Lot "${flock.reference}" clôturé (RM7 — plus de saisie possible).'
                : 'Échec de la clôture.'),
            backgroundColor: ok ? Colors.deepOrange : AppColors.alertCritical,
          ),
        );
        if (ok) navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Look up latest updated flock from provider if count changed
    final flocks = context.watch<FarmFlockProvider>().flocks;
    final currentFlock = flocks.firstWhere(
      (f) => f.id == widget.flock.id,
      orElse: () => widget.flock,
    );

    final mortalityProvider = context.watch<MortalityProvider>();
    final flockMortalities = mortalityProvider.mortalities
        .where((m) => m.flockId == currentFlock.id)
        .toList();

    final arrivalFormatted =
        DateFormat('dd/MM/yyyy').format(currentFlock.arrivalDate);
    final rate = currentFlock.mortalityRate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentFlock.reference),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: StatusBadge.flockStatus(currentFlock.status),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fiche Technique du Lot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    _InfoRow(label: 'Référence', value: currentFlock.reference),
                    const SizedBox(height: 8),
                    _InfoRow(
                        label: 'Souche / Race',
                        value: currentFlock.breed.isNotEmpty
                            ? currentFlock.breed
                            : 'Standard'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Sexe', value: currentFlock.sex),
                    const SizedBox(height: 8),
                    _InfoRow(
                        label: 'Date de mise en place', value: arrivalFormatted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cartes de statistiques
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Effectif Initial',
                    value: '${currentFlock.initialCount}',
                    subtitle: 'Sujets au départ',
                    icon: Icons.group_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Effectif Actuel',
                    value: '${currentFlock.currentCount}',
                    subtitle: 'Sujets vivants',
                    icon: Icons.pets,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Pertes Totales',
                    value: '${currentFlock.totalDead}',
                    subtitle: 'Mortalités cumulées',
                    icon: Icons.trending_down,
                    color: currentFlock.totalDead > 0
                        ? AppColors.alertCritical
                        : AppColors.alertSuccess,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Taux de Perte',
                    value: '${rate.toStringAsFixed(1)}%',
                    subtitle: rate > 5.0 ? 'Seuil d\'alerte' : 'Normal',
                    icon: Icons.pie_chart_outline,
                    color: rate > 5.0
                        ? AppColors.alertCritical
                        : AppColors.alertSuccess,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Boutons Actions Rapides pour ce lot
            if (currentFlock.isActive) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.addMortalityRoute,
                      arguments: currentFlock,
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Déclarer une mortalité sur ce lot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertCritical,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.addObservationRoute,
                      arguments: currentFlock,
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Déclarer une observation sanitaire'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCloseFlockDialog(context, currentFlock),
                  icon: const Icon(Icons.lock_outline, color: Colors.deepOrange),
                  label: const Text(
                    'Clôturer ce lot',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Historique des mortalités de ce lot
            const Text(
              'Historique des Saisies de Mortalité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (flockMortalities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 36, color: AppColors.alertSuccess),
                    SizedBox(height: 8),
                    Text(
                      'Aucune perte enregistrée',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ce lot ne présente aucune mortalité déclarée.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: flockMortalities.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final m = flockMortalities[idx];
                  final mDate = DateFormat('dd/MM/yyyy').format(m.date);
                  final isCancelled = m.isCancelled;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.grey.shade50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCancelled
                            ? Colors.grey.shade300
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? Colors.grey.withAlpha(30)
                                    : AppColors.alertCritical.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCancelled ? Icons.undo : Icons.remove,
                                color: isCancelled
                                    ? Colors.grey
                                    : AppColors.alertCritical,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mDate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCancelled
                                        ? Colors.grey
                                        : AppColors.textPrimary,
                                    decoration: isCancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (isCancelled)
                                  const Text(
                                    'ANNULÉE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else if (m.presumedCause.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cause : ${m.presumedCause}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              isCancelled
                                  ? '(annulée)'
                                  : '-${m.deadCount} sujet(s)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCancelled
                                    ? Colors.grey
                                    : AppColors.alertCritical,
                                fontSize: 15,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            // Bouton d'annulation RM11 (uniquement si non annulée et lot actif)
                            if (!isCancelled && currentFlock.isActive) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Annuler cette saisie (RM11)',
                                onPressed: () => _showCancelDialog(
                                    context, m, currentFlock),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
