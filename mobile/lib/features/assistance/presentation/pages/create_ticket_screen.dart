import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFlockId;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un lot.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<AssistanceProvider>();

    final ticket = await provider.createTicket(
      flockId: _selectedFlockId!,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    if (ticket != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Demande d\'assistance créée avec succès.'),
          backgroundColor: AppColors.alertSuccess,
        ),
      );
      navigator.pop();
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors de la création.'),
          backgroundColor: AppColors.alertCritical,
        ),
      );
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeFlocks = context.watch<FarmFlockProvider>().activeFlocks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle Demande'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations du problème',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Lot concerné *',
                          border: OutlineInputBorder(),
                        ),
                        items: activeFlocks
                            .map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text('${f.reference} (${f.currentCount} vivants)'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedFlockId = v),
                        validator: (v) =>
                            v == null ? 'Veuillez sélectionner un lot' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Sujet du ticket *',
                          hintText: 'ex: Suspicion maladie respiratoire',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Le sujet est obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description détaillée *',
                          border: OutlineInputBorder(),
                          hintText:
                              'Décrivez précisément la situation, les symptômes observés, l\'évolution...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La description est obligatoire'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Envoyer la demande d\'assistance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
