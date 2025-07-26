import 'package:flutter/material.dart';
import 'services/firebase_config_service.dart';
import 'pages/produto_list_page.dart';
import 'pages/firebase_config_page.dart'; // Importe a tela de configuração
import 'widgets/restart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configurado = await FirebaseConfigService.existeConfiguracaoFirebase();

  if (configurado) {
    await FirebaseConfigService.inicializarFirebaseDinamicamente();
  }

  runApp(
    RestartWidget(
      child: MyApp(firebaseConfigurado: configurado),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseConfigurado;

  const MyApp({super.key, required this.firebaseConfigurado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Produtos',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: firebaseConfigurado
          ? const ProdutoListPage()
          : const FirebaseConfigPage(),
    );
  }
}
