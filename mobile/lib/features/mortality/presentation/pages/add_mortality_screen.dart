import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/providers/mortality_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/custom_text_field.dart';

class AddMortalityScreen extends StatefulWidget {
  final FlockModel? initialFlock;

  const AddMortalityScreen({super.key, this.initialFlock});

  @override
  State<AddMortalityScreen> createState() => _AddMortalityScreenState();
}

class _AddMortalityScreenState extends State<AddMortalityScreen> {
  final _formKey = GlobalKey<FormState>();
  FlockModel? _selectedFlock;
  DateTime _selectedDate = DateTime.now();
  final _deadCountController = TextEditingController();
  final _causeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _commonCauses = [
    'Étouffement / Piquage',
    'Stress thermique (chaleur)',
    'Faiblesse / Déshydratation',
    'Signes respiratoires',
    'Cause indéterminée',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlock = widget.initialFlock;
  }

  @override
  void dispose() {
    _deadCountController.dispose();
    _causeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un lot.')),
      );
      return;
    }

    final deadCount = int.tryParse(_deadCountController.text.trim()) ?? 0;

    // Règle Métier RM1-RM4 : deadCount > 0 et <= currentCount
    if (deadCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nombre de morts doit être supérieur à 0 (RM1).'),
          backgroundColor: AppColors.alertCritical,
        ),
      );
      return;
    }

    if (deadCount > _selectedFlock!.currentCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le nombre de morts ($deadCount) ne peut pas excéder l\'effectif actuel (${_selectedFlock!.currentCount}) [RM4].',
          ),
          backgroundColor: AppColors.alertCritical,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final mortalityProvider = context.read<MortalityProvider>();
      final farmFlockProvider = context.read<FarmFlockProvider>();

      final m = await mortalityProvider.addMortality(
        flockId: _selectedFlock!.id,
        flockReference: _selectedFlock!.reference,
        date: _selectedDate,
        deadCount: deadCount,
        presumedCause: _causeController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (m != null) {
        // Met à jour l'effectif du lot localement
        farmFlockProvider.onMortalityAdded(_selectedFlock!.id, deadCount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mortalité de $deadCount sujet(s) enregistrée avec succès (Offline-First).',
              ),
              backgroundColor: AppColors.alertSuccess,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppColors.alertCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFlocks = context.watch<FarmFlockProvider>().activeFlocks;

    if (_selectedFlock == null && activeFlocks.isNotEmpty) {
      _selectedFlock = activeFlocks.first;
    }

    final dateFormatted = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Déclarer une Mortalité'),
        backgroundColor: AppColors.alertCritical,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection du lot
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lot concerné *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<FlockModel>(
                        initialValue: _selectedFlock,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.divider),
                          ),
                        ),
                        items: activeFlocks.map((f) {
                          return DropdownMenuItem<FlockModel>(
                            value: f,
                            child: Text(
                              '${f.reference} (${f.currentCount} vivants)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedFlock = val);
                        },
                      ),
                      if (_selectedFlock != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Effectif actuel restant : ${_selectedFlock!.currentCount} sujets',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
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
              ),
              const SizedBox(height: 16),

              // Date & Nombre de morts
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      const Text(
                        'Date du constat *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateFormatted,
                                  style: const TextStyle(fontSize: 14)),
                              const Icon(Icons.calendar_today,
                                  size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre de morts
                      CustomTextField(
                        controller: _deadCountController,
                        label: 'Nombre de sujets morts *',
                        hint: 'ex: 3',
                        prefixIcon: Icons.remove_circle_outline,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Veuillez saisir le nombre de morts';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Doit être un nombre entier > 0 (RM1)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Causes présumées
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cause suspectée / constatée',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _commonCauses.map((cause) {
                          final isSelected = _causeController.text == cause;
                          return ChoiceChip(
                            label: Text(cause,
                                style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (sel) {
                              setState(() {
                                _causeController.text = sel ? cause : '';
                              });
                            },
                            selectedColor:
                                AppColors.alertCritical.withAlpha(30),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _causeController,
                        label: 'Ou préciser une autre cause',
                        hint: 'ex: asphyxie nocturne',
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Observations / Notes complémentaires',
                        hint: 'Remarques sur l\'état des oiseaux, litière...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertCritical,
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
                        'Enregistrer la Déclaration',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
