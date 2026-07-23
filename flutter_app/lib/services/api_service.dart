import 'dart:io';
import 'package:http/http.dart' as http;

/// URL du backend. En build, injecter la vraie valeur via :
/// flutter build web --dart-define=API_BASE_URL=https://api-signal.evenement-vyvs.fr/api
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api-signal.evenement-vyvs.fr/api',
);

class ApiService {
  Future<http.StreamedResponse> creerSignalement({
    required String email,
    required String titre,
    required String type,
    String? typeAutrePrecision,
    required String adresse,
    required File photo,
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
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    return request.send();
  }
}
