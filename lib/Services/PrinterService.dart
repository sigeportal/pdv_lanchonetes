import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/empresa_model.dart';
import 'package:lanchonete/Services/EmpresaService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  static const int _printerPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 4);

  static final _formatMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Tenta imprimir Cupom + Comandas Separadas
  static Future<bool> printOrder(
      {required List<Itens> itens,
      required int orderNumber,
      required double totalValue}) async {
    if (kIsWeb) {
      print("Impressão direta não suportada na Web.");
      return false;
    }

    // 1. Carregar Configurações de IP
    final prefs = await SharedPreferences.getInstance();
    final ipCaixa = prefs.getString('printer_ip_caixa');
    final ipCozinha = prefs.getString('printer_ip_cozinha');

    if (ipCaixa == null || ipCaixa.isEmpty) {
      print("ERRO: IP da impressora do caixa não configurado.");
      return false;
    }

    // 2. BUSCAR DADOS DA EMPRESA
    Empresa dadosEmpresa = await EmpresaService.fetchDadosEmpresa();

    // 3. Carregar Perfil da Impressora
    CapabilityProfile profile;
    try {
      profile = await CapabilityProfile.load(name: 'XP-N160II');
    } catch (e) {
      profile = await CapabilityProfile.load();
    }

    // 4. LÓGICA DE SEPARAÇÃO (Pastel + Bebidas)

    // Verifica se existe ALGUM pastel no pedido
    bool temPastel = itens.any((item) => _isPastel(item));

    List<Itens> itensParaImpressoraGeral = [];
    List<Itens> itensParaImpressoraPastel = [];

    if (temPastel) {
      // CENÁRIO A: Tem Pastel
      // Impressora Pastel: Recebe Pasteis + Bebidas
      // Impressora Geral: Recebe o Resto (Lanches, Porções, etc)

      itensParaImpressoraPastel = itens.where((item) {
        return _isPastel(item) || _isBebida(item);
      }).toList();

      itensParaImpressoraGeral = itens.where((item) {
        return !_isPastel(item) && !_isBebida(item);
      }).toList();
    } else {
      // CENÁRIO B: NÃO Tem Pastel
      // Impressora Geral: Recebe TUDO (Bebidas, Lanches, etc)
      // Impressora Pastel: Recebe Nada

      itensParaImpressoraGeral = List.from(itens); // Cópia de tudo
      itensParaImpressoraPastel = [];
    }

    bool sucessoCaixa = false;

    // =========================================================================
    // IMPRESSÃO 1: CAIXA (Cupom Fiscal Completo + Comanda Geral)
    // =========================================================================
    try {
      print("Conectando ao CAIXA ($ipCaixa)...");
      final socketCaixa = await Socket.connect(ipCaixa, _printerPort,
          timeout: _connectionTimeout);

      // A. Gera Cupom do Cliente (SEMPRE COM A LISTA COMPLETA ORIGINAL)
      List<int> bytesCaixa = await _generateReceiptBytes(
          itens, orderNumber, totalValue, profile, dadosEmpresa);

      // B. Gera Via da Cozinha Geral (Se houver itens destinados a ela)
      if (itensParaImpressoraGeral.isNotEmpty) {
        final bytesCozinhaGeral = await _generateKitchenBytes(
            itensParaImpressoraGeral, orderNumber, profile,
            tituloSetor: "COZINHA (GERAL)");

        bytesCaixa.addAll(bytesCozinhaGeral);
      }

      socketCaixa.add(Uint8List.fromList(bytesCaixa));
      await socketCaixa.flush();
      await socketCaixa.close();
      sucessoCaixa = true;
      print("Impressão CAIXA OK.");
    } catch (e) {
      print("ERRO Impressão CAIXA: $e");
    }

    // =========================================================================
    // IMPRESSÃO 2: COZINHA/PASTELARIA (Pasteis + Bebidas, se houver pastel)
    // =========================================================================
    if (itensParaImpressoraPastel.isNotEmpty &&
        ipCozinha != null &&
        ipCozinha.isNotEmpty) {
      try {
        print("Conectando à COZINHA/PASTEL ($ipCozinha)...");
        final socketCozinha = await Socket.connect(ipCozinha, _printerPort,
            timeout: _connectionTimeout);

        final bytesPastelaria = await _generateKitchenBytes(
            itensParaImpressoraPastel, orderNumber, profile,
            tituloSetor: "COZINHA (PASTEL/BEBIDA)");

        socketCozinha.add(Uint8List.fromList(bytesPastelaria));
        await socketCozinha.flush();
        await socketCozinha.close();
        print("Impressão COZINHA OK.");
      } catch (e) {
        print("ERRO Impressão COZINHA: $e");
      }
    }

    return sucessoCaixa;
  }

  // --- FUNÇÕES AUXILIARES DE FILTRO ---

  static bool _isPastel(Itens item) {
    final nome = (item.nome ?? '').toLowerCase();
    return nome.contains('pastel');
  }

  static bool _isBebida(Itens item) {
    final nome = (item.nome ?? '').toLowerCase();
    // Adicione aqui palavras-chave que identificam bebidas no seu sistema
    return nome.contains('bebida') ||
        nome.contains('refrigerante') ||
        nome.contains('suco') ||
        nome.contains('agua') ||
        nome.contains('água') ||
        nome.contains('coca') ||
        nome.contains('fanta') ||
        nome.contains('guarana') ||
        nome.contains('cerveja') ||
        nome.contains('soda') ||
        nome.contains('lata') ||
        nome.contains('600ml') ||
        nome.contains('2l');
  }

  // --- VIA DO CLIENTE ---
  static Future<List<int>> _generateReceiptBytes(
      List<Itens> itens,
      int orderNumber,
      double totalValue,
      CapabilityProfile profile,
      Empresa empresa) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // Título
    bytes += generator.text(empresa.titulo1?.toUpperCase() ?? 'LANCHONETE',
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            codeTable: 'CP860'));

    bytes += generator.text(empresa.titulo2 ?? 'Endereco nao informado',
        styles: const PosStyles(align: PosAlign.center, codeTable: 'CP860'));

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

    // Cabeçalho Tabela
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

      if (item.complementos != null) {
        for (var c in item.complementos!) {
          valorAdicionais += (c.valor * c.quantidade);
        }
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) {
          valorAdicionais += (op.valorAdicional * op.quantidade);
        }
      }
      double totalLinha = (valorBase + valorAdicionais) * qtd;

      // Limpeza de caracteres especiais para evitar bug na impressora
      String valorFormatado = _formatMoeda
          .format(totalLinha)
          .replaceAll('R\$', '')
          .replaceAll('\u00A0', '') // Remove espaço invisível
          .trim();

      bytes += generator.row([
        PosColumn(
            text: '${qtd.toInt()}x',
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.left)),
        PosColumn(
            text: item.nome ?? 'Item',
            width: 6,
            styles: const PosStyles(align: PosAlign.left, codeTable: 'CP860')),
        PosColumn(
            text: valorFormatado,
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("   + ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB,
                  align: PosAlign.left,
                  codeTable: 'CP860'));
        }
      }
      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("   + ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB,
                  align: PosAlign.left,
                  codeTable: 'CP860'));
        }
      }
    }

    bytes += generator.hr();

    // CORREÇÃO DO TOTAL FINAL
    String totalNumerico = _formatMoeda
        .format(totalValue)
        .replaceAll('R\$', '')
        .replaceAll('\u00A0', '')
        .trim();

    // Inserimos o R$ manualmente com espaço normal (ASCII 32)
    String totalFinalParaImpressao = 'R\$ $totalNumerico';

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(
          text: totalFinalParaImpressao,
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

  // --- VIA DA COZINHA ---
  static Future<List<int>> _generateKitchenBytes(
      List<Itens> itens, int orderNumber, CapabilityProfile profile,
      {String tituloSetor = "COZINHA"}) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    bytes += generator.text(tituloSetor,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            reverse: true,
            codeTable: 'CP860'));
    bytes += generator.feed(1);

    bytes += generator.text('PEDIDO: ${orderNumber.toString().padLeft(3, '0')}',
        styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3,
            width: PosTextSize.size3,
            bold: true));

    bytes += generator.text(DateFormat('HH:mm').format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr(ch: '=');
    bytes += generator.feed(1);

    for (var item in itens) {
      double qtd = item.quantidade ?? 1;

      bytes += generator.text('${qtd.toInt()}x ${item.nome?.toUpperCase()}',
          styles: const PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size1,
              bold: true,
              codeTable: 'CP860'));

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("  [+] ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true,
                  codeTable: 'CP860'));
        }
      }

      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("  [+] ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true,
                  codeTable: 'CP860'));
        }
      }

      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.feed(1);
        bytes += generator.text("  OBS: ${item.obs}",
            styles:
                const PosStyles(bold: true, reverse: true, codeTable: 'CP860'));
      }

      bytes += generator.hr(ch: '-');
    }

    bytes += generator.feed(2);
    bytes += generator.text('*** VIA PRODUCAO ***',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
