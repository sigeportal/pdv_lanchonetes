import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img; // Necessário para o gerador
import 'package:lanchonete/Models/itens_model.dart';

class KitchenPrinterService {
  // Configurações da Impressora
  static const String _printerIp = '10.0.0.22';
  static const int _printerPort = 9100;

  /// Função principal para enviar a comanda para a cozinha
  static Future<bool> imprimirComanda(List<Itens> itens) async {
    try {
      // 1. Conectar ao Socket da Impressora
      print("Conectando à impressora $_printerIp:$_printerPort...");
      final socket = await Socket.connect(_printerIp, _printerPort,
          timeout: Duration(seconds: 5));

      // 2. Gerar os comandos ESC/POS
      final List<int> bytes = await _gerarTicket(itens);

      // 3. Enviar dados
      socket.add(Uint8List.fromList(bytes));

      // 4. Fechar conexão e aguardar envio
      await socket.flush();
      socket.close();

      print("Impressão enviada com sucesso!");
      return true;
    } catch (e) {
      print("Erro ao imprimir na cozinha: $e");
      return false;
    }
  }

  /// Gera os bytes (comandos) para a impressora
  static Future<List<int>> _gerarTicket(List<Itens> itens) async {
    // Carrega o perfil da impressora (Padrão)
    final profile = await CapabilityProfile.load();
    // PaperSize.mm80 define a largura de 80mm (aprox 48 colunas)
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // --- CABEÇALHO ---
    bytes += generator.text('COZINHA',
        styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2, // Altura Dupla
            width: PosTextSize.size2, // Largura Dupla
            bold: true));

    bytes += generator.text(
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        styles: PosStyles(align: PosAlign.center));

    bytes += generator.hr(); // Linha separadora
    bytes += generator.feed(1);

    // --- LISTA DE ITENS ---
    for (var item in itens) {
      double qtd = item.quantidade ?? 1;
      String nomeProduto = item.nome ?? "Item sem nome";

      // Formata a quantidade (ex: "2x" ou "1.5x")
      String qtdStr = (qtd % 1 == 0) ? qtd.toInt().toString() : qtd.toString();

      // Imprime: 2x HAMBURGUER
      bytes += generator.row([
        PosColumn(
          text: '${qtdStr}x',
          width: 2, // Coluna estreita para quantidade
          styles: PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
        ),
        PosColumn(
          text: nomeProduto,
          width: 10, // Resto da largura
          styles: PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
        ),
      ]);

      // --- COMPLEMENTOS ---
      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var comp in item.complementos!) {
          bytes += generator.text("   + ${comp.quantidade}x ${comp.nome}",
              styles: PosStyles(bold: false) // Fonte normal para complementos
              );
        }
      }

      // --- OBSERVAÇÕES (Destaque) ---
      if (item.obs != null && item.obs!.isNotEmpty) {
        bytes += generator.text("   *** OBS: ${item.obs} ***",
            styles: PosStyles(
                bold: true,
                reverse:
                    true) // Fundo preto, letra branca (se suportado) ou negrito
            );
      }

      bytes += generator.feed(1); // Espaço entre itens
      bytes += generator.hr(ch: '-'); // Linha tracejada entre itens
    }

    // --- RODAPÉ ---
    bytes += generator.feed(2);
    bytes += generator.text('FIM DO PEDIDO',
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(3);

    // Comando de Corte de Papel
    bytes += generator.cut();

    return bytes;
  }
}
