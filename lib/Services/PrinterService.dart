import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:lanchonete/Models/itens_model.dart'; // Ajuste conforme seu caminho real

class PrinterService {
  // Configurações da Impressora
  static const String _printerIp = '10.0.0.22';
  static const int _printerPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 5);

  static final _formatMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Tenta imprimir Cupom + Cozinha
  static Future<bool> printOrder(
      {required List<Itens> itens,
      required int orderNumber,
      required double totalValue}) async {
    // Web não suporta Socket direto
    if (kIsWeb) {
      print("Impressão direta não suportada na Web.");
      return false;
    }

    try {
      print(
          "Conectando à impressora $_printerIp:$_printerPort (timeout: $_connectionTimeout)...");
      final socket = await Socket.connect(_printerIp, _printerPort,
          timeout: _connectionTimeout);

      // --- CORREÇÃO DO LAYOUT 80mm ---
      // O perfil 'XP-N160II' geralmente corrige o problema de margem estreita (58mm)
      // em impressoras 80mm genéricas (Elgin, XPrinter, etc).
      CapabilityProfile profile;
      try {
        profile = await CapabilityProfile.load(name: 'XP-N160II');
      } catch (e) {
        // Se falhar, usa o padrão (pode ficar estreito, mas imprime)
        profile = await CapabilityProfile.load();
      }

      // 1. Gera bytes do Cupom do Cliente
      final List<int> receiptBytes =
          await _generateReceiptBytes(itens, orderNumber, totalValue, profile);

      // 2. Gera bytes da Via da Cozinha
      final List<int> kitchenBytes =
          await _generateKitchenBytes(itens, orderNumber, profile);

      // 3. Combina tudo
      final List<int> allBytes = [...receiptBytes, ...kitchenBytes];

      // 4. Envia
      socket.add(Uint8List.fromList(allBytes));
      await socket.flush();
      await socket.close();

      print("Impressão enviada com sucesso!");
      return true;
    } on SocketException catch (e) {
      print("Erro de conexão com a impressora: $e");
      print("Verifique se:");
      print("  - O IP da impressora ($_printerIp) está correto");
      print("  - A impressora está ligada e conectada à rede");
      print("  - A porta $_printerPort está aberta");
      return false;
    } catch (e) {
      print("Erro ao imprimir: $e");
      return false;
    }
  }

  // --- VIA DO CLIENTE (COM PREÇOS) ---
  static Future<List<int>> _generateReceiptBytes(List<Itens> itens,
      int orderNumber, double totalValue, CapabilityProfile profile) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Reset para limpar configurações anteriores da impressora
    bytes += generator.reset();

    // Cabeçalho
    // Usamos size2 aqui porque está centralizado e fora de colunas
    bytes += generator.text('LANCHONETE EXEMPLAR',
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));

    bytes += generator.text('Rua das Delicias, 123',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    // Senha
    bytes += generator.text('SENHA / PEDIDO',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(orderNumber.toString().padLeft(3, '0'),
        styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3,
            width: PosTextSize.size3,
            bold: true));

    bytes += generator.feed(1);
    bytes += generator.text(
        "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Tabela de Itens
    // SOMA DAS LARGURAS (WIDTH) DEVE SER 12
    // 2 (Qtd) + 6 (Item) + 4 (Total) = 12
    bytes += generator.row([
      PosColumn(text: 'Qtd', width: 2, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'Total',
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    for (var item in itens) {
      double qtd = item.quantidade ?? 1;
      double valorBase = item.valor ?? 0;
      double valorAdicionais = 0;
      //adicionais
      if (item.complementos != null) {
        for (var c in item.complementos!) {
          valorAdicionais += (c.valor * c.quantidade);
        }
      }
      //opcoes
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) {
          valorAdicionais += (op.valorAdicional * op.quantidade);
        }
      }
      double totalLinha = (valorBase + valorAdicionais) * qtd;

      // ATENÇÃO: Nunca use PosTextSize.size2 DENTRO de row(),
      // pois quebra o alinhamento em muitas impressoras. Use apenas Bold.
      bytes += generator.row([
        PosColumn(
            text: '${qtd.toInt()}x',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(
            text: item.nome ?? 'Item',
            width: 6,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            text: _formatMoeda.format(totalLinha).replaceAll('R\$', '').trim(),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      // Adicionais (Fora da row para não quebrar layout)
      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("   + ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB, align: PosAlign.left));
        }
      }
      // opcoes (Fora da row para não quebrar layout)
      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("   + ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB, align: PosAlign.left));
        }
      }
    }

    bytes += generator.hr();

    // Total Final
    // Aqui voltamos a usar size2 pois temos apenas 2 colunas grandes (6+6)
    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(
          text: _formatMoeda.format(totalValue),
          width: 6,
          styles: const PosStyles(
              bold: true,
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2)),
    ]);

    bytes += generator.feed(2);
    bytes += generator.text('*** VIA CLIENTE ***',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // --- VIA DA COZINHA (SEM PREÇOS, FOCO EM LEITURA RÁPIDA) ---
  static Future<List<int>> _generateKitchenBytes(
      List<Itens> itens, int orderNumber, CapabilityProfile profile) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // Cabeçalho Cozinha (Invertido para destaque visual)
    bytes += generator.text('COZINHA',
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            reverse: true));
    bytes += generator.feed(1);

    // Senha
    bytes += generator.text('PEDIDO: ${orderNumber.toString().padLeft(3, '0')}',
        styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3, // Fonte tripla para ver de longe
            width: PosTextSize.size3,
            bold: true));

    bytes += generator.text(DateFormat('HH:mm').format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr(ch: '=');
    bytes += generator.feed(1);

    // Lista de Itens da Cozinha
    for (var item in itens) {
      double qtd = item.quantidade ?? 1;

      // NOTA: Para a cozinha, não usamos colunas (row).
      // Imprimimos linearmente para permitir nomes longos sem quebra.

      // Formato: 2x X-TUDO ESPECIAL
      // Usamos apenas Height(altura) dobrada, Width(largura) normal para caber mais texto
      bytes += generator.text('${qtd.toInt()}x ${item.nome?.toUpperCase()}',
          styles: const PosStyles(
              height: PosTextSize.size2, width: PosTextSize.size1, bold: true));

      // Adicionais
      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("  [+] ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true));
        }
      }

      // opcoes
      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("  [+] ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true));
        }
      }

      // Observações (Fundo preto para chamar atenção do chapeiro)
      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.feed(1);
        bytes += generator.text("  OBS: ${item.obs}",
            styles: const PosStyles(bold: true, reverse: true));
      }

      bytes += generator.hr(ch: '-');
    }

    bytes += generator.feed(2);
    bytes += generator.text('*** VIA COZINHA ***',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
