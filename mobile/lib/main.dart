import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/app/router/app_router.dart';
import 'package:avicoleguard_mobile/core/constants/app_theme.dart';
import 'package:avicoleguard_mobile/core/storage/local_storage_service.dart';
import 'package:avicoleguard_mobile/features/alerts/data/repositories/alert_repository.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/providers/alert_provider.dart';
import 'package:avicoleguard_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/pages/splash_screen.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avicoleguard_mobile/features/flocks/data/repositories/farm_flock_repository.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/providers/farm_flock_provider.dart';
import 'package:avicoleguard_mobile/features/mortality/data/repositories/mortality_repository.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/providers/mortality_provider.dart';
import 'package:avicoleguard_mobile/features/observations/data/repositories/observation_repository.dart';
import 'package:avicoleguard_mobile/features/observations/presentation/providers/observation_provider.dart';
import 'package:avicoleguard_mobile/core/services/sync_service.dart';
import 'package:avicoleguard_mobile/features/assistance/data/repositories/assistance_repository.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  SyncService().startAutoSync();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => FarmFlockProvider(FarmFlockRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => MortalityProvider(MortalityRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(AlertRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ObservationProvider(ObservationRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AssistanceProvider(AssistanceRepository()),
        ),
        ChangeNotifierProvider.value(
          value: SyncService(),
        ),
      ],
      child: MaterialApp(
        title: 'AvicoleGuard',
        theme: AppTheme.lightTheme,
        initialRoute: SplashScreen.routeName,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
