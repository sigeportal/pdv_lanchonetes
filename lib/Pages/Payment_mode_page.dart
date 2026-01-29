import 'package:lanchonete/Components/generic_dialog.dart';
import 'package:lanchonete/Components/payment_option_tile.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Controller/Tef/types/tef_provider.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Models/venda_model.dart';
import 'package:lanchonete/Pages/Tela_carregamento_page.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_venda.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/card_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/currency_code.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/fin_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/payment_mode.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Services/CupomFiscalService.dart';
import '../Services/PrinterService.dart';

class PaymentModePage extends StatefulWidget {
  final double valorPagamento;

  const PaymentModePage({
    Key? key,
    required this.valorPagamento,
  }) : super(key: key);

  @override
  _PaymentModePageState createState() => _PaymentModePageState();
}

class _PaymentModePageState extends State<PaymentModePage> {
  final TefController _tefController = Get.find();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String _formatPayment() {
    return "R\$ ${widget.valorPagamento.toStringAsFixed(2)}"
        .replaceAll('.', ',');
  }

  // Método para retornar o widget baseado na orientação
  Widget _buildPaymentOptions(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isHorizontal = orientation == Orientation.landscape;

    // Se for horizontal (landscape), usa GridView com 4 colunas
    if (isHorizontal) {
      return GridView.count(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: _getPaymentTiles(),
      );
    }

    // Se for vertical (portrait), usa ListView com scroll vertical
    return SingleChildScrollView(
      child: Column(
        children: _getPaymentTilesWithSpacing(),
      ),
    );
  }

  // Retorna lista de PaymentOptionTile para GridView
  List<PaymentOptionTile> _getPaymentTiles() {
    return [
      PaymentOptionTile(
        icon: Icons.monetization_on_sharp,
        title: "Dinheiro",
        subtitle: "Á Vista",
        color: Colors.blue,
        onPressed: onClickButtonDinheiro,
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Débito",
        subtitle: "Cartão de débito",
        color: Colors.blue,
        onPressed: onClickButtonDebito,
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Crédito",
        subtitle: "Cartão de crédito",
        color: Colors.green,
        onPressed: onClickButtonCredito,
      ),
      PaymentOptionTile(
        icon: Icons.card_giftcard,
        title: "Voucher",
        subtitle: "Vale alimentação ou refeição",
        color: Colors.orange,
        onPressed: onClickButtonVoucher,
      ),
      PaymentOptionTile(
        icon: Icons.account_balance,
        title: "Carteira Digital",
        subtitle: "PIX e carteiras virtuais",
        color: Colors.indigo,
        onPressed: onClickButtonCarteiraDigital,
      ),
    ];
  }

  // Retorna lista de PaymentOptionTile com espaçamento para ListView
  List<Widget> _getPaymentTilesWithSpacing() {
    final tiles = _getPaymentTiles();
    final tilesWithSpacing = <Widget>[];

    for (int i = 0; i < tiles.length; i++) {
      tilesWithSpacing.add(tiles[i]);
      if (i < tiles.length - 1) {
        tilesWithSpacing.add(const SizedBox(height: 12));
      }
    }

    return tilesWithSpacing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forma de Pagamento"),
        elevation: 0,
      ),
      body: Container(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                // Card Valor Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total a Pagar",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPayment(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Escolha a forma de pagamento",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Lista de opções de pagamento responsiva
                Expanded(
                  child: _buildPaymentOptions(context),
                ),

                const SizedBox(height: 24),

                // Botão cancelar
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: navegarParaTelaAnterior,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LÓGICA DO DINHEIRO OTIMIZADA PARA TABLET ---

  void onClickButtonDinheiro() async {
    await _exibirCalculadoraTroco();
  }

  Future<void> _exibirCalculadoraTroco() async {
    final TextEditingController _valorRecebidoController =
        TextEditingController();
    double troco = 0.0;
    List<String> sugestaoCedulas = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Usa Dialog normal para ter controle total do tamanho (width/height)
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            // Define largura baseada na tela (70% da largura em paisagem)
            width: MediaQuery.of(context).size.width * 0.7,
            // Altura máxima para não estourar, mas flexível
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 800, // Limite para telas muito grandes
            ),
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                void _calcularTroco(String value) {
                  if (value.isEmpty) {
                    setState(() {
                      troco = 0.0;
                      sugestaoCedulas = [];
                    });
                    return;
                  }
                  String cleanValue = value.replaceAll(',', '.');
                  double? recebido = double.tryParse(cleanValue);

                  if (recebido != null) {
                    setState(() {
                      troco = recebido - widget.valorPagamento;
                      if (troco > 0) {
                        sugestaoCedulas = _gerarSugestaoCedulas(troco);
                      } else {
                        sugestaoCedulas = [];
                      }
                    });
                  }
                }

                bool podeConfirmar = false;
                double? valorDigitado = double.tryParse(
                    _valorRecebidoController.text.replaceAll(',', '.'));
                if (valorDigitado != null &&
                    valorDigitado >= widget.valorPagamento - 0.01) {
                  podeConfirmar = true;
                }

                // Layout dividido em Row para aproveitar horizontalidade do Tablet
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.blue, size: 28),
                        SizedBox(width: 10),
                        Text("Calculadora de Troco",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 10),

