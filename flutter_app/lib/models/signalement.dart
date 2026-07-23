enum StatutSignalement {
  cree,
  enAttenteModeration,
  enAttenteTraitement,
  traitementEnCours,
  confirmationAttendue,
  termine,
  refuse;

  static StatutSignalement fromApi(String v) {
    switch (v) {
      case 'cree': return StatutSignalement.cree;
      case 'en_attente_moderation': return StatutSignalement.enAttenteModeration;
      case 'en_attente_traitement': return StatutSignalement.enAttenteTraitement;
      case 'traitement_en_cours': return StatutSignalement.traitementEnCours;
      case 'confirmation_attendue': return StatutSignalement.confirmationAttendue;
      case 'termine': return StatutSignalement.termine;
      case 'refuse': return StatutSignalement.refuse;
      default: return StatutSignalement.cree;
    }
  }

  String get apiValue => switch (this) {
    StatutSignalement.cree => 'cree',
    StatutSignalement.enAttenteModeration => 'en_attente_moderation',
    StatutSignalement.enAttenteTraitement => 'en_attente_traitement',
    StatutSignalement.traitementEnCours => 'traitement_en_cours',
    StatutSignalement.confirmationAttendue => 'confirmation_attendue',
    StatutSignalement.termine => 'termine',
    StatutSignalement.refuse => 'refuse',
  };

  String get libelle => switch (this) {
    StatutSignalement.cree => 'Créé',
    StatutSignalement.enAttenteModeration => 'En attente de modération',
    StatutSignalement.enAttenteTraitement => 'En attente de traitement',
    StatutSignalement.traitementEnCours => 'Traitement en cours',
    StatutSignalement.confirmationAttendue => 'Confirmation attendue',
    StatutSignalement.termine => 'Terminé',
    StatutSignalement.refuse => 'Refusé',
  };
}

class Signalement {
  final String id;
  final String email;
  final String titre;
  final String type;
  final String? typeAutrePrecision;
  final String adresse;
  final String photoUrl;
  final StatutSignalement statut;
  final String? commentaireRefus;
  final bool statutVuParUser;
  final DateTime createdAt;

  Signalement({
    required this.id,
    required this.email,
    required this.titre,
    required this.type,
    this.typeAutrePrecision,
    required this.adresse,
    required this.photoUrl,
    required this.statut,
    this.commentaireRefus,
    required this.statutVuParUser,
    required this.createdAt,
  });

  factory Signalement.fromJson(Map<String, dynamic> j) => Signalement(
    id: j['id'],
    email: j['email'],
    titre: j['titre'],
    type: j['type'],
    typeAutrePrecision: j['typeAutrePrecision'],
    adresse: j['adresse'],
    photoUrl: j['photoUrl'] ?? j['photo_url'] ?? '',
    statut: StatutSignalement.fromApi(j['statut']),
    commentaireRefus: j['commentaireRefus'],
    statutVuParUser: j['statutVuParUser'] ?? true,
    createdAt: DateTime.parse(j['createdAt'] ?? j['created_at']),
  );
}

class Commentaire {
  final String id;
  final String contenu;
  final String auteurType; // 'citoyen' | 'mairie' | 'systeme'
  final DateTime createdAt;

  Commentaire({
    required this.id,
    required this.contenu,
    required this.auteurType,
    required this.createdAt,
  });

  factory Commentaire.fromJson(Map<String, dynamic> j) => Commentaire(
    id: j['id'],
    contenu: j['contenu'],
    auteurType: j['auteurType'] ?? j['auteur_type'],
    createdAt: DateTime.parse(j['createdAt'] ?? j['created_at']),
  );
}
