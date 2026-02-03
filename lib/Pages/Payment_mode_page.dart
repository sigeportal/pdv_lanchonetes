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

  // Estado para múltiplos pagamentos
  List<PFParcela> _pagamentos = [];
  Cliente? _clienteSelecionado; // Para casos de Pedido/A Prazo

  double get _totalPago => _pagamentos.fold(0, (sum, p) => sum + p.valor);
  double get _valorRestante =>
      (widget.valorPagamento - _totalPago).clamp(0, double.infinity);
  bool get _podeFinalizar => _valorRestante <= 0.01; // Margem de erro float

  String _formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  // --- UI PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isHorizontal = orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagamento"),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // CABEÇALHO DE TOTAIS
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                        "Total", widget.valorPagamento, Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoCard("Pago", _totalPago, Colors.green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoCard(
                        "Falta", _valorRestante, Colors.redAccent),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // CORPO (Opções + Lista de Pagamentos)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado Esquerdo: Opções de Pagamento
                  Expanded(
                    flex: 6, // Maior espaço para botões
                    child: Container(
                      color: Colors.grey[50],
                      padding: const EdgeInsets.all(12),
                      child: isHorizontal
                          ? GridView.count(
                              crossAxisCount: 3, // 3 colunas no landscape
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.3,
                              children: _getPaymentTiles(),
                            )
                          : ListView(
                              children: _getPaymentTilesWithSpacing(),
                            ),
                    ),
                  ),

                  // Lado Direito: Lista de Pagamentos Adicionados
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border(left: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[100],
                            width: double.infinity,
                            child: const Text("Pagamentos Adicionados",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                          ),
                          Expanded(
                            child: _pagamentos.isEmpty
                                ? Center(
                                    child: Text("Nenhum pagamento\nselecionado",
                                        textAlign: TextAlign.center,
                                        style:
                                            TextStyle(color: Colors.grey[400])),
                                  )
                                : ListView.builder(
                                    itemCount: _pagamentos.length,
                                    itemBuilder: (context, index) {
                                      final p = _pagamentos[index];
                                      return ListTile(
                                        leading: Icon(_getIconForType(p.tp),
                                            color: Colors.blue),
                                        title: Text(_getNomePagamento(p.tp)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatCurrency(p.valor),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  _pagamentos.removeAt(index);
                                                  // Se remover pedido, limpa cliente
                                                  if (!_pagamentos
                                                      .any((p) => p.tp == 1)) {
                                                    _clienteSelecionado = null;
                                                  }
                                                });
                                              },
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          // BOTÃO FINALIZAR
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _podeFinalizar
                                    ? _confirmarEFinalizarVenda
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  _podeFinalizar
                                      ? "FINALIZAR VENDA"
                                      : "FALTA ${_formatCurrency(_valorRestante)}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_formatCurrency(value),
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // --- BOTÕES DE AÇÃO ---

  List<PaymentOptionTile> _getPaymentTiles() {
    return [
      PaymentOptionTile(
        icon: Icons.monetization_on_sharp,
        title: "Dinheiro",
        subtitle: "Á Vista",
        color: Colors.blue,
        onPressed: () => _adicionarPagamentoDinheiro(),
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Débito",
        subtitle: "Cartão",
        color: Colors.blueAccent,
        onPressed: () => _adicionarPagamentoSimples("Débito", 'debito'),
      ),
      PaymentOptionTile(
        icon: Icons.credit_card,
        title: "Crédito",
        subtitle: "Cartão",
        color: Colors.green,
        onPressed: () => _adicionarPagamentoSimples("Crédito", 'credito'),
      ),
      PaymentOptionTile(
        icon: Icons.account_balance,
        title: "PIX",
        subtitle: "Digital",
        color: Colors.indigo,
        onPressed: () => _adicionarPagamentoSimples("PIX", 'pix'),
      ),
      PaymentOptionTile(
        icon: Icons.card_giftcard,
        title: "Voucher",
        subtitle: "Vale",
        color: Colors.orange,
        onPressed: () => _adicionarPagamentoSimples("Voucher", 'voucher'),
      ),
      PaymentOptionTile(
        icon: Icons.card_membership_rounded,
        title: "Pedido",
        subtitle: "A Prazo",
        color: Colors.red,
        onPressed: () => _adicionarPagamentoPedido(),
      ),
    ];
  }

  List<Widget> _getPaymentTilesWithSpacing() {
    final tiles = _getPaymentTiles();
    return tiles
        .expand((element) => [element, const SizedBox(height: 10)])
        .toList();
  }

  // --- LÓGICA DE ADIÇÃO DE PAGAMENTO ---

  // 1. Pagamento Genérico (Débito, Crédito, PIX, Voucher)
  Future<void> _adicionarPagamentoSimples(String titulo, String tipo) async {
    if (_valorRestante <= 0) {
      Fluttertoast.showToast(msg: "O valor total já foi atingido.");
      return;
    }

    double? valor = await _solicitarValor(titulo, _valorRestante);
    if (valor != null && valor > 0) {
      _adicionarParcela(tipo, valor);
    }
  }

  // 2. Pagamento em Dinheiro (Com calculadora)
  Future<void> _adicionarPagamentoDinheiro() async {
    if (_valorRestante <= 0) {
      Fluttertoast.showToast(msg: "O valor total já foi atingido.");
      return;
    }

    // Abre a calculadora que você já tinha, mas adaptada para retornar valor
    // em vez de fechar a venda
    await _exibirCalculadoraTrocoLogica();
  }

  // 3. Pagamento A Prazo (Pedido)
  Future<void> _adicionarPagamentoPedido() async {
    if (_valorRestante <= 0) {
      Fluttertoast.showToast(msg: "O valor total já foi atingido.");
      return;
    }

    // Se já tem cliente selecionado, mantemos. Senão, pedimos.
    if (_clienteSelecionado == null) {
      Cliente? cli = await _exibirSelecaoClientes();
      if (cli == null) return;
      setState(() {
        _clienteSelecionado = cli;
      });
    }

    double? valor = await _solicitarValor(
        "Pedido (${_clienteSelecionado!.nome})", _valorRestante);

    if (valor != null && valor > 0) {
      // Aqui você poderia perguntar parcelas se quisesse
      _adicionarParcela('pedido', valor);
    }
  }

  // Adiciona na lista interna
  void _adicionarParcela(String tipoString, double valor) {
    int tp = _getFormaPagtoId(tipoString);

    setState(() {
      _pagamentos.add(PFParcela(
        codigo: 0,
        duplicata: "1-1/1", // Pode ajustar se houver parcelamento real
        pf: 0,
        valor: valor,
        valorpg: valor,
        vencimento: DateTime.now(), // Ajustar se for a prazo
        juros: 0,
        tp: tp,
        descontos: 0,
        estado: 1,
        tipoPagamento: null,
      ));
    });
  }

  // Dialog para digitar valor
  Future<double?> _solicitarValor(String titulo, double valorSugerido) async {
    TextEditingController controller = TextEditingController(
        text: valorSugerido.toStringAsFixed(2).replaceAll('.', ','));

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Valor a pagar",
            prefixText: "R\$ ",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(context), // Fecha teclado
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: () {
              String text =
                  controller.text.replaceAll('.', '').replaceAll(',', '.');
              double? val = double.tryParse(text);
              if (val != null) {
                // Validação para não pagar mais que o restante
                if (val > _valorRestante + 0.05) {
                  // Margem pequena
                  Fluttertoast.showToast(
                      msg: "Valor excede o restante a pagar!");
                  return;
                }
                Navigator.pop(context, val);
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }

  // --- FINALIZAÇÃO ---

  Future<void> _confirmarEFinalizarVenda() async {
    // Monta o PedFat com a lista acumulada
    final comandaController =
        Provider.of<ComandaController>(context, listen: false);

    // Define o cliente (ou Consumidor se não houver pedido a prazo)
    String nomeCliente = 'CONSUMIDOR';
    int codCli = 1;

    if (_clienteSelecionado != null) {
      nomeCliente = _clienteSelecionado!.nome;
      codCli = _clienteSelecionado!.codigo;
    } else {
      // Se tem pedido mas não setou cliente (segurança)
      if (_pagamentos.any((p) => p.tp == 1)) {
        Cliente? cli = await _exibirSelecaoClientes();
        if (cli == null) return;
        _clienteSelecionado = cli;
        nomeCliente = cli.nome;
        codCli = cli.codigo;
      }
    }

    final pedFat = PedFat(
      codigo: 0,
      ficha: 0,
      cod_ped: 0,
      desconto: 0,
      valor: comandaController.valorComanda,
      datac: DateTime.parse('1990-01-01'),
      valorpg: _totalPago,
      cliente: nomeCliente,
      tabela: 'VENDAS',
      valorb: comandaController.valorComanda,
      fun: 1,
      campo_datac: 'VEN_DATAC',
      fat: 0,
      parcelas: _pagamentos.length, // Quantidade de formas de pagto usadas
      campo_fat: 'VEN_FAT',
      tipo: 1,
      cod_cli: codCli,
      campo_ped: 'VEN_CODIGO',
      data: DateTime.now(),
      pFParcelas: _pagamentos, // AQUI VAI A LISTA MÚLTIPLA
    );

    _finalizarVenda(pedFat);
  }

  Future<void> _finalizarVenda(PedFat pedFatFinal) async {
    try {
      final comandaController =
          Provider.of<ComandaController>(context, listen: false);
      final now = DateTime.now();

      // Construir itens (código mantido)
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
        cli: pedFatFinal.cod_cli,
        devolucao_p: "N",
        tipo_pedido: "VENDA",
        taxa_entrega: 0,
        forma_pgto: 0,
        nome_cliente: pedFatFinal.cliente,
        id_pedido: '',
        itens: itensVenda,
        pedFat: pedFatFinal,
      );

      Map<String, dynamic> vendaData = venda.toJson();

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

  // --- ADAPTAÇÃO DA CALCULADORA DE TROCO ---
  Future<void> _exibirCalculadoraTrocoLogica() async {
    final TextEditingController _valorRecebidoController =
        TextEditingController();
    double troco = 0.0;
    List<String> sugestaoCedulas = [];

    // Se falta R$ 20 e o cara dá R$ 50, o pagamento é R$ 20 e o troco R$ 30.
    // O valor a ser registrado na parcela é o valor da dívida (restante), não o entregue.

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 800,
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
                  String cleanValue = value
                      .replaceAll('.', '')
                      .replaceAll(',', '.'); // Fix parser
                  double? recebido = double.tryParse(cleanValue);

                  if (recebido != null) {
                    setState(() {
                      // O troco é baseado no quanto FALTA pagar
                      troco = recebido - _valorRestante;
                      if (troco > 0) {
                        sugestaoCedulas = _gerarSugestaoCedulas(troco);
                      } else {
                        sugestaoCedulas = [];
                      }
                    });
                  }
                }

                // O valor digitado (Recebido) deve ser pelo menos o valor restante
                // OU, se for menor, aceitamos como pagamento parcial (sem troco)
                bool podeConfirmar = false;
                String cleanText = _valorRecebidoController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.');
                double? valorDigitado = double.tryParse(cleanText);

                if (valorDigitado != null && valorDigitado > 0)
                  podeConfirmar = true;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate,
                            color: Colors.blue, size: 28),
                        const SizedBox(width: 10),
                        const Text("Dinheiro / Troco",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Falta Pagar",
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                  Text(_formatCurrency(_valorRestante),
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800])),
                                  const SizedBox(height: 30),
                                  const Text("Valor Recebido",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _valorRecebidoController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 20),
                                    decoration: const InputDecoration(
                                      prefixText: "R\$ ",
                                      border: OutlineInputBorder(),
                                      hintText: "0,00",
                                    ),
                                    onChanged: _calcularTroco,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                              width: 1,
                              color: Colors.grey[300],
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20)),
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(16),
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
                                  const Text("Troco a devolver",
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
                                  const SizedBox(height: 16),
                                  if (sugestaoCedulas.isNotEmpty) ...[
                                    const Divider(),
                                    const Text("Sugestão de notas:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: sugestaoCedulas.length,
                                        itemBuilder: (context, index) {
                                          return Text(
                                              "• ${sugestaoCedulas[index]}",
                                              style: const TextStyle(
                                                  fontSize: 16));
                                        },
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar",
                              style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: podeConfirmar
                              ? () {
                                  Navigator.pop(context);
                                  // Se o valor recebido for maior que o restante, pagamos o restante (o resto é troco).
                                  // Se for menor, pagamos o recebido (pagamento parcial).
                                  double recebido = double.tryParse(
                                          _valorRecebidoController.text
                                              .replaceAll('.', '')
                                              .replaceAll(',', '.')) ??
                                      0;
                                  double valorAPagar =
                                      recebido >= _valorRestante
                                          ? _valorRestante
                                          : recebido;

                                  _adicionarParcela('dinheiro', valorAPagar);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16)),
                          child: const Text("Confirmar Pagamento",
                              style: TextStyle(color: Colors.white)),
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

  // ... [MÉTODOS AUXILIARES: _gerarSugestaoCedulas, _getFormaPagtoId, etc MANTIDOS DO CÓDIGO ORIGINAL] ...
  // Copie os métodos _gerarSugestaoCedulas, _getFormaPagtoId, e as classes _ClienteSelectionDialog aqui
  // Eles não precisam mudar de lógica interna, apenas certifique-se de que estão dentro da classe.

  // (Para economizar espaço, assumo que você manterá os métodos auxiliares existentes no seu arquivo original,
  //  como _gerarSugestaoCedulas, _getFormaPagtoId, _getIconForType, _getNomePagamento, _exibirSelecaoClientes e a classe _ClienteSelectionDialog)
  // Abaixo apenas os helpers visuais que adicionei no build:

  IconData _getIconForType(int tp) {
    switch (tp) {
      case 0:
        return Icons.monetization_on;
      case 1:
        return Icons.card_membership;
      case 2:
      case 3:
        return Icons.credit_card;
      case 4:
        return Icons.qr_code;
      case 5:
        return Icons.card_giftcard;
      default:
        return Icons.payment;
    }
  }

  String _getNomePagamento(int tp) {
    switch (tp) {
      case 0:
        return "Dinheiro";
      case 1:
        return "A Prazo";
      case 2:
        return "Crédito";
      case 3:
        return "Débito";
      case 4:
        return "PIX";
      case 5:
        return "Voucher";
      default:
        return "Outro";
    }
  }

  // Algoritmo para calcular notas e moedas (Mantido)
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
        return 0;
    }
  }

  // Reutilize o _ClienteSelectionDialog do seu código original no final do arquivo
  Future<Cliente?> _exibirSelecaoClientes() async {
    return showDialog<Cliente?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _ClienteSelectionDialog();
      },
    );
  }
}

// ... CLASSE _ClienteSelectionDialog (MANTENHA A DO SEU CÓDIGO ORIGINAL) ...
class _ClienteSelectionDialog extends StatefulWidget {
  const _ClienteSelectionDialog();
  @override
  State<_ClienteSelectionDialog> createState() =>
      _ClienteSelectionDialogState();
}

// (Cole o conteúdo restante da classe _ClienteSelectionDialog e seu State aqui, é igual ao que você já tem)
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
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum cliente encontrado'));
            }
            if (_clientesOriginais.isEmpty) {
              _clientesOriginais = snapshot.data!;
              _clientesFiltrados = snapshot.data!;
            }
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: _filtrarClientes,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cli = _clientesFiltrados[index];
                      return ListTile(
                        title: Text(cli.nome),
                        subtitle: Text(cli.cnpj_cpf),
                        onTap: () => Navigator.pop(context, cli),
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"))
      ],
    );
  }
}
