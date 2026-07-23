import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.titre,
    required this.jour,
    required this.semaine,
    required this.mois,
  });

  final String titre;
  final int jour;
  final int semaine;
  final int mois;

  Widget _valeur(String label, int v) => Column(
    children: [
      Text('$v', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _valeur("Aujourd'hui", jour),
                _valeur('Cette semaine', semaine),
                _valeur('Ce mois', mois),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
