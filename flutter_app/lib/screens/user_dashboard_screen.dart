import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/signalement.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/statut_badge.dart';
import 'home_screen.dart';
import 'signalement_form_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final _api = ApiService();
  late Future<List<Signalement>> _futureSignalements;
  int _notificationsNonLues = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    final token = context.read<AuthService>().token!;
    _futureSignalements = _api.mesSignalements(token);
    _api.notificationsNonLues(token).then((n) {
      if (mounted) setState(() => _notificationsNonLues = n);
    });
  }

  void _ouvrirNotifications() {
    // Cahier des charges : signalements dont le statut a changé depuis la
    // dernière connexion, ou en attente de complément. On les liste depuis
    // les signalements marqués "statutVuParUser = false".
    _futureSignalements.then((liste) {
      final aSuivre = liste.where((s) => !s.statutVuParUser).toList();
      showModalBottomSheet(
        context: context,
        builder: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            if (aSuivre.isEmpty) const Text('Rien de nouveau.'),
            ...aSuivre.map((s) => ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: Text(s.titre),
              subtitle: Text('Nouveau statut : ${s.statut.libelle}'),
            )),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes signalements'),
        actions: [
          IconButton(
            tooltip: 'Créer un signalement',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Scaffold(
                  body: SafeArea(
                    child: SignalementFormScreen(
                      emailUtilisateurConnecte: user?.email,
                      embarque: true,
                      afficherEntete: false,
                      onAnnuler: () => Navigator.pop(context),
                    ),
                  ),
                )),
              );
              setState(_charger);
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _ouvrirNotifications,
              ),
              if (_notificationsNonLues > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_notificationsNonLues',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().deconnexion();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Signalement>>(
        future: _futureSignalements,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final signalements = snapshot.data!;
          if (signalements.isEmpty) {
            return const Center(child: Text('Vous n\'avez pas encore fait de signalement.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: signalements.length,
            itemBuilder: (context, i) {
              final s = signalements[i];
              return Card(
                child: ListTile(
                  title: Text(s.titre),
                  subtitle: Text('${s.adresse}\n${s.type}'),
                  isThreeLine: true,
                  trailing: StatutBadge(statut: s.statut),
                  onTap: () => _ouvrirDetail(s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _ouvrirDetail(Signalement s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _DetailSignalementScreen(signalement: s)));
  }
}

/// Détail d'un signalement + fil de commentaires (ajout possible par le citoyen).
class _DetailSignalementScreen extends StatefulWidget {
  const _DetailSignalementScreen({required this.signalement});
  final Signalement signalement;

  @override
  State<_DetailSignalementScreen> createState() => _DetailSignalementScreenState();
}

class _DetailSignalementScreenState extends State<_DetailSignalementScreen> {
  final _api = ApiService();
  final _commentaireCtrl = TextEditingController();
  late Future<List<Commentaire>> _futureCommentaires;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    final token = context.read<AuthService>().token!;
    _futureCommentaires = _api.commentaires(token, widget.signalement.id);
  }

  Future<void> _envoyerCommentaire() async {
    if (_commentaireCtrl.text.trim().isEmpty) return;
    final token = context.read<AuthService>().token!;
    await _api.ajouterCommentaire(token, widget.signalement.id, _commentaireCtrl.text.trim());
    _commentaireCtrl.clear();
    setState(_charger);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.signalement;
    return Scaffold(
      appBar: AppBar(title: Text(s.titre)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(s.adresse)),
                StatutBadge(statut: s.statut),
              ],
            ),
          ),
          if (s.statut == StatutSignalement.refuse && s.commentaireRefus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Motif du refus : ${s.commentaireRefus}',
                  style: const TextStyle(color: Colors.red)),
            ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Commentaire>>(
              future: _futureCommentaires,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final commentaires = snapshot.data!;
                if (commentaires.isEmpty) {
                  return const Center(child: Text('Aucun commentaire pour le moment.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: commentaires.length,
                  itemBuilder: (context, i) {
                    final c = commentaires[i];
                    final estMairie = c.auteurType == 'mairie';
                    return Align(
                      alignment: estMairie ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: estMairie ? Colors.grey.shade200 : Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(estMairie ? 'Mairie' : 'Vous',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(c.contenu),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentaireCtrl,
                    decoration: const InputDecoration(hintText: 'Ajouter un commentaire...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _envoyerCommentaire),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
