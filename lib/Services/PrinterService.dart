import 'dart:io';
import 'dart:typed_data';
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

  // --- FORMATAÇÃO MANUAL ---
  static String _formatarMoedaManual(double valor) {
    String temp = valor.toStringAsFixed(2);
    temp = temp.replaceAll('.', ',');
    return "R\$ $temp";
  }

  // --- REMOVE ACENTOS ---
  static String _semAcentos(String str) {
    if (str.isEmpty) return "";
    var comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < comAcento.length; i++) {
      str = str.replaceAll(comAcento[i], semAcento[i]);
    }
    return str;
  }

  // --- LÓGICA DE ORDENAÇÃO DE EXTRAS (Tamanho/Unidade Primeiro) ---
  static List<Map<String, dynamic>> _getExtrasOrdenados(Itens item) {
    List<Map<String, dynamic>> extras = [];

    // Adiciona Complementos
    if (item.complementos != null) {
      for (var c in item.complementos!) {
        extras.add({
          'nome': c.nome,
          'qtd': c.quantidade,
          'tipo': 'complemento'
        });
      }
    }

    // Adiciona Opções de Nível
    if (item.opcoesNiveis != null) {
      for (var op in item.opcoesNiveis!) {
        extras.add({
          'nome': op.nome,
          'qtd': op.quantidade,
          'tipo': 'opcao'
        });
      }
    }

    // Palavras-chave que indicam prioridade (Tamanho ou Unidade)
    final prioridades = [
      'TAMANHO', 'TAM', 'UNIDADE', 'UN', 'UNID',
      'PEQUENO', 'MEDIO', 'MÉDIO', 'GRANDE', 'GIGANTE', 'FAMILIA',
      ' P ', ' M ', ' G ', ' GG ', // Espaços para evitar falsos positivos
      '(P)', '(M)', '(G)', '(GG)',
      ' P', ' M', ' G', ' GG' // Fim de frase
    ];

    // Verifica se uma string é prioritária
    bool isPrioridade(String nome) {
      String n = _semAcentos(nome.toUpperCase());
      // Verifica igualdade exata para letras soltas
      if (['P', 'M', 'G', 'GG'].contains(n)) return true;
      
      // Verifica conter palavras-chave
      for (var p in prioridades) {
        if (n.contains(p)) return true;
      }
      return false;
    }

    // Ordena: Prioritários primeiro, o resto mantém a ordem de inserção (estável)
    extras.sort((a, b) {
      bool aPri = isPrioridade(a['nome'] ?? '');
      bool bPri = isPrioridade(b['nome'] ?? '');

      if (aPri && !bPri) return -1; // A vem primeiro
      if (!aPri && bPri) return 1;  // B vem primeiro
      return 0; // Mantém ordem original
    });

    return extras;
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
    CapabilityProfile profile = await CapabilityProfile.load();

    bool temPastel = itens.any((item) => _isPastel(item));
    List<Itens> itensGeral = [];
    List<Itens> itensPastel = [];

    if (temPastel) {
      itensPastel = itens
          .where((item) => _isPastel(item) || _isBebida(item))
          .toList();
      itensGeral = itens
          .where((item) => !_isPastel(item) && !_isBebida(item))
          .toList();
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
            tituloSetor: "COZINHA (GERAL)",
            isParaLevar: isParaLevar));
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
            tituloSetor: "COZINHA (PASTEL)",
            isParaLevar: isParaLevar);
        
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

    bytes += generator.text(
        _semAcentos(empresa.titulo1?.toUpperCase() ?? 'LANCHONETE'),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));

    bytes += generator.text(
        _semAcentos(empresa.titulo2 ?? ''),
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
        for (var c in item.complementos!) valorTotalItem += (c.valor * c.quantidade);
      }
      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) valorTotalItem += (op.valorAdicional * op.quantidade);
      }
      double totalLinha = valorTotalItem * qtd;

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
            text: _formatarMoedaManual(totalLinha).replaceAll('R\$ ', ''),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);

      // --- USANDO A LISTA ORDENADA ---
      List<Map<String, dynamic>> extras = _getExtrasOrdenados(item);
      
      for (var extra in extras) {
        bytes += generator.text(
            " + ${extra['qtd']}x ${_semAcentos(extra['nome'])}",
            styles: const PosStyles(fontType: PosFontType.fontB));
      }
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      PosColumn(
          text: _formatarMoedaManual(totalValue),
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
      bytes += generator.text('*** VIAGEM / PARA LEVAR ***',
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              reverse: true));
      bytes += generator.feed(1);
    } else {
      bytes += generator.text('CONSUMO NO LOCAL (MESA)',
          styles: const PosStyles(align: PosAlign.center, bold: true));
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
      bytes += generator.text('${qtd.toInt()}x ${_semAcentos(item.nome?.toUpperCase() ?? "")}',
          styles: const PosStyles(
              height: PosTextSize.size2, width: PosTextSize.size1, bold: true));

      // --- USANDO A LISTA ORDENADA NA COZINHA ---
      List<Map<String, dynamic>> extras = _getExtrasOrdenados(item);

      for (var extra in extras) {
        bytes += generator.text(
            "  [+] ${extra['qtd']}x ${_semAcentos(extra['nome'])}",
            styles: const PosStyles(bold: true));
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