import 'package:lanchonete/Components/generic_dialog.dart';
import 'package:lanchonete/Components/payment_option_tile.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Controller/Tef/types/tef_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Pages/Tela_carregamento_page.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_venda.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/card_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/currency_code.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/fin_type.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/payment_mode.dart';

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

  String _formatPayment() {
    return "R\$ ${widget.valorPagamento.toStringAsFixed(2)}"
        .replaceAll('.', ',');
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Seção do valor total
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

                // Título da seção
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

                // Lista de opções de pagamento
                Expanded(
                  child: ListView(
                    children: [
                      PaymentOptionTile(
                        icon: Icons.monetization_on_sharp,
                        title: "Dinheiro",
                        subtitle: "Á Vista",
                        color: Colors.blue,
                        onPressed: onClickButtonDinheiro,
                      ),
                      const SizedBox(height: 12),
                      PaymentOptionTile(
                        icon: Icons.credit_card,
                        title: "Débito",
                        subtitle: "Cartão de débito",
                        color: Colors.blue,
                        onPressed: onClickButtonDebito,
                      ),
                      const SizedBox(height: 12),
                      PaymentOptionTile(
                        icon: Icons.credit_card,
                        title: "Crédito",
                        subtitle: "Cartão de crédito",
                        color: Colors.green,
                        onPressed: onClickButtonCredito,
                      ),
                      const SizedBox(height: 12),
                      PaymentOptionTile(
                        icon: Icons.card_giftcard,
                        title: "Voucher",
                        subtitle: "Vale alimentação ou refeição",
                        color: Colors.orange,
                        onPressed: onClickButtonVoucher,
                      ),
                      const SizedBox(height: 12),
                      PaymentOptionTile(
                        icon: Icons.account_balance,
                        title: "Carteira Digital",
                        subtitle: "PIX e carteiras virtuais",
                        color: Colors.indigo,
                        onPressed: onClickButtonCarteiraDigital,
                      ),
                      const SizedBox(height: 24),
                      // Botão cancelar
                      ElevatedButton(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _confirmarFechamento(String formaPagto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          'Deseja finalizar a venda na Forma de pagamento "$formaPagto"?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) {
                  return TelaCarregamento(
                    messageAwait: 'Aguarde, finalizando venda...',
                    messageSuccess: 'Venda finalizada com sucesso...',
                    messageError: 'Erro ao finalizar venda, tente novamente...',
                    finalization: true,
                  );
                }),
              );
            },
            child: Text(
              'Confirmar',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos onClick
  void onClickButtonDinheiro() async {
    await _confirmarFechamento('Dinheiro');
  }

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

  // Métodos auxiliares

  void navegarParaTelaAnterior() {
    Get.offAndToNamed('/principal');
  }

  Future<void> pagar(TransacaoRequisicaoVenda transacao) async {
    await _tefController.payGORequestHandler.venda(transacao);
  }

  /// Função auxiliar para obter o modo de financiamento
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

  // Função auxiliar para selecionar a quantidade de parcelas
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
      onCancel: () {
        _onCancelOperation();
      },
    );
    return quantidadeParcelas;
  }

  // Função auxiliar para selecionar a forma de financiamento
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
      onCancel: () {
        _onCancelOperation();
      },
    );
    return currenFinType;
  }

  /// Função auxiliar para calcular a quantidade máxima de parcelas
  double _obterQuantidadeMaximaDeParcelas(double valor) {
    double valordeParcelaMinimo = 5.00;
    double valorMinimoParcelavel = 2 * valordeParcelaMinimo;
    double quantidadeMaximaDeParcelas = 99.0;

    if (valor < valorMinimoParcelavel) {
      Fluttertoast.showToast(
          msg: "Valor mínimo para parcelamento é R\$ $valorMinimoParcelavel",
          toastLength: Toast.LENGTH_LONG);
      return 1.0;
    }
    double quantidadeDeParcelas = valor / valordeParcelaMinimo;

    if (quantidadeDeParcelas > quantidadeMaximaDeParcelas) {
      return quantidadeMaximaDeParcelas;
    }
    return quantidadeDeParcelas.floorToDouble();
  }

  void _onCancelOperation() {
    Fluttertoast.showToast(
        msg: "Operação cancelada", toastLength: Toast.LENGTH_LONG);
  }

  /// Função auxiliar para pagamento com cartão de crédito
  void _pagamentoCredito(TransacaoRequisicaoVenda transacao) async {
    try {
      await _obterModoDeFinanciamento(transacao);
      if (transacao.finType == null) {
        navegarParaTelaAnterior();
        return;
      }
      await pagar(transacao);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Erro ao processar pagamento: $e",
          toastLength: Toast.LENGTH_LONG,
          fontSize: 16.0);
    }
  }
}
