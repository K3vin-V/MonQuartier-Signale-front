import 'package:flutter/material.dart';
import 'signalement_form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _formulaireOuvert = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              // AnimatedSwitcher évite un changement de page complet : on
              // reste sur le même écran, seul le contenu central change.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _formulaireOuvert ? _buildFormulaire() : _buildMenu(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Column(
      key: const ValueKey('menu'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/MonQuartier-Signale-logo-2.png', height: 200),
        const SizedBox(height: 16),
        Text(
          'Signalements Crosne',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Signalez un problème sur la commune, avec ou sans compte.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),

        // Cahier des charges : le formulaire est accessible SANS être
        // connecté ni avoir de compte. Ici, il s'affiche à la place de ce
        // menu, sur le même écran, sans navigation vers une nouvelle page.
        FilledButton.icon(
          onPressed: () => setState(() => _formulaireOuvert = true),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Créer un signalement'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          icon: const Icon(Icons.login),
          label: const Text('Se connecter / créer un compte'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Se connecter permet de suivre vos signalements et '
          'd\'être notifié de leur avancement.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFormulaire() {
    return SizedBox(
      key: const ValueKey('formulaire'),
      height: 682, // +10% par rapport à la valeur initiale (620)
      child: SignalementFormScreen(
        embarque: true,
        onAnnuler: () => setState(() => _formulaireOuvert = false),
      ),
    );
  }
}
