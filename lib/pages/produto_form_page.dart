import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProdutoFormPage extends StatefulWidget {
  final String? produtoId;
  final Map<String, dynamic>? produtoData;

  const ProdutoFormPage({super.key, this.produtoId, this.produtoData});

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  bool _promocao = false;
  final TextEditingController _precoPromocionalController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _categoriaController;

  File? _imagemFile;
  String? _imagemUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoriaController = TextEditingController(
      text: widget.produtoData?['categoria'] ?? '',
    );
    _nomeController = TextEditingController(
      text: widget.produtoData?['nome'] ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.produtoData?['descricao'] ?? '',
    );

    // Aqui convertemos o preço (int em centavos) para double em reais e formatamos
    if (widget.produtoData?['preco'] != null) {
      final precoCentavos = widget.produtoData!['preco'] as int;
      final precoReais = precoCentavos / 100;
      _precoController =
          TextEditingController(text: precoReais.toStringAsFixed(2));
    } else {
      _precoController = TextEditingController(text: '');
    }

    _promocao = widget.produtoData?['promocao'] ?? false;

    // Preço promocional também em centavos -> reais
    if (widget.produtoData?['precoPromocional'] != null) {
      final precoPromoCentavos = widget.produtoData!['precoPromocional'] as int;
      final precoPromoReais = precoPromoCentavos / 100;
      _precoPromocionalController.text = precoPromoReais.toStringAsFixed(2);
    }

    _imagemUrl = widget.produtoData?['imagem'];
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _precoPromocionalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imagemFile = File(picked.path);
        _imagemUrl = null;
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final ref =
          FirebaseStorage.instance.ref().child('produtos').child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Erro upload imagem: $e');
      return null;
    }
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? imagemUrl = _imagemUrl;
      if (_imagemFile != null) {
        final uploadedUrl = await _uploadImage(_imagemFile!);
        if (uploadedUrl != null) {
          imagemUrl = uploadedUrl;
        }
      }

      // Aqui convertemos de string (ex: "15.00") para int em centavos (ex: 1500)
      final precoDouble = double.parse(_precoController.text.trim());
      final precoCentavos = (precoDouble * 100).round();

      int? precoPromocionalCentavos;
      if (_promocao) {
        final precoPromoDouble =
            double.tryParse(_precoPromocionalController.text.trim());
        if (precoPromoDouble != null) {
          precoPromocionalCentavos = (precoPromoDouble * 100).round();
        }
      }

      final produtoData = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'preco': precoCentavos, // salva em centavos (int)
        'imagem': imagemUrl ?? '',
        'categoria': _categoriaController.text.trim(),
        'promocao': _promocao,
        'precoPromocional':
            precoPromocionalCentavos, // salva em centavos ou null
      };

      if (widget.produtoId != null) {
        await FirebaseFirestore.instance
            .collection('produtos')
            .doc(widget.produtoId)
            .update(produtoData);
      } else {
        await FirebaseFirestore.instance
            .collection('produtos')
            .add(produtoData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto salvo com sucesso')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar produto: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.produtoId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Produto' : 'Novo Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imagemFile != null
                    ? Image.file(
                        _imagemFile!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      )
                    : (_imagemUrl != null && _imagemUrl!.isNotEmpty)
                        ? Image.network(
                            _imagemUrl!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Categoria é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço (ex: 12.99)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Preço é obrigatório';
                  }
                  final preco = double.tryParse(value);
                  if (preco == null || preco < 0) {
                    return 'Informe um preço válido';
                  }
                  return null;
                },
                onEditingComplete: () {
                  final preco = double.tryParse(_precoController.text.trim());
                  if (preco != null) {
                    _precoController.text = preco.toStringAsFixed(2);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _promocao,
                    onChanged: (val) {
                      setState(() {
                        _promocao = val ?? false;
                        if (!_promocao) {
                          _precoPromocionalController.clear();
                        }
                      });
                    },
                  ),
                  const Text('Produto em promoção?'),
                ],
              ),
              if (_promocao)
                TextFormField(
                  controller: _precoPromocionalController,
                  decoration: const InputDecoration(
                    labelText: 'Preço promocional',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (_promocao) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o preço promocional';
                      }
                      final precoPromo = double.tryParse(value);
                      final precoNormal = double.tryParse(
                        _precoController.text,
                      );
                      if (precoPromo == null) {
                        return 'Informe um preço válido';
                      }
                      if (precoNormal != null && precoPromo >= precoNormal) {
                        return 'Preço promocional deve ser menor que o preço normal';
                      }
                    }
                    return null;
                  },
                  onEditingComplete: () {
                    final precoPromo = double.tryParse(
                      _precoPromocionalController.text.trim(),
                    );
                    if (precoPromo != null) {
                      _precoPromocionalController.text =
                          precoPromo.toStringAsFixed(2);
                    }
                  },
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarProduto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Salvar Alterações' : 'Cadastrar Produto',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
