import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/empty_state_widget.dart';

class AssistanceListScreen extends StatefulWidget {
  const AssistanceListScreen({super.key});

  @override
  State<AssistanceListScreen> createState() => _AssistanceListScreenState();
}

class _AssistanceListScreenState extends State<AssistanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistanceProvider>().refresh();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'closed':
        return 'Clos';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assistance Vétérinaire'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AssistanceProvider>().refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRouter.createTicketRoute),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
        backgroundColor: AppColors.primary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.tickets.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.support_agent,
                  title: 'Aucune demande d\'assistance',
                  message:
                      'Créez une demande pour contacter un vétérinaire ou un technicien.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.tickets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final t = provider.tickets[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.ticketDetailRoute,
                          arguments: t,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(t.status).withAlpha(30),
                          child: Icon(
                            Icons.support_agent,
                            color: _statusColor(t.status),
                          ),
                        ),
                        title: Text(
                          t.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(t.status).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(t.status),
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(t.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
