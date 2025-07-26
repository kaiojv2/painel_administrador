class Produto {
  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final double preco;
  final double? precoPromocional;
  final bool promocao;
  final String imagem;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.preco,
    this.precoPromocional,
    this.promocao = false,
    required this.imagem,
  });

  factory Produto.fromMap(Map<String, dynamic> map, String id) {
    return Produto(
      id: id,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      categoria: map['categoria'] ?? '',
      preco: (map['preco'] ?? 0).toDouble(),
      precoPromocional: map['precoPromocional'] != null
          ? (map['precoPromocional'] as num).toDouble()
          : null,
      promocao: map['promocao'] ?? false,
      imagem: map['imagem'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'preco': preco,
      'precoPromocional': precoPromocional,
      'promocao': promocao,
      'imagem': imagem,
    };
  }
}
