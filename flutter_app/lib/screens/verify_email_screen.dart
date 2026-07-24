import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});

  final String token;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _api = ApiService();
  bool _enCours = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    final erreur = await _api.verifierEmail(widget.token);
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _erreur = erreur;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/MonQuartier-Signale-logo-2.png', height: 160),
                  const SizedBox(height: 32),
                  if (_enCours) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Vérification en cours...'),
                  ] else if (_erreur == null) ...[
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Adresse email vérifiée avec succès !',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                      child: const Text('Se connecter'),
                    ),
                  ] else ...[
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _erreur!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ce lien a peut-être déjà été utilisé, ou a expiré.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
