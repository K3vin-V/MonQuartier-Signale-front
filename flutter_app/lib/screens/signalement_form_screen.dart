import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SignalementFormScreen extends StatefulWidget {
  const SignalementFormScreen({
    super.key,
    this.emailUtilisateurConnecte,
    this.embarque = false,
    this.onAnnuler,
  });

  /// Si l'utilisateur est connecté, son email est pré-rempli (cahier des charges).
  final String? emailUtilisateurConnecte;

  /// true = affiché sans son propre AppBar/Scaffold, intégré dans une autre page
  /// (ex: HomeScreen qui bascule entre menu et formulaire sans changer de page).
  final bool embarque;

  /// Appelé quand l'utilisateur annule, uniquement utile en mode embarqué.
  final VoidCallback? onAnnuler;

  @override
  State<SignalementFormScreen> createState() => _SignalementFormScreenState();
}

class _SignalementFormScreenState extends State<SignalementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late final TextEditingController _emailCtrl;
  final _titreCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _autrePrecisionCtrl = TextEditingController();

  String _type = 'voirie';
  XFile? _photo;
  String? _erreurAdresse;
  bool _envoiEnCours = false;
  bool _succesAffiche = false;

  final _now = DateTime.now();

  static const _types = {
    'voirie': 'Voirie',
    'transport': 'Transport',
    'incivilite': 'Incivilité',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.emailUtilisateurConnecte ?? '');
  }

  Future<void> _choisirPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _soumettre() async {
    setState(() {
      _erreurAdresse = null;
      _succesAffiche = false;
    });
    if (!_formKey.currentState!.validate() || _photo == null) {
      if (_photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La photo est obligatoire.')),
        );
      }
      return;
    }

    setState(() => _envoiEnCours = true);
    try {
      final response = await _api.creerSignalement(
        email: _emailCtrl.text,
        titre: _titreCtrl.text,
        type: _type,
        typeAutrePrecision: _type == 'autre' ? _autrePrecisionCtrl.text : null,
        adresse: _adresseCtrl.text,
        photo: _photo!,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          // Remise à zéro complète du formulaire pour un nouveau signalement.
          _titreCtrl.clear();
          _adresseCtrl.clear();
          _autrePrecisionCtrl.clear();
          if (widget.emailUtilisateurConnecte == null) {
            _emailCtrl.clear(); // sinon on garde l'email pré-rempli de l'utilisateur connecté
          }
          _formKey.currentState!.reset();
          setState(() {
            _photo = null;
            _type = 'voirie';
            _erreurAdresse = null;
            _succesAffiche = true;
          });
        }
      } else {
        final body = jsonDecode(await response.stream.bytesToString());
        // Le backend renvoie une erreur explicite si l'adresse n'est pas dans
        // le périmètre de la commune (règle obligatoire du cahier des charges).
        setState(() => _erreurAdresse = body['message'] ?? 'Adresse invalide.');
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatee = DateFormat('dd/MM/yyyy à HH:mm').format(_now);

    // En plein écran (pas embarqué), l'en-tête est plus compact pour éviter
    // d'avoir besoin de scroller juste pour voir le formulaire.
    final tailleLogo = widget.embarque ? 72.0 : 48.0;

    final formulaire = Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, widget.embarque ? 16 : 4, 16, 16),
        children: [
          // Même en-tête que la page d'accueil (logo + titre), demandé pour
          // garder une identité visuelle cohérente sur le formulaire.
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/MonQuartier-Signale-logo-2.png', height: 150),
                const SizedBox(height: 6),
                Text(
                  'Signalements à Crosne',
                  style: widget.embarque
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (widget.embarque) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Signalez un problème sur Crosne (avec ou sans compte)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: widget.embarque ? 24 : 8),
          if (widget.embarque)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onAnnuler,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ),
          if (_succesAffiche) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Signalement bien enregistré, merci !',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.green.shade700, size: 18),
                    onPressed: () => setState(() => _succesAffiche = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email *'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titreCtrl,
            decoration: const InputDecoration(labelText: 'Titre du signalement *'),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type de signalement *'),
            items: _types.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          if (_type == 'autre') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _autrePrecisionCtrl,
              decoration: const InputDecoration(labelText: 'Précisez *'),
              validator: (v) {
                if (_type != 'autre') return null;
                return (v == null || v.isEmpty) ? 'Précision obligatoire' : null;
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _adresseCtrl,
            decoration: InputDecoration(
              labelText: 'Adresse postale *',
              errorText: _erreurAdresse,
              helperText: 'Doit être une adresse à Crosne',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _choisirPhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(_photo == null ? 'Ajouter une photo *' : 'Photo sélectionnée ✓'),
          ),
          const SizedBox(height: 16),
          // Date & heure pré-remplies et non modifiables, comme demandé.
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Date et heure'),
            child: Text(dateFormatee),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _envoiEnCours ? null : _soumettre,
            child: _envoiEnCours
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );

    if (widget.embarque) return formulaire;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau signalement')),
      body: formulaire,
    );
  }
}
