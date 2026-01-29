class Nivel {
  final int codigo;
  final String titulo;
  final String descricao;
  final int selecaoMin;
  final int selecaoMax;
  final List<OpcaoNivel> opcoes;
  final int codProduto;

  Nivel({
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.selecaoMin,
    required this.selecaoMax,
    required this.opcoes,
    required this.codProduto,
  });

  factory Nivel.fromJson(Map<String, dynamic> json) {
    return Nivel(
      codigo: json['codigo'] ?? 0,
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      selecaoMin: json['selecaoMin'] ?? 1,
      selecaoMax: json['selecaoMax'] ?? 1,
      opcoes: (json['opcoes'] as List?)
              ?.map((e) => OpcaoNivel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      codProduto: json['codProduto'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'titulo': titulo,
      'descricao': descricao,
      'selecaoMin': selecaoMin,
      'selecaoMax': selecaoMax,
      'opcoes': opcoes.map((e) => e.toJson()).toList(),
      'codProduto': codProduto,
    };
  }
}

class OpcaoNivel {
  final int codigo;
  final String nome;
  final double valorAdicional;
  final bool ativo;
  final String ativoStr;
  final int codNivel;
  bool selecionado;
  int quantidade;

  OpcaoNivel({
    required this.codigo,
    required this.nome,
    required this.valorAdicional,
    required this.ativo,
    required this.ativoStr,
    required this.codNivel,
    this.selecionado = false,
    this.quantidade = 0,
  });

  factory OpcaoNivel.fromJson(Map<String, dynamic> json) {
    return OpcaoNivel(
      codigo: json['codigo'] ?? 0,
      nome: json['nome'] ?? '',
      valorAdicional: (json['valorAdicional'] ?? 0).toDouble(),
      ativo: json['ativo'] ?? false,
      ativoStr: json['ativoStr'] ?? 'N',
      codNivel: json['codNivel'] ?? 0,
      selecionado: false,
      quantidade: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nome': nome,
      'valorAdicional': valorAdicional,
      'ativo': ativo,
      'ativoStr': ativoStr,
      'codNivel': codNivel,
      'selecionado': selecionado,
      'quantidade': quantidade,
    };
  }
}
