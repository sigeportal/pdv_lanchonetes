import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OrderNumberService {
  static const String _keyDate = 'order_date';
  static const String _keyCount = 'order_count';

  /// Gera o próximo número de pedido.
  /// Se o dia mudou, reseta para 1.
  static Future<int> generateNextOrderNumber() async {
    final prefs = await SharedPreferences.getInstance();

    // Data de hoje (apenas dia/mês/ano)
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Data salva
    String? lastDate = prefs.getString(_keyDate);

    int currentOrder = 0;

    if (lastDate != today) {
      // Mudou o dia (ou é a primeira vez), reseta para 1
      currentOrder = 1;
      await prefs.setString(_keyDate, today);
    } else {
      // Mesmo dia, recupera o último e soma 1
      currentOrder = (prefs.getInt(_keyCount) ?? 0) + 1;
    }

    // Salva o novo número
    await prefs.setInt(_keyCount, currentOrder);

    return currentOrder;
  }

  /// Apenas recupera o número atual sem incrementar (útil para reimpressão)
  static Future<int> getCurrentOrderNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCount) ?? 0;
  }
}
