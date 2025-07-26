import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/firebase_config_service.dart';
import '../widgets/restart_widget.dart'; // seu RestartWidget personalizado

class FirebaseConfigPage extends StatefulWidget {
  const FirebaseConfigPage({super.key});

  @override
  State<FirebaseConfigPage> createState() => _FirebaseConfigPageState();
}

class _FirebaseConfigPageState extends State<FirebaseConfigPage> {
  final _formKey = GlobalKey<FormState>();

  final _apiKeyController = TextEditingController();
  final _appIdController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _storageBucketController = TextEditingController();

  bool _loading = true;

  // Map para controlar visibilidade dos campos (pode manter ou remover se não quiser ocultar)
  final Map<String, bool> _obscureMap = {
    'apiKey': true,
    'appId': true,
    'projectId': true,
    'storageBucket': true,
  };

  @override
  void initState() {
    super.initState();
    _carregarConfiguracaoAtual();
  }

  Future<void> _carregarConfiguracaoAtual() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/firebase_config.json');

    if (file.existsSync()) {
      final jsonString = await file.readAsString();
      final config = json.decode(jsonString);

      _apiKeyController.text = config['apiKey'] ?? '';
      _appIdController.text = config['appId'] ?? '';
      _projectIdController.text = config['projectId'] ?? '';
      _storageBucketController.text = config['storageBucket'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _salvarConfiguracao() async {
    if (!_formKey.currentState!.validate()) return;

    final config = {
      'apiKey': _apiKeyController.text.trim(),
      'appId': _appIdController.text.trim(),
      'projectId': _projectIdController.text.trim(),
      'storageBucket': _storageBucketController.text.trim(),
    };

    try {
      await FirebaseConfigService.salvarConfiguracaoFirebase(config);
      await FirebaseConfigService.inicializarFirebaseDinamicamente();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuração salva e Firebase inicializado!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reinicia o app pelo RestartWidget
      await Future.delayed(const Duration(milliseconds: 800));
      RestartWidget.restartApp(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar ou inicializar Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String keyName,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscureMap[keyName] ?? false,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            (_obscureMap[keyName] ?? false)
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureMap[keyName] = !(_obscureMap[keyName] ?? false);
            });
          },
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Obrigatório' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Firebase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(
                  controller: _apiKeyController,
                  label: 'API Key',
                  keyName: 'apiKey'),
              _buildField(
                  controller: _appIdController,
                  label: 'App ID',
                  keyName: 'appId'),
              _buildField(
                  controller: _projectIdController,
                  label: 'Project ID',
                  keyName: 'projectId'),
              _buildField(
                  controller: _storageBucketController,
                  label: 'Storage Bucket',
                  keyName: 'storageBucket'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarConfiguracao,
                child: const Text('Salvar Configuração'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
