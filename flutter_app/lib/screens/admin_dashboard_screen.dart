import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/signalement.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/statut_badge.dart';
import '../widgets/kpi_card.dart';
import 'home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  late Future<Map<String, dynamic>> _futureKpis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  void _charger() {
    final token = context.read<AuthService>().token!;
    _futureKpis = _api.kpis(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration - Signalements'),
        actions: [
          IconButton(
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À modérer'),
            Tab(text: 'En traitement'),
            Tab(text: 'Traités / refusés'),
          ],
        ),
      ),
      body: Column(
        children: [
          _ZoneKpi(future: _futureKpis),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TableauSignalements(
                  statuts: const ['en_attente_moderation'],
                  actionsModerationVisibles: true,
                  onChange: () => setState(_charger),
                ),
                _TableauSignalements(
                  statuts: const ['en_attente_traitement', 'traitement_en_cours', 'confirmation_attendue'],
                  actionsModerationVisibles: false,
                  onChange: () => setState(_charger),
                ),
                _TableauSignalements(
                  statuts: const ['termine', 'refuse'],
                  actionsModerationVisibles: false,
                  onChange: () => setState(_charger),
                  lectureSeuleSeulement: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneKpi extends StatelessWidget {
  const _ZoneKpi({required this.future});
  final Future<Map<String, dynamic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final crees = data['signalementsCrees'];
        final moderes = data['signalementsModeres'];
        final traites = data['signalementsTraites'];
        final termineRefuse = data['repartitionTermineRefuse'];
        final globale = data['repartitionGlobale'];

        return Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cartes = [
                KpiCard(titre: 'Signalements créés', jour: crees['jour'], semaine: crees['semaine'], mois: crees['mois']),
                KpiCard(titre: 'Signalements modérés', jour: moderes['jour'], semaine: moderes['semaine'], mois: moderes['mois']),
                KpiCard(titre: 'Signalements traités', jour: traites['jour'], semaine: traites['semaine'], mois: traites['mois']),
              ];
              final graphs = [
                _GraphiqueCamembert(
                  titre: 'Terminés vs Refusés',
                  valeurs: {
                    'Terminés': (termineRefuse['termine'] as int).toDouble(),
                    'Refusés': (termineRefuse['refuse'] as int).toDouble(),
                  },
                  couleurs: const [Colors.green, Colors.red],
                ),
                _GraphiqueCamembert(
                  titre: 'Répartition globale',
                  valeurs: {
                    'À modérer': (globale['aModerer'] as int).toDouble(),
                    'En traitement': (globale['enTraitement'] as int).toDouble(),
                  },
                  couleurs: const [Colors.orange, Colors.indigo],
                ),
              ];

              // Écran large : KPI + graphiques sur une seule ligne. Les
              // cartes KPI (plus de contenu texte) reçoivent plus de place
              // (flex 3) que les graphiques, plus compacts (flex 2).
              if (constraints.maxWidth > 1100) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...cartes.map((c) => Expanded(
                            flex: 3,
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c),
                          )),
                      ...graphs.map((g) => Expanded(
                            flex: 2,
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: g),
                          )),
                    ],
                  ),
                );
              }

              // Écran moyen : deux lignes séparées (KPI puis graphiques).
              if (constraints.maxWidth > 700) {
                return Column(
                  children: [
                    Row(children: cartes.map((c) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList()),
                    const SizedBox(height: 12),
                    Row(children: graphs.map((g) => Expanded(child: g)).toList()),
                  ],
                );
              }

              // Écran étroit : tout empilé verticalement.
              return Column(children: [...cartes, ...graphs]);
            },
          ),
        );
      },
    );
  }
}

class _GraphiqueCamembert extends StatelessWidget {
  const _GraphiqueCamembert({required this.titre, required this.valeurs, required this.couleurs});
  final String titre;
  final Map<String, double> valeurs;
  final List<Color> couleurs;

