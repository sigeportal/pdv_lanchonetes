import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';

class Itens {
  int? codigo;
  int? produto;
  double? valor;
  double? quantidade;
  String? estado;
  String? obs;
  String? nome;
  int? grade;
  int? codGrupo;
  List<Complementos>? complementos;
  List<OpcaoNivel>? opcoesNiveis;
  int? id;
  GradeProduto? gradeProduto;
  int? usuario;
  String? idAgrupamento;

  Itens(
      {this.id,
      this.produto,
      this.valor,
      this.quantidade,
      this.estado,
      this.obs,
      this.nome,
      this.complementos,
      this.opcoesNiveis,
      this.codigo,
      this.grade,
      this.codGrupo,
      this.gradeProduto,
      this.usuario,
      this.idAgrupamento}) {
    if (this.complementos == null) {
      this.complementos = <Complementos>[];
    }
    if (this.opcoesNiveis == null) {
      this.opcoesNiveis = <OpcaoNivel>[];
    }
  }

  factory Itens.fromJson(Map<String, dynamic> json) {
    return Itens(
      codigo: json['cpCodigo'] ?? 0,
      produto: json['cpPro'] ?? 0,
      estado: json['cpEstado'] ?? '',
      valor: json['cpValor'] * 100 / 100 ?? 0,
      quantidade: json['cpQuantidade'] * 100 / 100 ?? 0,
      obs: json['cpObs'] ?? '',
      grade: json['cpGra'] ?? 0,
      nome: json['nome'] ?? '',
      gradeProduto: json['cpGra'] != 0
          ? GradeProduto.fromMap(json['gradeProduto'])
          : GradeProduto(codigo: 0, valor: 0, tamanho: ''),
      complementos: (json['complementos'] as List)
          .map((e) => Complementos.fromJson(e))
          .toList(),
      opcoesNiveis: (json['opcoesNivel'] as List)
          .map((e) => OpcaoNivel.fromJson(e))
          .toList(),
      usuario: json['usuario'],
      idAgrupamento: json['idAgrupamento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "codigo": codigo,
      "produto": produto,
      "estado": estado,
      "valor": valor,
      "quantidade": quantidade,
      "obs": obs,
      "grade": grade,
      "codGrupo": codGrupo,
      "nome": nome,
      "gradeProduto": gradeProduto != null ? gradeProduto!.toJson() : null,
      "complementos": complementos != null
          ? complementos!.map((c) => c.toJson()).toList()
          : null,
      "opcoesNivel": opcoesNiveis != null
          ? opcoesNiveis!.map((c) => c.toJson()).toList()
          : null,
      "usuario": usuario,
      "idAgrupamento": idAgrupamento,
    };
  }
}
