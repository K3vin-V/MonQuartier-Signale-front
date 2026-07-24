import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/verify_email_screen.dart';

void main() => runApp(const SignalementApp());

class SignalementApp extends StatelessWidget {
  const SignalementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..restaurerSession(),
      child: MaterialApp(
        title: 'Signalements Crosne',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
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
///
/// Gère aussi le lien de vérification d'email reçu par mail
/// (https://.../#/verifier-email?token=...) : si ce token est présent dans
/// l'URL au chargement, on affiche l'écran de confirmation à la place du
/// flux normal.
class _SplashAndRoute extends StatelessWidget {
  const _SplashAndRoute();

  /// Extrait le paramètre `token` depuis le fragment d'URL (#/...), utilisé
  /// par défaut en Flutter Web pour le routage sans configuration serveur
  /// particulière.
  String? get _tokenVerificationEmail {
    final fragment = Uri.base.fragment; // ex: "/verifier-email?token=abc123"
    if (!fragment.startsWith('/verifier-email')) return null;
    final indexQuery = fragment.indexOf('?');
    if (indexQuery == -1) return null;
    final params = Uri.splitQueryString(fragment.substring(indexQuery + 1));
    return params['token'];
  }

  @override
  Widget build(BuildContext context) {
    final token = _tokenVerificationEmail;
    if (token != null) {
      return VerifyEmailScreen(token: token);
    }

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