  @override
  Widget build(BuildContext context) {
    final total = valeurs.values.fold<double>(0, (a, b) => a + b);
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: total == 0
                  ? const Center(child: Text('Aucune donnée'))
                  : PieChart(PieChartData(
                      sections: [
                        for (var i = 0; i < valeurs.length; i++)
                          PieChartSectionData(
                            value: valeurs.values.elementAt(i),
                            color: couleurs[i % couleurs.length],
                            title: total > 0
                                ? '${(valeurs.values.elementAt(i) / total * 100).round()}%'
                                : '',
                            radius: 50,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                      ],
                      sectionsSpace: 2,
                    )),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (var i = 0; i < valeurs.length; i++)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, color: couleurs[i % couleurs.length]),
                    const SizedBox(width: 4),
                    Text(valeurs.keys.elementAt(i), style: const TextStyle(fontSize: 12)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableauSignalements extends StatefulWidget {
  const _TableauSignalements({
    required this.statuts,
    required this.actionsModerationVisibles,
    required this.onChange,
    this.lectureSeuleSeulement = false,
  });

  final List<String> statuts;
  final bool actionsModerationVisibles;
  final bool lectureSeuleSeulement;
  final VoidCallback onChange;

  @override
  State<_TableauSignalements> createState() => _TableauSignalementsState();
}

class _TableauSignalementsState extends State<_TableauSignalements> {
  final _api = ApiService();
  late Future<List<Signalement>> _future;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    final token = context.read<AuthService>().token!;
    _future = _api.signalementsParStatuts(token, widget.statuts);
  }

  Future<void> _changerStatut(Signalement s, String nouveauStatut) async {
    final token = context.read<AuthService>().token!;

    // Règle obligatoire : "Refusé" exige un commentaire, quel que soit le
    // statut de départ.
    String? commentaire;
    if (nouveauStatut == 'refuse') {
      commentaire = await showDialog<String>(
        context: context,
        builder: (_) => _DialogueMotifRefus(),
      );
      if (commentaire == null || commentaire.trim().isEmpty) return; // annulé
    }

    await _api.changerStatut(token, s.id, nouveauStatut, commentaire: commentaire);
    setState(_charger);
    widget.onChange();
  }

  Future<void> _supprimer(Signalement s) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce signalement ?'),
        content: Text(
          'Cette action est définitive : "${s.titre}" et ses commentaires '
          'seront supprimés. Le ticket Zammad associé n\'est pas affecté.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    final token = context.read<AuthService>().token!;
    await _api.supprimerSignalement(token, s.id);
    setState(_charger);
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Signalement>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final liste = snapshot.data!;
        if (liste.isEmpty) return const Center(child: Text('Aucun signalement.'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Titre')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Adresse')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Actions')),
            ],
            rows: liste.map((s) => DataRow(cells: [
              DataCell(Text(s.titre)),
              DataCell(Text(s.type)),
              DataCell(Text(s.adresse, overflow: TextOverflow.ellipsis)),
              DataCell(Text(s.email)),
              DataCell(StatutBadge(statut: s.statut)),
              DataCell(widget.lectureSeuleSeulement
                  ? Row(children: [
                      IconButton(
                        tooltip: 'Remettre en modération',
                        icon: const Icon(Icons.undo, color: Colors.orange),
                        onPressed: () => _changerStatut(s, 'en_attente_moderation'),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _supprimer(s),
                      ),
                    ])
                  : Row(children: [
                      if (widget.actionsModerationVisibles) ...[
                        IconButton(
                          tooltip: 'Valider (passer en attente de traitement)',
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onPressed: () => _changerStatut(s, 'en_attente_traitement'),
                        ),
                      ] else ...[
                        PopupMenuButton<String>(
                          tooltip: 'Changer le statut',
                          onSelected: (v) => _changerStatut(s, v),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'traitement_en_cours', child: Text('Traitement en cours')),
                            PopupMenuItem(value: 'confirmation_attendue', child: Text('Confirmation attendue')),
                            PopupMenuItem(value: 'termine', child: Text('Terminé')),
                          ],
                        ),
                      ],
                      // "Refusé" accessible depuis n'importe quel statut,
                      // comme demandé dans le cahier des charges.
                      IconButton(
                        tooltip: 'Refuser',
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        onPressed: () => _changerStatut(s, 'refuse'),
                      ),
                    ])),
            ])).toList(),
          ),
        );
      },
    );
  }
}

class _DialogueMotifRefus extends StatefulWidget {
  @override
  State<_DialogueMotifRefus> createState() => _DialogueMotifRefusState();
}

class _DialogueMotifRefusState extends State<_DialogueMotifRefus> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motif du refus'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(hintText: 'Commentaire obligatoire'),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Refuser'),
        ),
      ],
    );
  }
}
