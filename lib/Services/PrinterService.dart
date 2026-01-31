import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/empresa_model.dart'; // Certifique-se de importar o Model criado
import 'package:lanchonete/Services/EmpresaService.dart'; // Certifique-se de importar o Service criado
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  static const int _printerPort = 9100;
  // Aumentei um pouco o timeout para dar tempo de conectar em redes lentas
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

    // 2. BUSCAR DADOS DA EMPRESA (API ou Cache)
    // Isso garante que o título seja dinâmico
    Empresa dadosEmpresa = await EmpresaService.fetchDadosEmpresa();

    // 3. Carregar Perfil da Impressora
    CapabilityProfile profile;
    try {
      profile = await CapabilityProfile.load(name: 'XP-N160II');
    } catch (e) {
      profile = await CapabilityProfile.load();
    }

    // 4. Separar as Listas (Lógica do Pastel)
    final List<Itens> listaPasteis = itens.where((item) {
      final nome = (item.nome ?? '').toLowerCase();
      return nome.contains('pastel');
    }).toList();

    final List<Itens> listaGeral = itens.where((item) {
      final nome = (item.nome ?? '').toLowerCase();
      return !nome.contains('pastel');
    }).toList();

    bool sucessoCaixa = false;
    // Se não tiver pastéis, consideramos a "cozinha" como sucesso (nada a fazer)
    bool sucessoCozinha = listaPasteis.isEmpty;

    // =========================================================================
    // IMPRESSÃO 1: CAIXA (Cupom Completo + Produção Geral)
    // =========================================================================
    try {
      print("Conectando ao CAIXA ($ipCaixa)...");
      final socketCaixa = await Socket.connect(ipCaixa, _printerPort,
          timeout: _connectionTimeout);

      // A. Gera Cupom do Cliente (COM TODOS OS ITENS e DADOS DA EMPRESA)
      List<int> bytesCaixa = await _generateReceiptBytes(
          itens, orderNumber, totalValue, profile, dadosEmpresa);

      // B. Gera Via da Cozinha Geral (Apenas itens que NÃO são pastel)
      if (listaGeral.isNotEmpty) {
        final bytesCozinhaGeral = await _generateKitchenBytes(
            listaGeral, orderNumber, profile,
            tituloSetor: "COZINHA (GERAL)");

        // Concatena a via da cozinha ao final do cupom do cliente
        bytesCaixa.addAll(bytesCozinhaGeral);
      }

      // Envia tudo para o Caixa de uma vez
      socketCaixa.add(Uint8List.fromList(bytesCaixa));
      await socketCaixa.flush();
      await socketCaixa.close();
      sucessoCaixa = true;
      print("Impressão CAIXA OK.");
    } catch (e) {
      print("ERRO Impressão CAIXA: $e");
    }

    // =========================================================================
    // IMPRESSÃO 2: COZINHA/PASTELARIA (Apenas Pastéis)
    // =========================================================================
    // Só tenta imprimir se houver pastéis e se o IP estiver configurado
    if (listaPasteis.isNotEmpty && ipCozinha != null && ipCozinha.isNotEmpty) {
      try {
        print("Conectando à COZINHA ($ipCozinha)...");
        final socketCozinha = await Socket.connect(ipCozinha, _printerPort,
            timeout: _connectionTimeout);

        final bytesPastelaria = await _generateKitchenBytes(
            listaPasteis, orderNumber, profile,
            tituloSetor: "COZINHA (PASTEL)");

        socketCozinha.add(Uint8List.fromList(bytesPastelaria));
        await socketCozinha.flush();
        await socketCozinha.close();
        sucessoCozinha = true;
        print("Impressão COZINHA OK.");
      } catch (e) {
        print("ERRO Impressão COZINHA: $e");
      }
    }

    return sucessoCaixa;
  }

  // --- VIA DO CLIENTE (DADOS DINÂMICOS DA EMPRESA) ---
  static Future<List<int>> _generateReceiptBytes(
      List<Itens> itens,
      int orderNumber,
      double totalValue,
      CapabilityProfile profile,
      Empresa empresa) async {
    // Recebe o objeto Empresa

    print(empresa.titulo1?.toUpperCase());

    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // --- TÍTULO DINÂMICO ---
    // titulo1: Nome Fantasia (Ex: "LANCHONETE DO ZÉ")
    bytes += generator.text(empresa.titulo1?.toUpperCase() ?? 'LANCHONETE',
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));

    // titulo2: Endereço ou Razão Social
    bytes += generator.text(empresa.titulo2 ?? 'Endereco nao informado',
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

    // Tabela
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

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("   + ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB, align: PosAlign.left));
        }
      }
      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("   + ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  fontType: PosFontType.fontB, align: PosAlign.left));
        }
      }
    }

    bytes += generator.hr();

    // Total
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

  // --- VIA DA COZINHA (Layout Otimizado) ---
  static Future<List<int>> _generateKitchenBytes(
      List<Itens> itens, int orderNumber, CapabilityProfile profile,
      {String tituloSetor = "COZINHA"}) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // Cabeçalho Setorizado (Invertido para destaque)
    bytes += generator.text(tituloSetor,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            reverse: true));
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

      // Layout Linear: Quantidade e Nome em destaque
      bytes += generator.text('${qtd.toInt()}x ${item.nome?.toUpperCase()}',
          styles: const PosStyles(
              height: PosTextSize.size2, width: PosTextSize.size1, bold: true));

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var c in item.complementos!) {
          bytes += generator.text("  [+] ${c.quantidade}x ${c.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true));
        }
      }

      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text("  [+] ${op.quantidade}x ${op.nome}",
              styles: const PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  bold: true));
        }
      }

      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.feed(1);
        bytes += generator.text("  OBS: ${item.obs}",
            styles: const PosStyles(bold: true, reverse: true));
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
