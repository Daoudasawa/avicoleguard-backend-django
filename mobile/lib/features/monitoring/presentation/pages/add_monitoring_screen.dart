import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/monitoring/data/models/monitoring_model.dart';
import 'package:avicoleguard_mobile/shared/widgets/custom_text_field.dart';

class AddMonitoringScreen extends StatefulWidget {
  final FlockModel? initialFlock;
  const AddMonitoringScreen({super.key, this.initialFlock});

  @override
  State<AddMonitoringScreen> createState() => _AddMonitoringScreenState();
}

class _AddMonitoringScreenState extends State<AddMonitoringScreen> {
  final _formKey = GlobalKey<FormState>();
  FlockModel? _selectedFlock;
  DateTime _selectedDate = DateTime.now();

  final _temperatureController = TextEditingController();
  final _waterController = TextEditingController();
  final _feedController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedFlock = widget.initialFlock;
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _waterController.dispose();
    _feedController.dispose();
    _weightController.dispose();
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

    setState(() => _isSubmitting = true);

    try {
      final clientUuid = const Uuid().v4();
      final monitoring = DailyMonitoringModel(
        id: clientUuid,
        flockId: _selectedFlock!.id,
        date: _selectedDate,
        temperature: double.tryParse(_temperatureController.text.trim()),
        waterConsumption: double.tryParse(_waterController.text.trim()),
        feedConsumption: double.tryParse(_feedController.text.trim()),
        averageWeight: double.tryParse(_weightController.text.trim()),
        clientUuid: clientUuid,
        syncStatus: 'pending',
      );

      // Sauvegarde locale Hive
      await LocalStorageService.getMonitoringsBox().put(
        monitoring.id,
        monitoring.toJson(),
      );

      // Ajout dans la file sync offline
      await LocalStorageService.getSyncQueueBox().put(clientUuid, {
        'type': 'record_monitoring',
        'payload': monitoring.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relevé journalier enregistré avec succès !'),
            backgroundColor: AppColors.alertSuccess,
          ),
        );
        Navigator.of(context).pop();
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
        title: const Text('Relevé d\'Ambiance & Suivi'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lot & Date
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
                        'Lot de volailles *',
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
                            child: Text('${f.reference} (${f.currentCount} sujets)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedFlock = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Date du relevé *',
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
                                  size: 18, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mesures environnementales & consommations
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
                        'Paramètres Environnementaux & Nutrition',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _temperatureController,
                        label: 'Température du bâtiment (°C)',
                        hint: 'ex: 31.5',
                        prefixIcon: Icons.thermostat_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _waterController,
                        label: 'Consommation d\'eau (Litres)',
                        hint: 'ex: 120.0',
                        prefixIcon: Icons.water_drop_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _feedController,
                        label: 'Consommation d\'aliment (Kg)',
                        hint: 'ex: 85.5',
                        prefixIcon: Icons.grass_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _weightController,
                        label: 'Poids moyen constaté (Grammes)',
                        hint: 'ex: 450.0',
                        prefixIcon: Icons.scale_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                  backgroundColor: AppColors.secondary,
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
                        'Enregistrer le Relevé',
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
