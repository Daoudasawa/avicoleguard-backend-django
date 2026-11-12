import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/empty_state_widget.dart';
import 'package:avicoleguard_mobile/shared/widgets/status_badge.dart';

class FlocksListScreen extends StatefulWidget {
  const FlocksListScreen({super.key});

  @override
  State<FlocksListScreen> createState() => _FlocksListScreenState();
}

class _FlocksListScreenState extends State<FlocksListScreen> {
  String _filter = 'active'; // 'all', 'active', 'closed'

  @override
  Widget build(BuildContext context) {
    final farmFlock = context.watch<FarmFlockProvider>();
    final allFlocks = farmFlock.flocks;

    final filtered = allFlocks.where((f) {
      if (_filter == 'active') return f.isActive;
      if (_filter == 'closed') return !f.isActive;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mes Lots de Volailles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => farmFlock.refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRouter.addFlockRoute),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Lot'),
      ),
      body: Column(
        children: [
          // Barre de filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Actifs (${farmFlock.activeFlocks.length})',
                  isSelected: _filter == 'active',
                  onSelected: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tous (${allFlocks.length})',
                  isSelected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Clôturés (${allFlocks.length - farmFlock.activeFlocks.length})',
                  isSelected: _filter == 'closed',
                  onSelected: () => setState(() => _filter = 'closed'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Liste des lots
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aucun lot trouvé',
                    message: _filter == 'active'
                        ? 'Vous n\'avez aucun lot actif actuellement.'
                        : 'Aucun lot ne correspond à ce filtre.',
                    actionLabel: 'Créer un Lot',
                    onAction: () => Navigator.of(context)
                        .pushNamed(AppRouter.addFlockRoute),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final flock = filtered[index];
                      final arrivalFormatted =
                          DateFormat('dd/MM/yyyy').format(flock.arrivalDate);
                      final rate = flock.mortalityRate;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.divider),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.flockDetailRoute,
                              arguments: flock,
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      flock.reference,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    StatusBadge.flockStatus(flock.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mise en place : $arrivalFormatted',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (flock.breed.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.pets_outlined,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        flock.breed,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _MetricColumn(
                                        label: 'Départ',
                                        value: '${flock.initialCount}',
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: AppColors.divider,
                                      ),
                                      _MetricColumn(
                                        label: 'Actuel',
                                        value: '${flock.currentCount}',
                                        valueColor: AppColors.primary,
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: AppColors.divider,
                                      ),
                                      _MetricColumn(
                                        label: 'Pertes',
                                        value: '${rate.toStringAsFixed(1)}%',
                                        valueColor: rate > 5.0
                                            ? AppColors.alertCritical
                                            : AppColors.alertSuccess,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withAlpha(40),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
