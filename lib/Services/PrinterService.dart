import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Usado apenas para Data/Hora agora
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/empresa_model.dart';
import 'package:lanchonete/Services/EmpresaService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  static const int _printerPort = 9100;
  static const Duration _connectionTimeout = Duration(seconds: 4);

  // --- FORMATAÇÃO MANUAL (RESOLVE O BUG DO 'á' E R$ DUPLO) ---
  static String _formatarMoedaManual(double valor) {
    // Transforma 20.0 em "20.00"
    String temp = valor.toStringAsFixed(2);
    // Troca ponto por virgula: "20,00"
    temp = temp.replaceAll('.', ',');
    // Adiciona o R$ manualmente com espaço normal (ASCII 32)
    return "R\$ $temp";
  }

  // --- REMOVE ACENTOS (RESOLVE O BUG DO 'ç' VIRAR '|') ---
  static String _semAcentos(String str) {
    if (str.isEmpty) return "";
    var comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < comAcento.length; i++) {
      str = str.replaceAll(comAcento[i], semAcento[i]);
    }
    return str;
  }

  static Future<bool> printOrder(
      {required List<Itens> itens,
      required int orderNumber,
      required double totalValue,
      bool isParaLevar = false}) async {
    if (kIsWeb) return false;

    final prefs = await SharedPreferences.getInstance();
    final ipCaixa = prefs.getString('printer_ip_caixa');
    final ipCozinha = prefs.getString('printer_ip_cozinha');

    if (ipCaixa == null || ipCaixa.isEmpty) {
      print("ERRO: IP da impressora do caixa não configurado.");
      return false;
    }

    Empresa dadosEmpresa = await EmpresaService.fetchDadosEmpresa();

    // Carrega perfil padrão para garantir máxima compatibilidade
    CapabilityProfile profile = await CapabilityProfile.load();

    // --- SEPARAÇÃO ---
    bool temPastel = itens.any((item) => _isPastel(item));
    List<Itens> itensGeral = [];
    List<Itens> itensPastel = [];

    if (temPastel) {
      itensPastel =
          itens.where((item) => _isPastel(item) || _isBebida(item)).toList();
      itensGeral =
          itens.where((item) => !_isPastel(item) && !_isBebida(item)).toList();
    } else {
      itensGeral = List.from(itens);
    }

    bool sucesso = false;

    // 1. IMPRESSORA CAIXA
    try {
      final socketCaixa = await Socket.connect(ipCaixa, _printerPort,
          timeout: _connectionTimeout);

      List<int> bytes = await _generateReceiptBytes(
          itens, orderNumber, totalValue, profile, dadosEmpresa);

      if (itensGeral.isNotEmpty) {
        bytes.addAll(await _generateKitchenBytes(
            itensGeral, orderNumber, profile,
            tituloSetor: "COZINHA (GERAL)", isParaLevar: isParaLevar));
      }

      socketCaixa.add(Uint8List.fromList(bytes));
      await socketCaixa.flush();
      await socketCaixa.close();
      sucesso = true;
    } catch (e) {
      print("Erro Caixa: $e");
    }

    // 2. IMPRESSORA COZINHA
    if (itensPastel.isNotEmpty && ipCozinha != null && ipCozinha.isNotEmpty) {
      try {
        final socketCozinha = await Socket.connect(ipCozinha, _printerPort,
            timeout: _connectionTimeout);

        List<int> bytes = await _generateKitchenBytes(
            itensPastel, orderNumber, profile,
            tituloSetor: "COZINHA (PASTEL)", isParaLevar: isParaLevar);

        socketCozinha.add(Uint8List.fromList(bytes));
        await socketCozinha.flush();
        await socketCozinha.close();
      } catch (e) {
        print("Erro Cozinha: $e");
      }
    }

    return sucesso;
  }

  static bool _isPastel(Itens item) =>
      (item.nome ?? '').toLowerCase().contains('pastel');

  static bool _isBebida(Itens item) {
    String nome = (item.nome ?? '').toLowerCase();
    return nome.contains('bebida') ||
        nome.contains('refri') ||
        nome.contains('suco') ||
        nome.contains('agua') ||
        nome.contains('cerveja') ||
        nome.contains('coca') ||
        nome.contains('lata');
  }

  // --- GERADOR CUPOM CLIENTE ---
  static Future<List<int>> _generateReceiptBytes(
      List<Itens> itens,
      int orderNumber,
      double totalValue,
      CapabilityProfile profile,
      Empresa empresa) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.reset();

    // Cabeçalho - Sanitizado
    bytes += generator.text(
        _semAcentos(empresa.titulo1?.toUpperCase() ?? 'LANCHONETE'),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));

    bytes += generator.text(_semAcentos(empresa.titulo2 ?? ''),
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text('SENHA / PEDIDO',
        styles: const PosStyles(align: PosAlign.center));
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

    // Tabela Itens
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
      double valorTotalItem = (item.valor ?? 0);
      if (item.complementos != null) {
        for (var c in item.complementos!)
          valorTotalItem += (c.valor * c.quantidade);
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!)
          valorTotalItem += (op.valorAdicional * op.quantidade);
      }
      double totalLinha = valorTotalItem * qtd;

      // Nome do item sanitizado
      String nomeItem = _semAcentos(item.nome ?? '');

      bytes += generator.row([
        PosColumn(
            text: '${qtd.toInt()}x',
            width: 2,
            styles: const PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(
            text: nomeItem,
            width: 6,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            text: _formatarMoedaManual(totalLinha).replaceAll(
                'R\$ ', ''), // Remove R$ na linha do item para caber melhor
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (item.complementos != null) {
        for (var c in item.complementos!) {
          bytes += generator.text(" + ${c.quantidade}x ${_semAcentos(c.nome!)}",
              styles: const PosStyles(fontType: PosFontType.fontB));
        }
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text(
              " + ${op.quantidade}x ${_semAcentos(op.nome)}",
              styles: const PosStyles(fontType: PosFontType.fontB));
        }
      }
    }

    bytes += generator.hr();

    // Total Final - Usando formatação manual
    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(
          text: _formatarMoedaManual(totalValue), // AQUI: Usa a função manual
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

  // --- VIA COZINHA ---
  static Future<List<int>> _generateKitchenBytes(
      List<Itens> itens, int orderNumber, CapabilityProfile profile,
      {String tituloSetor = "COZINHA", bool isParaLevar = false}) async {
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.reset();

    if (isParaLevar) {
      bytes += generator.text('* VIAGEM / PARA LEVAR *',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              reverse: true));
      bytes += generator.feed(1);
    } else {
      bytes += generator.text('CONSUMO NO LOCAL (MESA)',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              reverse: true));
      bytes += generator.feed(1);
    }

    bytes += generator.text(_semAcentos(tituloSetor),
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
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '=');

    for (var item in itens) {
      double qtd = item.quantidade ?? 1;
      // Sanitiza nome do item
      String nomeItem = _semAcentos(item.nome?.toUpperCase() ?? "");

      bytes += generator.text(
        '${qtd.toInt()}x $nomeItem',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size1,
          bold: true,
        ),
      );

      if (item.complementos != null) {
        for (var c in item.complementos!) {
          bytes += generator.text(
            "  [+] ${c.quantidade}x ${_semAcentos(c.nome!)}",
            styles: const PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size1,
              bold: true,
            ),
          );
        }
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) {
          bytes += generator.text(
            "  [+] ${op.quantidade}x ${_semAcentos(op.nome)}",
            styles: const PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size1,
              bold: true,
            ),
          );
        }
      }
      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.text("  OBS: ${_semAcentos(item.obs!)}",
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
