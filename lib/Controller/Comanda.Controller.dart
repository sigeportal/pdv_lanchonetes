import 'package:lanchonete/Models/comanda_model.dart';
import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Services/ComandaService.dart';
import 'package:lanchonete/Services/VendaService.dart';
import 'package:flutter/cupertino.dart';

class ComandaController extends ChangeNotifier {
  List<Itens> itens = [];

  // Cálculo do total
  double get valorComanda {
    double somaTotal = 0.0;

    for (var item in itens) {
      double valorItemBase = (item.valor ?? 0.0).toDouble();
      double valorAdicionais = 0.0;

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var comp in item.complementos!) {
          double valComp = (comp.valor).toDouble();
          double qtdComp = (comp.quantidade ?? 0).toDouble();
          valorAdicionais += (valComp * qtdComp);
        }
      }

      double quantidadeItem = (item.quantidade ?? 1.0).toDouble();
      double valorUnitarioCheio = valorItemBase + valorAdicionais;

      somaTotal += (valorUnitarioCheio * quantidadeItem);
    }

    return somaTotal;
  }

  // Retorna a quantidade total de um produto específico (para mostrar no badge do grid)
  double getQuantidade(int produto) {
    double quantidade = 0;
    for (var element in itens) {
      if (element.produto == produto) {
        quantidade += element.quantidade!;
      }
    }
    return quantidade;
  }

  int get totalItens => itens.length;
  bool get isEmpty => itens.isEmpty;

  // MODIFICADO: Adiciona sempre uma NOVA LINHA, sem somar quantidade
  void adicionaItem(Produtos produto, String idAgrupamento,
      {GradeProduto? gradeProduto,
      double quantidade = 1.0,
      required int usuario}) {
    // Removida a lógica de "indexWhere" que buscava item existente.
    // Agora sempre adiciona um novo item na lista.

    itens.add(
      Itens(
          // Gera um código único baseado no timestamp para garantir unicidade na lista
          codigo: DateTime.now().millisecondsSinceEpoch,
          produto: produto.codigo,
          quantidade: quantidade,
          valor: produto.valor,
          nome: produto.nome,
          grade: produto.grade,
          gradeProduto: gradeProduto,
          usuario: usuario,
          idAgrupamento: (gradeProduto != null) ? idAgrupamento : '',
          complementos: []),
    );

    notifyListeners();
  }

  void clear() {
    itens.clear();
    notifyListeners();
  }

  // Remove todas as ocorrências de um produto (usado pelos botões de - no catálogo)
  void removeItem(int? codProduto) {
    // Remove a última ocorrência encontrada para dar sensação de "desempilhar" visualmente
    var index = itens.lastIndexWhere((e) => e.produto == codProduto);
    if (index != -1) {
      itens.removeAt(index);
      notifyListeners();
    }
  }

  // MODIFICADO: Remove a linha específica clicada no carrinho
  void removeItemCarrinho(Itens item) {
    // Remove pela referência do objeto, garantindo que apague apenas a linha clicada
    itens.remove(item);
    notifyListeners();
  }

  void diminuirQuantidade(int? codigo) {
    // Encontra o último item adicionado desse produto
    var index = itens.lastIndexWhere((e) => e.produto == codigo);

    if (index != -1) {
      var item = itens[index];
      if ((item.quantidade ?? 0) > 1) {
        item.quantidade = item.quantidade! - 1.0;
      } else {
        // Se a quantidade for 1, remove a linha
        itens.removeAt(index);
      }
    }
    notifyListeners();
  }

  Future<bool> insereComanda(int? mesa) async {
    final comandaService = ComandaService();
    var resultado = false;
    try {
      var comanda = Comanda();
      comanda.mesa = mesa;
      comanda.valor = valorComanda;
      comanda.itens = [...itens];

      var comandaExistente = await comandaService.fetchComanda(mesa);
      if (comandaExistente.itens == null || comandaExistente.itens!.isEmpty) {
        resultado = await comandaService.criaComanda(comanda);
      } else {
        resultado = await comandaService.atualizarComanda(comanda);
      }

      if (resultado) {
        clear();
      }
      return resultado;
    } catch (e) {
      throw Exception(e);
    }
  }

  void adicionaObservacao(int? codItem, String obs) {
    // Busca pelo código único gerado no adicionaItem
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].obs = obs;
      notifyListeners();
    }
  }

  void adicionaComplementos(int? codItem, List<Complementos> complementos) {
    // Busca pelo código único gerado no adicionaItem
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].complementos = List.from(complementos);
      notifyListeners();
    }
  }

  Future<bool> deletarItemComanda(int codigo) async {
    final comandaService = ComandaService();
    try {
      final result = await comandaService.deletarItemComanda(codigo);
      notifyListeners();
      return result;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Comanda> buscaComanda(int codigo) async {
    final comandaService = ComandaService();
    try {
      final result = await comandaService.fetchComanda(codigo);
      notifyListeners();
      return result;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> inserirVenda(
      Map<String, dynamic> vendaData) async {
    final vendaService = VendaService();
    try {
      final resultado = await vendaService.inserirVenda(vendaData);
      clear();
      notifyListeners();
      return resultado;
    } catch (e) {
      throw Exception('Erro ao inserir venda: $e');
    }
  }
}
