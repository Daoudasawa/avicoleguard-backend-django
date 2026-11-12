import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/alerts/data/models/alert_model.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/providers/alert_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/empty_state_widget.dart';
import 'package:avicoleguard_mobile/shared/widgets/status_badge.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = alertProvider.alerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Alertes Sanitaires',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => alertProvider.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Avertissement réglementaire RM9 obligatoire
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryDark.withAlpha(20),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AlertModel.rm9Disclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: alerts.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Situation Sanitaire Saine',
                    message:
                        'Aucune alerte active détectée sur vos lots actuellement.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final dateFormatted = DateFormat('dd/MM/yyyy HH:mm')
                          .format(alert.createdAt);

                      return InkWell(
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.alertDetailRoute,
                          arguments: alert,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: alert.isCritical
                                  ? AppColors.alertCritical.withAlpha(120)
                                  : AppColors.divider,
                              width: alert.isCritical ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge.alertLevel(alert.level),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  alert.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (alert.flockReference != null) ...[
                                  Text(
                                    'Lot concerné : ${alert.flockReference}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline,
                                        size: 16,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Règle déclenchée [${alert.ruleCode}]. Touchez pour voir les recommandations détaillées.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // US-ALERT-002 — Bouton d'acquittement pour alertes ouvertes
                                if (alert.isOpen) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final provider =
                                            context.read<AlertProvider>();
                                        final ok = await provider
                                            .acknowledgeAlert(alert.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(ok
                                                  ? 'Alerte acquittée.'
                                                  : 'Échec de l\'acquittement.'),
                                              backgroundColor: ok
                                                  ? AppColors.alertSuccess
                                                  : AppColors.alertCritical,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 18),
                                      label:
                                          const Text('Acquitter cette alerte'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                            color: AppColors.primary),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                    ),
                                  ),
                                ] else if (alert.status == 'acknowledged') ...[
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 14,
                                          color: AppColors.alertSuccess),
                                      SizedBox(width: 6),
                                      Text(
                                        'Acquittée',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.alertSuccess,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
