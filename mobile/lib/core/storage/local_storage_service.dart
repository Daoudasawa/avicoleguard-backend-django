import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  // Noms des boîtes Hive pour le stockage local
  static const String farmsBox = 'farms_cache';
  static const String flocksBox = 'flocks_cache';
  static const String mortalitiesBox = 'mortalities_cache';
  static const String monitoringsBox = 'monitorings_cache';
  static const String observationsBox = 'observations_cache';
  static const String ticketsBox = 'tickets_cache';
  static const String syncQueueBox = 'offline_sync_queue';
  static const String settingsBox = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Ouverture des boîtes nécessaires au mode hors-ligne
    await Hive.openBox<Map>(farmsBox);
    await Hive.openBox<Map>(flocksBox);
    await Hive.openBox<Map>(mortalitiesBox);
    await Hive.openBox<Map>(monitoringsBox);
    await Hive.openBox<Map>(observationsBox);
    await Hive.openBox<Map>(ticketsBox);
    await Hive.openBox<Map>(syncQueueBox);
    await Hive.openBox<dynamic>(settingsBox);
  }

  // Accesseurs typés
  static Box<Map> getFarmsBox() => Hive.box<Map>(farmsBox);
  static Box<Map> getFlocksBox() => Hive.box<Map>(flocksBox);
  static Box<Map> getMortalitiesBox() => Hive.box<Map>(mortalitiesBox);
  static Box<Map> getMonitoringsBox() => Hive.box<Map>(monitoringsBox);
  static Box<Map> getObservationsBox() => Hive.box<Map>(observationsBox);
  static Box<Map> getTicketsBox() => Hive.box<Map>(ticketsBox);
  static Box<Map> getSyncQueueBox() => Hive.box<Map>(syncQueueBox);
  static Box<dynamic> getSettingsBox() => Hive.box<dynamic>(settingsBox);

  // Sauvegarde de l'horodatage de dernière synchronisation (pour /sync/pull/)
  static Future<void> saveLastSyncTimestamp(String isoTimestamp) async {
    final box = getSettingsBox();
    await box.put('last_sync_timestamp', isoTimestamp);
  }

  static String? getLastSyncTimestamp() {
    final box = getSettingsBox();
    return box.get('last_sync_timestamp') as String?;
  }

  static Future<void> clearCache() async {
    await getFarmsBox().clear();
    await getFlocksBox().clear();
    await getMortalitiesBox().clear();
    await getMonitoringsBox().clear();
    await getObservationsBox().clear();
    await getSyncQueueBox().clear();
  }
}
