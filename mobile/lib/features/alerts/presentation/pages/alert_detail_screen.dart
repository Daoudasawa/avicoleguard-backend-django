import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/alerts/data/models/alert_model.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/providers/alert_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/status_badge.dart';

/// US-ALERT-002 — Écran de détail d'une alerte sanitaire.
/// Affiche les recommandations automatiques (RM9) et permet l'acquittement.
class AlertDetailScreen extends StatelessWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  Color get _levelColor {
    switch (alert.level) {
      case 'critique':
        return AppColors.alertCritical;
      case 'preoccupant':
        return AppColors.alertWarning;
      case 'attention':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de l\'Alerte'),
        backgroundColor: _levelColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── En-tête ─────────────────────────────────────────────────────
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge.alertLevel(alert.level),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(alert.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (alert.flockReference != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lot : ${alert.flockReference}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Règle déclenchée : ${alert.ruleCode}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Recommandation automatique (RM9) ────────────────────────────
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Recommandation automatique',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    Text(
                      _getRecommendationText(),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    // RM9 — Mention obligatoire : signal, pas un diagnostic
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.alertWarning.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.alertWarning.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 16, color: AppColors.alertWarning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AlertModel.rm9Disclaimer,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.alertWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Actions ─────────────────────────────────────────────────────
            if (alert.isOpen) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final provider = context.read<AlertProvider>();
                    final ok = await provider.acknowledgeAlert(alert.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Alerte acquittée.'
                              : 'Échec de l\'acquittement réseau.'),
                          backgroundColor: ok
                              ? AppColors.alertSuccess
                              : AppColors.alertCritical,
                        ),
                      );
                      if (ok) Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Acquitter l\'alerte',
                      style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.alertSuccess.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.alertSuccess, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alerte acquittée — aucune action supplémentaire requise.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.alertSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// RM9 — Recommandations contextualisées selon la règle déclenchée.
  String _getRecommendationText() {
    switch (alert.ruleCode) {
      case 'mortality_threshold':
        return 'Le taux de mortalité de ce lot dépasse le seuil configuré. '
            'Vérifiez l\'abreuvement, la ventilation et l\'alimentation. '
            'Inspectez les oiseaux faibles et isolez-les si nécessaire.';
      case 'water_consumption_drop':
        return 'Une baisse significative de la consommation d\'eau a été détectée. '
            'Vérifiez les abreuvoirs (obstruction, température de l\'eau). '
            'Une déshydratation peut s\'installer rapidement.';
      case 'feed_consumption_drop':
        return 'La consommation d\'aliment a chuté. '
            'Vérifiez la qualité de l\'aliment, les mangeoires et l\'état général du troupeau.';
      case 'respiratory_observations':
        return 'Des observations respiratoires répétées ont été signalées. '
            'Vérifiez la ventilation et la densité du bâtiment. '
            'Un contact avec un vétérinaire est recommandé.';
      default:
        return 'Des indicateurs anormaux ont été détectés sur ce lot. '
            'Surveillez l\'abreuvement, l\'ambiance du bâtiment et l\'état général des animaux. '
            'En cas de doute, contactez un professionnel de santé animale.';
    }
  }
}