                    // CORPO DO MODAL (Dividido em 2 colunas)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // COLUNA DA ESQUERDA (Entrada de Dados)
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Total da Venda",
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                  Text(
                                      _currencyFormat
                                          .format(widget.valorPagamento),
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800])),
                                  SizedBox(height: 30),
                                  Text("Valor Recebido do Cliente",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: _valorRecebidoController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    autofocus: true,
                                    style: TextStyle(fontSize: 20),
                                    decoration: InputDecoration(
                                      prefixText: "R\$ ",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 12),
                                      hintText: "0,00",
                                      helperText: "Digite o valor entregue",
                                    ),
                                    onChanged: _calcularTroco,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Divisória Vertical
                          Container(
                            width: 1,
                            color: Colors.grey[300],
                            margin: EdgeInsets.symmetric(horizontal: 20),
                          ),

                          // COLUNA DA DIREITA (Resultado e Sugestão)
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: troco >= 0
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: troco >= 0
                                        ? Colors.green.withOpacity(0.5)
                                        : Colors.red.withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Troco a devolver",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black54)),
                                  Text(
                                    _currencyFormat
                                        .format(troco < 0 ? 0 : troco),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: troco >= 0
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  if (sugestaoCedulas.isNotEmpty) ...[
                                    Divider(),
                                    Text("Sugestão de notas:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: sugestaoCedulas.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.money,
                                                    size: 18,
                                                    color: Colors.green[700]),
                                                SizedBox(width: 8),
                                                Text(sugestaoCedulas[index],
                                                    style: TextStyle(
                                                        fontSize: 16)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                        child: Center(
                                            child: Text("Aguardando valor...",
                                                style: TextStyle(
                                                    color: Colors.grey))))
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // RODAPÉ (Botões)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16)),
                          child: Text("Cancelar",
                              style:
                                  TextStyle(color: Colors.red, fontSize: 16)),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: podeConfirmar
                              ? () {
                                  Navigator.pop(context);
                                  _finalizarVenda('Dinheiro');
                                }
                              : null,
                          icon: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                          label: Text("Finalizar Venda",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Algoritmo para calcular notas e moedas (Greedy Algorithm)
  List<String> _gerarSugestaoCedulas(double valorTroco) {
    List<String> resultado = [];
    int centavos = (valorTroco * 100).round();

    final Map<int, String> cedulas = {
      10000: "Nota de R\$ 100,00",
      5000: "Nota de R\$ 50,00",
      2000: "Nota de R\$ 20,00",
      1000: "Nota de R\$ 10,00",
      500: "Nota de R\$ 5,00",
      200: "Nota de R\$ 2,00",
      100: "Moeda de R\$ 1,00",
      50: "Moeda de R\$ 0,50",
      25: "Moeda de R\$ 0,25",
      10: "Moeda de R\$ 0,10",
      5: "Moeda de R\$ 0,05"
    };

    for (var valor in cedulas.keys) {
      if (centavos >= valor) {
        int qtd = centavos ~/ valor;
        centavos %= valor;
        resultado.add("$qtd x ${cedulas[valor]}");
      }
    }
    return resultado;
  }

  Future<void> _finalizarVenda(String formaPagto) async {
    try {
      final comandaController =
          Provider.of<ComandaController>(context, listen: false);

      // Construir a estrutura de venda conforme o modelo correto
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      Map<String, dynamic> vendaData = {
        "Valor": comandaController.valorComanda,
        "Fun": 1, // ID do funcionário
        "Diferenca": 0,
        "Datac": formattedDate,
        "Cli": 1, // ID do cliente (padrão = 1 para consumidor)
        "Devolucao_p": "N",
        "Tipo_pedido": "Venda",
        "Taxa_entrega": 0,
        "Forma_pgto": _getFormaPagtoId(formaPagto),
        "Nome_cliente": "CONSUMIDOR",
        "Id_pedido": "PED-${formattedDate.replaceAll('-', '')}-001",
        "Itens": comandaController.itens.map((item) {
          final valorUnitario = item.valor ?? 0.0;
          final quantidade = item.quantidade ?? 1.0;
          final subtotal = valorUnitario * quantidade;

          return {
            "Valor": valorUnitario,
            "Quantidade": quantidade,
            "Pro": item.produto,
            "Lucro": 10,
            "Valorr": valorUnitario * 0.8,
            "Valorl": valorUnitario * 0.9,
            "Valorf": valorUnitario,
            "Diferenca": 0,
            "Liquido": subtotal,
            "Valor2": subtotal,
            "Valorcm": 0,
            "Aliquota": 0,
            "Gtin": "",
            "Embalagem": "PC",
            "Valorb": valorUnitario,
            "Desconto": 0,
            "Valorc": valorUnitario * 0.7,
            "Obs": item.obs ?? "",
            "Gra": item.grade ?? 0,
            "Semente_tratada": "N",
            "Valor_partida": 0,
            "Variacao": 0,
            "Usu": 1
          };
        }).toList(),
        "PedFat": {
          "Codigo": 222,
          "Data": formattedDate,
          "Tabela": "VENDAS",
          "Cod_Ped": 12345,
          "Campo_Fat": "VEN_FAT",
          "Campo_Ped": "VEN_CODIGO",
          "Cliente": "CONSUMIDOR",
          "Valor": comandaController.valorComanda,
          "ValorPG": comandaController.valorComanda,
          "Cod_Cli": 1,
          "FUN": 1,
          "Parcelas": 1,
          "FAT": 1,
          "ValorB": comandaController.valorComanda,
          "Desconto": 0,
          "DataC": formattedDate,
          "Campo_DataC": "VEN_DATAC",
          "Tipo": 1,
          "Ficha": 0,
          "PFParcelas": [
            {
              "Codigo": 1,
              "PF": 0,
              "TP": 0,
              "Valor": comandaController.valorComanda,
              "Vencimento":
                  "${now.add(Duration(days: 30)).year}-${(now.add(Duration(days: 30)).month).toString().padLeft(2, '0')}-${(now.add(Duration(days: 30)).day).toString().padLeft(2, '0')}",
              "Juros": 0,
              "Descontos": 0,
              "Duplicata": "1-1/1",
              "Valorpg": comandaController.valorComanda,
              "Estado": 1
            }
          ]
        }
      };

      // Mostrar tela de carregamento
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) {
          return TelaCarregamento(
            messageAwait: 'Aguarde, finalizando venda...',
            messageSuccess: 'Venda finalizada com sucesso...',
            messageError: 'Erro ao finalizar venda, tente novamente...',
            finalization: true,
            onFinalization: () async {
              final itens = comandaController.itens;
              final valorComanda = comandaController.valorComanda;
              final success = await comandaController.inserirVenda(vendaData);
              if (success['codigo'] != 0) {
                int numeroPedido =
                    await OrderNumberService.generateNextOrderNumber();
                await PrinterService.printOrder(
                    itens: itens,
                    orderNumber: numeroPedido,
                    totalValue: valorComanda);
                //limpa o carrinho
                comandaController.clear();
              }
            },
          );
        }),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Erro: $e");
    }
  }

  // --- Outros métodos de pagamento (mantidos iguais) ---

  void onClickButtonDebito() async {
    TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
        amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
      ..provider = _tefController.configuracoes.provider.toValue()
      ..cardType = CardType.cartaoDebito
      ..finType = FinType.aVista;
    pagar(transacao);
  }

  void onClickButtonCredito() async {
    TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
        amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
      ..provider = _tefController.configuracoes.provider.toValue()
      ..cardType = CardType.cartaoCredito;
    _pagamentoCredito(transacao);
  }

  void onClickButtonVoucher() async {
    TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
        amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
      ..cardType = CardType.cartaoVoucher
      ..finType = FinType.aVista;
    await pagar(transacao);
  }

  void onClickButtonCarteiraDigital() async {
    TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
        amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
      ..provider = TefProvider.NENHUM.toValue()
      ..finType = FinType.aVista
      ..paymentMode = PaymentMode.pagamentoCarteiraVirtual;
    await pagar(transacao);
  }

  void navegarParaTelaAnterior() {
    Get.offAndToNamed('/principal');
  }

  Future<void> pagar(TransacaoRequisicaoVenda transacao) async {
    await _tefController.payGORequestHandler.venda(transacao);
  }

  Future<void> _obterModoDeFinanciamento(
      TransacaoRequisicaoVenda transacao) async {
    FinType currentFinType = await _selecionaFinanciamento();
    double minimoParcelas = 2.0;

    switch (currentFinType) {
      case FinType.aVista:
        transacao.finType = currentFinType;
        break;
      case FinType.parceladoEmissor:
      case FinType.parceladoEstabelecimento:
        transacao.finType = currentFinType;
        double quantidadeParcelas =
            await _selecionaQuantidadeDeParcelas(transacao.amount);
        if (quantidadeParcelas < minimoParcelas) {
          transacao.finType = null;
          return;
        }
        transacao.installments = quantidadeParcelas;
        break;
      default:
        transacao.finType = null;
        break;
    }
  }

  Future<double> _selecionaQuantidadeDeParcelas(double valor) async {
    double quantidadeMaximaDeParcelas = _obterQuantidadeMaximaDeParcelas(valor);
    var parcelas =
        List.generate(quantidadeMaximaDeParcelas.toInt(), (i) => (i + 1))
            .sublist(1);
    double quantidadeParcelas = 1.0;

    await showGenericDialog<int>(
      context: context,
      title: "Selecione a quantidade de parcelas",
      options: parcelas,
      selectedValue: null,
      displayText: (e) => "$e x",
      onSelected: (value) {
        quantidadeParcelas = value.toDouble();
      },
      onCancel: _onCancelOperation,
    );
    return quantidadeParcelas;
  }

  Future<FinType> _selecionaFinanciamento() async {
    var listFinType = {
      FinType.aVista,
      FinType.parceladoEmissor,
      FinType.parceladoEstabelecimento
    };
    FinType currenFinType = FinType.financiamentoNaoDefinido;

    await showGenericDialog<FinType>(
      context: context,
      title: "Selecione a forma de Financiamento",
      options: listFinType.toList(),
      selectedValue: null,
      displayText: (e) => e.finTypeString.replaceAll('_', ' ').toLowerCase(),
      onSelected: (value) {
        currenFinType = value;
      },
      onCancel: _onCancelOperation,
    );
    return currenFinType;
  }

  double _obterQuantidadeMaximaDeParcelas(double valor) {
    double valordeParcelaMinimo = 5.00;
    double valorMinimoParcelavel = 2 * valordeParcelaMinimo;
    if (valor < valorMinimoParcelavel) {
      Fluttertoast.showToast(
          msg: "Valor mínimo para parcelamento é R\$ $valorMinimoParcelavel",
          toastLength: Toast.LENGTH_LONG);
      return 1.0;
    }
    double quantidade = valor / valordeParcelaMinimo;
    return quantidade > 99.0 ? 99.0 : quantidade.floorToDouble();
  }

  void _onCancelOperation() {
    Fluttertoast.showToast(
        msg: "Operação cancelada", toastLength: Toast.LENGTH_LONG);
  }

  void _pagamentoCredito(TransacaoRequisicaoVenda transacao) async {
    try {
      await _obterModoDeFinanciamento(transacao);
      if (transacao.finType == null) {
        navegarParaTelaAnterior();
        return;
      }
      await pagar(transacao);
    } catch (e) {
      Fluttertoast.showToast(msg: "Erro: $e", toastLength: Toast.LENGTH_LONG);
    }
  }

  // Mapear forma de pagamento para ID
  int _getFormaPagtoId(String formaPagto) {
    switch (formaPagto.toLowerCase()) {
      case 'dinheiro':
        return 1;
      case 'débito':
        return 2;
      case 'crédito':
        return 3;
      case 'voucher':
        return 4;
      case 'carteira digital':
        return 5;
      default:
        return 1; // Padrão: dinheiro
    }
  }
}
