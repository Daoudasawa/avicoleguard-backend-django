import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/providers/alert_provider.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/providers/mortality_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/empty_state_widget.dart';
import 'package:avicoleguard_mobile/shared/widgets/stat_card.dart';
import 'package:avicoleguard_mobile/shared/widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _refreshData() async {
    await Future.wait([
      context.read<FarmFlockProvider>().refresh(),
      context.read<MortalityProvider>().refresh(),
      context.read<AlertProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final farmFlock = context.watch<FarmFlockProvider>();
    final mortality = context.watch<MortalityProvider>();
    final alert = context.watch<AlertProvider>();

    final totalActive = farmFlock.totalActiveBirds;
    final todayDead = mortality.todayDeadCount;
    final openAlerts = alert.openAlertsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pets, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'AvicoleGuard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Actualiser',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salutation Utilisateur
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${user?.displayName ?? "Éleveur"} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Voici le statut de vos élevages en temps réel.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Titre KPIs
              const Text(
                'Indicateurs Clés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Grille de 3 StatCards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Volailles Actives',
                      value: '$totalActive',
                      subtitle: '${farmFlock.activeFlocks.length} lot(s)',
                      icon: Icons.egg_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Morts du Jour',
                      value: '$todayDead',
                      subtitle: 'Pertes déclarées',
                      icon: Icons.trending_down_rounded,
                      color: todayDead > 0
                          ? AppColors.alertCritical
                          : AppColors.alertSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                title: 'Alertes Sanitaires Ouvertes',
                value: '$openAlerts',
                subtitle: openAlerts > 0
                    ? 'Attention requise (RM8/RM9)'
                    : 'Aucun risque détecté',
                icon: Icons.notifications_active_outlined,
                color: openAlerts > 0
                    ? AppColors.alertWarning
                    : AppColors.alertSuccess,
                onTap: () {
                  // Switch or push to alerts
                },
              ),
              const SizedBox(height: 24),

              // Raccourcis d'actions rapides
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: 'Déclarer\nMortalité',
                      icon: Icons.remove_circle_outline,
                      color: AppColors.alertCritical,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRouter.addMortalityRoute),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      label: 'Relevé\nAmbiance',
                      icon: Icons.thermostat_outlined,
                      color: AppColors.secondary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRouter.addMonitoringRoute),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      label: 'Nouveau\nLot',
                      icon: Icons.add_business_outlined,
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRouter.addFlockRoute),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mes Lots Actifs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes Lots en Cours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${farmFlock.activeFlocks.length} actif(s)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (farmFlock.activeFlocks.isEmpty)
                EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun lot en cours',
                  message:
                      'Commencez par créer votre premier lot de volailles.',
                  actionLabel: 'Créer un Lot',
                  onAction: () => Navigator.of(context)
                      .pushNamed(AppRouter.addFlockRoute),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: farmFlock.activeFlocks.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final flock = farmFlock.activeFlocks[index];
                    return _FlockSummaryCard(flock: flock);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlockSummaryCard extends StatelessWidget {
  final dynamic flock;
  const _FlockSummaryCard({required this.flock});

  @override
  Widget build(BuildContext context) {
    final rate = flock.mortalityRate;
    final progress = flock.initialCount > 0
        ? (flock.currentCount / flock.initialCount).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      elevation: 0.5,
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
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    flock.reference,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  StatusBadge.flockStatus(flock.status),
                ],
              ),
              if (flock.breed.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Souche : ${flock.breed}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Effectif : ${flock.currentCount} / ${flock.initialCount} sujets',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Taux perte : ${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: rate > 5.0
                          ? AppColors.alertCritical
                          : AppColors.alertSuccess,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    rate > 5.0 ? AppColors.alertCritical : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
