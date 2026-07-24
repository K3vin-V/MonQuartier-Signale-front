import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/signalement.dart';

/// URL du backend. En build, injecter la vraie valeur via :
/// flutter build web --dart-define=API_BASE_URL=https://api-signal.evenement-vyvs.fr/api
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api-signal.evenement-vyvs.fr/api',
);

class ApiService {
  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<http.StreamedResponse> creerSignalement({
    required String email,
    required String titre,
    required String type,
    String? typeAutrePrecision,
    required String adresse,
    required XFile photo,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/signalements');
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = email
      ..fields['titre'] = titre
      ..fields['type'] = type
      ..fields['adresse'] = adresse;

    if (typeAutrePrecision != null) {
      request.fields['typeAutrePrecision'] = typeAutrePrecision;
    }
    if (bearerToken != null) {
      request.headers['Authorization'] = 'Bearer $bearerToken';
    }

    // fromBytes plutôt que fromPath : fromPath utilise dart:io, absent sur
    // Flutter Web. XFile.readAsBytes() fonctionne sur toutes les plateformes.
    final bytes = await photo.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: photo.name,
    ));

    return request.send();
  }

  // ---- Espace utilisateur standard ----

  Future<List<Signalement>> mesSignalements(String token) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/signalements/mes-signalements'),
      headers: _headers(token),
    );
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Signalement.fromJson(e)).toList();
  }

  Future<List<Commentaire>> commentaires(String token, String signalementId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/signalements/$signalementId/commentaires'),
      headers: _headers(token),
    );
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Commentaire.fromJson(e)).toList();
  }

  Future<void> ajouterCommentaire(String token, String signalementId, String contenu) async {
    await http.post(
      Uri.parse('$apiBaseUrl/signalements/$signalementId/commentaires'),
      headers: _headers(token),
      body: jsonEncode({'contenu': contenu}),
    );
  }

  Future<int> notificationsNonLues(String token) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/notifications/non-lues'),
      headers: _headers(token),
    );
    final list = jsonDecode(res.body) as List;
    return list.length;
  }

  // ---- Espace super administrateur ----

  Future<Map<String, dynamic>> kpis(String token) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/admin/kpis'), headers: _headers(token));
    return jsonDecode(res.body);
  }

  Future<List<Signalement>> signalementsParStatuts(String token, List<String> statuts) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/signalements?statuts=${statuts.join(',')}'),
      headers: _headers(token),
    );
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Signalement.fromJson(e)).toList();
  }

  Future<void> changerStatut(String token, String id, String statut, {String? commentaire}) async {
    await http.patch(
      Uri.parse('$apiBaseUrl/signalements/$id/statut'),
      headers: _headers(token),
      body: jsonEncode({'statut': statut, if (commentaire != null) 'commentaire': commentaire}),
    );
  }

  Future<void> supprimerSignalement(String token, String id) async {
    await http.delete(
      Uri.parse('$apiBaseUrl/signalements/$id'),
      headers: _headers(token),
    );
  }
}
