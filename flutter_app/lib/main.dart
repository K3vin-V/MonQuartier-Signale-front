import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() => runApp(const SignalementApp());

class SignalementApp extends StatelessWidget {
  const SignalementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..restaurerSession(),
      child: MaterialApp(
        title: 'Signalements à Crosne',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, 
                         useMaterial3: true,
                         scaffoldBackgroundColor: Colors.white,
                        ),
        home: const _SplashAndRoute(),
      ),
    );
  }
}

/// Point d'entrée réel de l'app (cahier des charges : la page d'accueil
/// permet de s'authentifier OU de créer un signalement). Si une session est
/// déjà restaurée (utilisateur reconnu), on saute directement à son espace.
class _SplashAndRoute extends StatelessWidget {
  const _SplashAndRoute();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isConnecte) return const HomeScreen();
        return auth.user!.isAdmin
            ? const AdminDashboardScreen()
            : const UserDashboardScreen();
      },
    );
  }
}
