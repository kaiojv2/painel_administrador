import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseConfigService {
  static const _configFileName = 'firebase_config.json';

  /// Salva o JSON localmente (você pode chamar isso ao mudar os dados)
  static Future<void> salvarConfiguracaoFirebase(
      Map<String, dynamic> config) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_configFileName');
    await file.writeAsString(json.encode(config));
  }

  /// Verifica se o JSON de configuração já existe
  static Future<bool> existeConfiguracaoFirebase() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_configFileName');
    return await file.exists();
  }

  /// Lê o JSON salvo localmente e inicializa o Firebase
  static Future<void> inicializarFirebaseDinamicamente() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_configFileName');
    print('Arquivo salvo em: ${dir.path}/firebase_config.json');

    // Evita reinicialização
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    if (!file.existsSync()) {
      throw Exception('Arquivo firebase_config.json não encontrado.');
    }

    final jsonString = await file.readAsString();
    final config = json.decode(jsonString);

    final firebaseOptions = FirebaseOptions(
      apiKey: config['apiKey'],
      appId: config['appId'],
      messagingSenderId:
          config['messagingSenderId'] ?? '', // precisa ter, mesmo que vazio
      projectId: config['projectId'],
      storageBucket: config['storageBucket'],
      // REMOVIDO messagingSenderId e authDomain, pois não usados no seu caso
    );

    await Firebase.initializeApp(options: firebaseOptions);
  }
}
