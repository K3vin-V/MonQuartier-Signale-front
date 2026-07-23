import 'package:flutter/material.dart';
import '../models/signalement.dart';

class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut});
  final StatutSignalement statut;

  Color get _couleur => switch (statut) {
    StatutSignalement.cree => Colors.grey,
    StatutSignalement.enAttenteModeration => Colors.orange,
    StatutSignalement.enAttenteTraitement => Colors.blue,
    StatutSignalement.traitementEnCours => Colors.indigo,
    StatutSignalement.confirmationAttendue => Colors.purple,
    StatutSignalement.termine => Colors.green,
    StatutSignalement.refuse => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _couleur.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
      ),
      child: Text(
        statut.libelle,
        style: TextStyle(color: _couleur, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
