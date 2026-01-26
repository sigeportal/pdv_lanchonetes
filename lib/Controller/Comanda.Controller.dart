import 'package:lanchonete/Models/comanda_model.dart';
import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Services/ComandaService.dart';
import 'package:flutter/cupertino.dart';

class ComandaController extends ChangeNotifier {
  List<Itens> itens = [];

  // CORREÇÃO: Cálculo do total considerando Quantidade x Valor Unitário
  double get valorComanda {
    double soma = 0;
    for (var element in itens) {
      // Soma valor do item * quantidade
      soma += (element.valor! * (element.quantidade ?? 1));

      // Soma valor dos complementos (se houver)
      if (element.complementos != null && element.complementos!.isNotEmpty) {
        double totalComplementos = element.complementos!
            .map((e) => e.valor * e.quantidade)
            .fold(0.0, (a, b) => a + b);
        soma += totalComplementos;
      }
    }
    return soma;
  }

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

  // LÓGICA DE SOMAR QUANTIDADE
  void adicionaItem(Produtos produto, String idAgrupamento,
      {GradeProduto? gradeProduto,
      double quantidade = 1.0,
      required int usuario}) {
    // Procura se já existe um item com o mesmo Código e mesmo Agrupamento (Grade)
    int index = itens.indexWhere((item) =>
        item.produto == produto.codigo && item.idAgrupamento == idAgrupamento);

    if (index != -1) {
      // SE JÁ EXISTE: Apenas incrementa a quantidade
      itens[index].quantidade = (itens[index].quantidade ?? 0) + quantidade;
    } else {
      // SE NÃO EXISTE: Cria uma nova linha na lista
      itens.add(
        Itens(
            codigo: itens.length + 1,
            produto: produto.codigo,
            quantidade: quantidade,
            valor: produto.valor, // Mantém o Valor Unitário
            nome: produto.nome,
            grade: produto.grade,
            gradeProduto: gradeProduto,
            usuario: usuario,
            idAgrupamento: (gradeProduto != null) ? idAgrupamento : '',
            complementos: []),
      );
    }
    notifyListeners();
  }

  void clear() {
    itens.clear();
    notifyListeners();
  }

  void removeItem(int? codProduto) {
    itens.removeWhere((e) => e.produto == codProduto);
    notifyListeners();
  }

  void removeItemCarrinho(Itens item) {
    if (item.gradeProduto != null) {
      itens.removeWhere((e) => e.idAgrupamento == item.idAgrupamento);
    } else {
      // Remove o objeto específico da lista
      itens.remove(item);
    }
    notifyListeners();
  }

  void diminuirQuantidade(int? codigo) {
    // Encontra o item (preferencialmente o último adicionado ou pelo index)
    // Para simplificar, pega o primeiro que encontrar desse produto
    var index = itens.indexWhere((e) => e.produto == codigo);

    if (index != -1) {
      var item = itens[index];
      if ((item.quantidade ?? 0) > 1) {
        item.quantidade = item.quantidade! - 1.0;
      } else {
        // Se chegar a 1 e diminuir, remove o item
        itens.removeAt(index);
      }
      // OBS: Não alteramos mais o 'item.valor' aqui para preservar o valor unitário
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
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].obs = obs;
      notifyListeners();
    }
  }

  void adicionaComplementos(int? codItem, List<Complementos> complementos) {
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].complementos = complementos;
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
}
