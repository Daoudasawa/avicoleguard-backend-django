import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/assistance/data/models/ticket_model.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistanceProvider>().loadMessages(widget.ticket.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    final ok = await context.read<AssistanceProvider>().sendMessage(
      ticketId: widget.ticket.id,
      content: content,
    );
    if (ok && mounted) _messageController.clear();
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();
    final messages = provider.currentMessages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.ticket.subject,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (widget.ticket.isOpen)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Clôturer le ticket',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clôturer ce ticket ?'),
                    content: const Text('Le problème est-il résolu ? Vous pourrez toujours consulter l\'historique des échanges.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Non'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Oui, clôturer'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final ok = await context
                      .read<AssistanceProvider>()
                      .closeTicket(widget.ticket.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket clôturé.')),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tête description du problème
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statut : ${widget.ticket.isOpen ? "En cours" : "Clos"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.ticket.isOpen ? Colors.orange : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(widget.ticket.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ticket.description,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          // Fil des échanges
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Aucune réponse pour le moment.\nUn vétérinaire ou technicien étudiera votre demande sous peu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final m = messages[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.authorName ?? 'Intervenant',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM HH:mm').format(m.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.content,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Zone de saisie d'un nouveau message
          if (widget.ticket.isOpen)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message ou une précision...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
