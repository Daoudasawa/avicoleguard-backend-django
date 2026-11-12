import 'package:flutter/material.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/pages/register_screen.dart';
import 'package:avicoleguard_mobile/features/auth/presentation/pages/splash_screen.dart';
import 'package:avicoleguard_mobile/features/flocks/data/models/flock_model.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/pages/add_flock_screen.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/pages/flock_detail_screen.dart';
import 'package:avicoleguard_mobile/features/home/presentation/pages/main_screen.dart';
import 'package:avicoleguard_mobile/features/monitoring/presentation/pages/add_monitoring_screen.dart';
import 'package:avicoleguard_mobile/features/mortality/presentation/pages/add_mortality_screen.dart';
import 'package:avicoleguard_mobile/features/observations/presentation/pages/add_observation_screen.dart';
import 'package:avicoleguard_mobile/features/alerts/data/models/alert_model.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/pages/alert_detail_screen.dart';
import 'package:avicoleguard_mobile/features/assistance/data/models/ticket_model.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/pages/assistance_list_screen.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/pages/create_ticket_screen.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/pages/ticket_detail_screen.dart';

class AppRouter {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String flockDetailRoute = '/flock-detail';
  static const String addMortalityRoute = '/add-mortality';
  static const String addMonitoringRoute = '/add-monitoring';
  static const String addObservationRoute = '/add-observation';
  static const String addFlockRoute = '/add-flock';
  static const String alertDetailRoute = '/alert-detail';
  static const String assistanceRoute = '/assistance';
  static const String createTicketRoute = '/create-ticket';
  static const String ticketDetailRoute = '/ticket-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case flockDetailRoute:
        final flock = settings.arguments as FlockModel;
        return MaterialPageRoute(
          builder: (_) => FlockDetailScreen(flock: flock),
        );

      case addMortalityRoute:
        final initialFlock = settings.arguments as FlockModel?;
        return MaterialPageRoute(
          builder: (_) => AddMortalityScreen(initialFlock: initialFlock),
        );

      case addMonitoringRoute:
        final initialFlock = settings.arguments as FlockModel?;
        return MaterialPageRoute(
          builder: (_) => AddMonitoringScreen(initialFlock: initialFlock),
        );

      case addObservationRoute:
        final flock = settings.arguments as FlockModel;
        return MaterialPageRoute(
          builder: (_) => AddObservationScreen(flock: flock),
        );

      case addFlockRoute:
        return MaterialPageRoute(builder: (_) => const AddFlockScreen());

      case alertDetailRoute:
        final alert = settings.arguments as AlertModel;
        return MaterialPageRoute(
          builder: (_) => AlertDetailScreen(alert: alert),
        );

      case assistanceRoute:
        return MaterialPageRoute(builder: (_) => const AssistanceListScreen());

      case createTicketRoute:
        return MaterialPageRoute(builder: (_) => const CreateTicketScreen());

      case ticketDetailRoute:
        final ticket = settings.arguments as TicketModel;
        return MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticket: ticket),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page non trouvée')),
            body: Center(
              child: Text('Aucune route définie pour ${settings.name}'),
            ),
          ),
        );
    }
  }
}
