import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/farms/data/models/farm_model.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/shared/widgets/custom_text_field.dart';

class AddFlockScreen extends StatefulWidget {
  const AddFlockScreen({super.key});

  @override
  State<AddFlockScreen> createState() => _AddFlockScreenState();
}

class _AddFlockScreenState extends State<AddFlockScreen> {
  final _formKey = GlobalKey<FormState>();
  FarmModel? _selectedFarm;
  final _referenceController = TextEditingController();
  final _breedController = TextEditingController();
  final _initialCountController = TextEditingController();
  DateTime _arrivalDate = DateTime.now();
  String _selectedSex = 'mixed';
  bool _isSubmitting = false;

  final List<String> _commonBreeds = [
    'Cobb 500',
    'Ross 308',
    'Goliath',
    'Sasso',
    'Poulet Bicyclette (Local)',
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    _breedController.dispose();
    _initialCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _arrivalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() => _arrivalDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final farmFlock = context.read<FarmFlockProvider>();

    // If no farm, create a default farm first
    String targetFarmId;
    if (_selectedFarm == null) {
      final defaultFarm = await farmFlock.addFarm(
        name: 'Ferme Principale',
        locationText: 'Site principal',
      );
      if (!mounted) return;
      if (defaultFarm == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Impossible de créer la ferme parente.')),
        );
        return;
      }
      targetFarmId = defaultFarm.id;
    } else {
      targetFarmId = _selectedFarm!.id;
    }

    final initialCount =
        int.tryParse(_initialCountController.text.trim()) ?? 0;

    if (initialCount <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('L\'effectif initial doit être supérieur à 0.'),
          backgroundColor: AppColors.alertCritical,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final flock = await farmFlock.addFlock(
        farmId: targetFarmId,
        reference: _referenceController.text.trim(),
        initialCount: initialCount,
        breed: _breedController.text.trim(),
        sex: _selectedSex,
        arrivalDate: _arrivalDate,
      );

      if (flock != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lot "${flock.reference}" créé avec succès !'),
            backgroundColor: AppColors.alertSuccess,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
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
    final farms = context.watch<FarmFlockProvider>().farms;
    if (_selectedFarm == null && farms.isNotEmpty) {
      _selectedFarm = farms.first;
    }

    final dateFormatted = DateFormat('dd/MM/yyyy').format(_arrivalDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau Lot de Volailles'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        'Ferme d\'hébergement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (farms.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aucune ferme configurée. Une ferme par défaut sera créée automatiquement.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<FarmModel>(
                          initialValue: _selectedFarm,
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
                          items: farms.map((f) {
                            return DropdownMenuItem<FarmModel>(
                              value: f,
                              child: Text(f.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedFarm = val);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Caractéristiques du lot
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
                        'Caractéristiques du Lot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _referenceController,
                        label: 'Référence du lot *',
                        hint: 'ex: LOT-2026-CHAIR-01',
                        prefixIcon: Icons.tag,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _initialCountController,
                        label: 'Effectif de départ (Nombre de poussins) *',
                        hint: 'ex: 500',
                        prefixIcon: Icons.pets,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Doit être un nombre entier > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Date de mise en place *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 14),
                      const Text(
                        'Souche / Race',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _commonBreeds.map((breed) {
                          final isSelected = _breedController.text == breed;
                          return ChoiceChip(
                            label: Text(breed,
                                style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (sel) {
                              setState(() {
                                _breedController.text = sel ? breed : '';
                              });
                            },
                            selectedColor: AppColors.primary.withAlpha(30),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _breedController,
                        label: 'Ou préciser une autre souche',
                        hint: 'ex: Kuroiler',
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sexe',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'mixed', label: Text('Mixte')),
                          ButtonSegment(value: 'female', label: Text('Femelle')),
                          ButtonSegment(value: 'male', label: Text('Mâle')),
                        ],
                        selected: {_selectedSex},
                        onSelectionChanged: (set) {
                          setState(() => _selectedSex = set.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Créer
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
                        'Créer le Lot',
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
