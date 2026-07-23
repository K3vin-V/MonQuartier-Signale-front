import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/auth_service.dart';
import 'user_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _modeInscription = false;
  bool _enCours = false;
  String? _erreur;

  Future<void> _connexionEmailMdp() async {
    setState(() { _enCours = true; _erreur = null; });
    final auth = context.read<AuthService>();
    final erreur = _modeInscription
        ? await auth.register(_emailCtrl.text, _passwordCtrl.text)
        : await auth.login(_emailCtrl.text, _passwordCtrl.text);
    setState(() => _enCours = false);
    if (erreur != null) {
      setState(() => _erreur = erreur);
      return;
    }
    _redirigerSelonRole();
  }

  Future<void> _connexionGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // annulé par l'utilisateur
      setState(() => _enCours = true);
      // Le backend recrée/retrouve le compte à partir de l'id Google + email.
      final erreur = await context.read<AuthService>().loginOAuthGoogle(
        googleUser.id, googleUser.email,
      );
      setState(() => _enCours = false);
      if (erreur != null) {
        setState(() => _erreur = erreur);
        return;
      }
      _redirigerSelonRole();
    } catch (e) {
      setState(() { _enCours = false; _erreur = 'Connexion Google impossible.'; });
    }
  }

  Future<void> _connexionApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      setState(() => _enCours = true);
      final erreur = await context.read<AuthService>().loginOAuthApple(
        credential.userIdentifier ?? '',
        credential.email ?? _emailCtrl.text,
      );
      setState(() => _enCours = false);
      if (erreur != null) {
        setState(() => _erreur = erreur);
        return;
      }
      _redirigerSelonRole();
    } catch (e) {
      setState(() { _enCours = false; _erreur = 'Connexion Apple impossible.'; });
    }
  }

  void _redirigerSelonRole() {
    final user = context.read<AuthService>().user;
    if (!mounted || user == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.isAdmin ? const AdminDashboardScreen() : const UserDashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modeInscription ? 'Créer un compte' : 'Connexion')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enCours ? null : _connexionEmailMdp,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _enCours
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_modeInscription ? 'Créer mon compte' : 'Se connecter'),
                ),
                TextButton(
                  onPressed: () => setState(() => _modeInscription = !_modeInscription),
                  child: Text(_modeInscription
                      ? 'J\'ai déjà un compte'
                      : 'Pas encore de compte ? Créer un compte'),
                ),
                const SizedBox(height: 12),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ou')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _enCours ? null : _connexionGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continuer avec Google'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _enCours ? null : _connexionApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continuer avec Apple'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
