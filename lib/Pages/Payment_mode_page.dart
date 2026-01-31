import 'package:lanchonete/Components/generic_dialog.dart';
import 'package:lanchonete/Components/payment_option_tile.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Models/venda_model.dart';
import 'package:lanchonete/Models/cliente_model.dart';
import 'package:lanchonete/Pages/Tela_carregamento_page.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_venda.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Services/CupomFiscalService.dart';
import '../Services/PrinterService.dart';
import '../Services/ClienteService.dart';

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
  late PedFat pedFat;

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
        icon: Icons.card_membership_rounded,
        title: "Pedido",
        subtitle: "A Prazo",
        color: Colors.red,
        onPressed: onClickButtonPedido,
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
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [
      PFParcela(
        codigo: 0,
        duplicata: "1-1/1",
        pf: 0,
        valor: comandaController.valorComanda,
        valorpg: comandaController.valorComanda,
        vencimento: DateTime.now(),
        juros: 0,
        tp: _getFormaPagtoId('dinheiro'),
        descontos: 0,
        estado: 1,
        tipoPagamento: null,
      )
    ];

    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: 'CONSUMIDOR',
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: 1,
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: 1,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirCalculadoraTroco();
  }

  void onClickButtonPedido() async {
    // Primeiro, exibir a tela de seleção de clientes
    Cliente? clienteSelecionado = await _exibirSelecaoClientes();

    if (clienteSelecionado == null) {
      // Cliente não selecionado, cancelar operação
      return;
    }

    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    double quantidadeParcelas =
        1; //await _selecionaQuantidadeDeParcelas(comandaController.valorComanda);
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [];
    double valorTotal = comandaController.valorComanda;
    for (var i = 0; i <= quantidadeParcelas.toInt() - 1; i++) {
      double valorParcela = valorTotal / quantidadeParcelas.toInt();
      parcelas.add(
        PFParcela(
          codigo: 0,
          duplicata: "1-${i + 1}/${quantidadeParcelas.toInt()}",
          pf: 0,
          valor: valorParcela,
          valorpg: valorParcela,
          vencimento: DateTime(
            DateTime.now().year,
            DateTime.now().month + i,
            DateTime.now().day,
          ),
          juros: 0,
          tp: _getFormaPagtoId('pedido'),
          descontos: 0,
          estado: 1,
          tipoPagamento: null,
        ),
      );
    }
    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: clienteSelecionado.nome,
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: quantidadeParcelas.toInt(),
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: clienteSelecionado.codigo,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirConfirmacaoPagamento(
        'Pedido (A Prazo)', clienteSelecionado.nome);
  }

  void onClickButtonCredito() async {
    // TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
    //     amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
    //   ..provider = _tefController.configuracoes.provider.toValue()
    //   ..cardType = CardType.cartaoCredito;
    // _pagamentoCredito(transacao);
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    double quantidadeParcelas = 1;
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [];
    double valorTotal = comandaController.valorComanda;
    for (var i = 0; i <= quantidadeParcelas.toInt() - 1; i++) {
      double valorParcela = valorTotal / quantidadeParcelas.toInt();
      parcelas.add(
        PFParcela(
          codigo: 0,
          duplicata: "1-${i + 1}/${quantidadeParcelas.toInt()}",
          pf: 0,
          valor: valorParcela,
          valorpg: valorParcela,
          vencimento: DateTime(
            DateTime.now().year,
            DateTime.now().month + i,
            DateTime.now().day,
          ),
          juros: 0,
          tp: _getFormaPagtoId('credito'),
          descontos: 0,
          estado: 1,
          tipoPagamento: null,
        ),
      );
    }
    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: 'CONSUMIDOR',
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: quantidadeParcelas.toInt(),
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: 1,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirConfirmacaoPagamento(
        'Cartão de Crédito', 'CONSUMIDOR NÃO IDENTIFICADO');
  }

  void onClickButtonVoucher() async {
    // TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
    //     amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
    //   ..cardType = CardType.cartaoVoucher
    //   ..finType = FinType.aVista;
    // await pagar(transacao);
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    double quantidadeParcelas = 1;
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [];
    double valorTotal = comandaController.valorComanda;
    for (var i = 0; i <= quantidadeParcelas.toInt() - 1; i++) {
      double valorParcela = valorTotal / quantidadeParcelas.toInt();
      parcelas.add(
        PFParcela(
          codigo: 0,
          duplicata: "1-${i + 1}/${quantidadeParcelas.toInt()}",
          pf: 0,
          valor: valorParcela,
          valorpg: valorParcela,
          vencimento: DateTime(
            DateTime.now().year,
            DateTime.now().month + i,
            DateTime.now().day,
          ),
          juros: 0,
          tp: _getFormaPagtoId('voucher'),
          descontos: 0,
          estado: 1,
          tipoPagamento: null,
        ),
      );
    }
    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: 'CONSUMIDOR',
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: quantidadeParcelas.toInt(),
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: 1,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirConfirmacaoPagamento('Voucher', 'CONSUMIDOR NÃO IDENTIFICADO');
  }

  void onClickButtonCarteiraDigital() async {
    // TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
    //     amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
    //   ..provider = TefProvider.NENHUM.toValue()
    //   ..finType = FinType.aVista
    //   ..paymentMode = PaymentMode.pagamentoCarteiraVirtual;
    // await pagar(transacao);
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    double quantidadeParcelas = 1;
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [];
    double valorTotal = comandaController.valorComanda;
    for (var i = 0; i <= quantidadeParcelas.toInt() - 1; i++) {
      double valorParcela = valorTotal / quantidadeParcelas.toInt();
      parcelas.add(
        PFParcela(
          codigo: 0,
          duplicata: "1-${i + 1}/${quantidadeParcelas.toInt()}",
          pf: 0,
          valor: valorParcela,
          valorpg: valorParcela,
          vencimento: DateTime(
            DateTime.now().year,
            DateTime.now().month + i,
            DateTime.now().day,
          ),
          juros: 0,
          tp: _getFormaPagtoId('pix'),
          descontos: 0,
          estado: 1,
          tipoPagamento: null,
        ),
      );
    }
    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: 'CONSUMIDOR',
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: quantidadeParcelas.toInt(),
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: 1,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirConfirmacaoPagamento(
        'Carteira Digital / PIX', 'CONSUMIDOR NÃO IDENTIFICADO');
  }

  // Tela de seleção de clientes para pagamento em pedido
  Future<Cliente?> _exibirSelecaoClientes() async {
    return showDialog<Cliente?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ClienteSelectionDialog();
      },
    );
  }

  // Tela de confirmação de pagamento
  Future<void> _exibirConfirmacaoPagamento(
      String formaPagamento, String cliente) async {
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);

    // Obter informações do pagamento
    String descricaoParc = '';
    if (pedFat.pFParcelas.length == 1) {
      descricaoParc = 'Pagamento à vista';
    } else {
      descricaoParc =
          '${pedFat.pFParcelas.length}x de ${_currencyFormat.format(pedFat.pFParcelas.first.valor)}';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: 650,
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de confirmação
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 50,
                      color: Colors.blue[700],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Confirmar Pagamento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Detalhes do pagamento em card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        // Forma de pagamento
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Forma de Pagamento:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formaPagamento,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Divider(),
                        const SizedBox(height: 16),

                        // Valor total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cliente:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              cliente,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        const SizedBox(height: 16),

                        // Valor total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Valor Total:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currencyFormat
                                  .format(comandaController.valorComanda),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Parcelamento (se houver)
                        if (pedFat.pFParcelas.length > 1)
                          Column(
                            children: [
                              Divider(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Parcelamento:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    descricaoParc,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Aviso
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Verifique os dados antes de confirmar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botões
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão Cancelar
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  BorderSide(color: Colors.red[300]!, width: 2),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botão Confirmar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (formaPagamento == 'Dinheiro') {
                              _exibirCalculadoraTroco();
                            } else {
                              _finalizarVenda();
                            }
                          },
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text(
                            'Confirmar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                                  _finalizarVenda();
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

  Future<void> _finalizarVenda() async {
    try {
      final comandaController =
          Provider.of<ComandaController>(context, listen: false);

      // Construir a venda usando o modelo Venda
      final now = DateTime.now();

      // Construir itens
      List<ItemVenda> itensVenda = comandaController.itens.map((item) {
        final valorUnitario = item.valor ?? 0.0;
        final quantidade = (item.quantidade ?? 1.0).toInt();

        return ItemVenda(
          codigo: 0,
          valor: valorUnitario * quantidade,
          quantidade: quantidade,
          ven: 0,
          pro: item.produto ?? 0,
          lucro: 10,
          valorr: valorUnitario * 0.8,
          valorl: valorUnitario * 0.9,
          valorf: valorUnitario,
          diferenca: 0,
          liquido: 0,
          valor2: valorUnitario * quantidade,
          valorcm: 0,
          aliquota: 0,
          gtin: "",
          embalagem: "PC",
          valorb: valorUnitario * quantidade,
          desconto: 0,
          valorc: valorUnitario * 0.7,
          obs: item.obs ?? "",
          gra: item.grade ?? 0,
          semente_tratada: "N",
          valor_partida: 0,
          variacao: 0,
          usu: 1,
          complementos: [],
          opcoesNivel: item.opcoesNiveis,
        );
      }).toList();

      // Criar modelo Venda
      final venda = Venda(
        codigo: 0,
        data: now,
        valor: comandaController.valorComanda,
        hora: now.hour + (now.minute / 60) + (now.second / 3600),
        fun: 1,
        nf: 0,
        diferenca: 0,
        datac: now.day,
        fat: 0,
        dav: 0,
        cli: pedFat.cod_cli,
        devolucao_p: "N",
        tipo_pedido: "VENDA",
        taxa_entrega: 0,
        forma_pgto: 0,
        nome_cliente: pedFat.cliente,
        id_pedido: '',
        itens: itensVenda,
        pedFat: pedFat,
      );

      // Converter para JSON para enviar à API
      Map<String, dynamic> vendaData = venda.toJson();

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
    // TransacaoRequisicaoVenda transacao = TransacaoRequisicaoVenda(
    //     amount: widget.valorPagamento, currencyCode: CurrencyCode.iso4217Real)
    //   ..provider = _tefController.configuracoes.provider.toValue()
    //   ..cardType = CardType.cartaoDebito
    //   ..finType = FinType.aVista;
    // pagar(transacao);
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);
    double quantidadeParcelas = 1;
    // Construir parcelas de pagamento
    List<PFParcela> parcelas = [];
    double valorTotal = comandaController.valorComanda;
    for (var i = 0; i <= quantidadeParcelas.toInt() - 1; i++) {
      double valorParcela = valorTotal / quantidadeParcelas.toInt();
      parcelas.add(
        PFParcela(
          codigo: 0,
          duplicata: "1-${i + 1}/${quantidadeParcelas.toInt()}",
          pf: 0,
          valor: valorParcela,
          valorpg: valorParcela,
          vencimento: DateTime(
            DateTime.now().year,
            DateTime.now().month + i,
            DateTime.now().day,
          ),
          juros: 0,
          tp: _getFormaPagtoId('debito'),
          descontos: 0,
          estado: 1,
          tipoPagamento: null,
        ),
      );
    }
    pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: comandaController.valorComanda,
      cliente: 'CONSUMIDOR',
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: quantidadeParcelas.toInt(),
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: 1,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: parcelas,
    );
    await _exibirConfirmacaoPagamento(
        'Cartão de Débito', 'CONSUMIDOR NÃO IDENTIFICADO');
  }

  void navegarParaTelaAnterior() {
    Get.offAndToNamed('/principal');
  }

  Future<void> pagar(TransacaoRequisicaoVenda transacao) async {
    await _tefController.payGORequestHandler.venda(transacao);
  }

  Future<double> _selecionaQuantidadeDeParcelas(double valor) async {
    double quantidadeMaximaDeParcelas = _obterQuantidadeMaximaDeParcelas(valor);
    var parcelas = List.generate(quantidadeMaximaDeParcelas.toInt(), (i) => (i))
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

  // Mapear forma de pagamento para ID
  int _getFormaPagtoId(String formaPagto) {
    switch (formaPagto.toLowerCase()) {
      case 'dinheiro':
        return 0;
      case 'pedido':
        return 1;
      case 'credito':
        return 2;
      case 'debito':
        return 3;
      case 'pix':
        return 4;
      case 'voucher':
        return 5;
      default:
        return 0; // Padrão: dinheiro
    }
  }
}

// Dialog para seleção de clientes
class _ClienteSelectionDialog extends StatefulWidget {
  const _ClienteSelectionDialog();

  @override
  State<_ClienteSelectionDialog> createState() =>
      _ClienteSelectionDialogState();
}

class _ClienteSelectionDialogState extends State<_ClienteSelectionDialog> {
  late Future<List<Cliente>> _futureClientes;
  List<Cliente> _clientesFiltrados = [];
  List<Cliente> _clientesOriginais = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureClientes = ClienteService.obterClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarClientes(String termo) {
    setState(() {
      if (termo.isEmpty) {
        _clientesFiltrados = _clientesOriginais;
      } else {
        _clientesFiltrados = _clientesOriginais
            .where((cliente) =>
                cliente.nome.toLowerCase().contains(termo.toLowerCase()) ||
                cliente.cnpj_cpf.contains(termo))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Cliente>>(
          future: _futureClientes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar clientes:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Nenhum cliente encontrado'),
              );
            }

            // Inicializar a lista filtrada quando os dados chegarem
            if (_clientesOriginais.isEmpty) {
              _clientesOriginais = snapshot.data!;
              _clientesFiltrados = snapshot.data!;
            }

            return Column(
              children: [
                // Campo de busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou CPF/CNPJ',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarClientes('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filtrarClientes,
                ),
                const SizedBox(height: 16),
                // Lista de clientes
                Expanded(
                  child: _clientesFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                              'Nenhum cliente encontrado com esse critério'),
                        )
                      : ListView.builder(
                          itemCount: _clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = _clientesFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(cliente.nome),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Limite: R\$ ${cliente.limite.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.of(context).pop(cliente);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
