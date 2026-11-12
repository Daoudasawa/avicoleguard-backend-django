import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/core/services/sync_service.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/providers/mortality_provider.dart';

class ProfileSyncScreen extends StatefulWidget {
  const ProfileSyncScreen({super.key});

  @override
  State<ProfileSyncScreen> createState() => _ProfileSyncScreenState();
}

class _ProfileSyncScreenState extends State<ProfileSyncScreen> {
  bool _isSyncing = false;

  int get _pendingCount => LocalStorageService.getSyncQueueBox().length;
  String? get _lastSync => LocalStorageService.getLastSyncTimestamp();

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);

    final messenger = ScaffoldMessenger.of(context);
    final farmFlock = context.read<FarmFlockProvider>();
    final mortality = context.read<MortalityProvider>();
    final assistance = context.read<AssistanceProvider>();

    try {
      // 1. Envoi prioritaire de toutes les opérations locales en attente (Push offline)
      await SyncService().flushSyncQueue();

      // 2. Récupération des dernières données du serveur (Pull)
      await farmFlock.refresh();
      await mortality.refresh();
      await assistance.refresh();

      // 3. Enregistrement du timestamp
      await LocalStorageService.saveLastSyncTimestamp(
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Synchronisation complète réussie !'),
            backgroundColor: AppColors.alertSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Échec partiel de la synchronisation réseau.'),
            backgroundColor: AppColors.alertCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertCritical),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await auth.logout();
      if (mounted) {
        navigator.pushReplacementNamed(AppRouter.loginRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final lastSyncFormatted = _lastSync != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(_lastSync!))
        : 'Jamais';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil & Synchronisation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Carte Profil
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withAlpha(30),
                      child: Text(
                        (user?.displayName.isNotEmpty == true)
                            ? user!.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Non renseigné',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rôle : ${user?.role.toUpperCase() ?? "ÉLEVEUR"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Carte Mode Hors-Ligne & Synchronisation
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_sync_outlined,
                            color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Synchronisation Offline-First',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SyncInfoRow(
                      label: 'En attente de synchronisation',
                      value: '$_pendingCount saisie(s)',
                      valueColor: _pendingCount > 0
                          ? AppColors.alertWarning
                          : AppColors.alertSuccess,
                    ),
                    const SizedBox(height: 10),
                    _SyncInfoRow(
                      label: 'Dernière synchronisation',
                      value: lastSyncFormatted,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _manualSync,
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync, size: 18),
                        label: Text(_isSyncing
                            ? 'Synchronisation en cours...'
                            : 'Synchroniser maintenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout,
                    size: 18, color: AppColors.alertCritical),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: AppColors.alertCritical),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.alertCritical),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SyncInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
