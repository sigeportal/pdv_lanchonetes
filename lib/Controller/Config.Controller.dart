import 'package:lanchonete/Interfaces/Local_Storage.Interface.dart';
import 'package:lanchonete/Services/Local_storage.Service.dart';
import 'package:flutter/material.dart';

class ConfigController {
  static final ConfigController instance = ConfigController._();
  final ILocalStorage storage = LocalStorageService();

  final baseURL = ValueNotifier<String?>('');
  final useTables = ValueNotifier<bool>(false);
  final tableCount = ValueNotifier<int>(0);

  Future<String> getUrlBase() async {
    if (baseURL.value != '') {
      return 'http://${baseURL.value}:9000';
    }
    await getConfig();
    return 'http://${baseURL.value}:9000';
  }

  ConfigController._() {
    getConfig();
  }

  getConfig() async {
    // Busca o IP
    var url = await storage.get('urlBase');
    if (url != null) {
      baseURL.value = url.toString();
    }

    // Busca a configuração de mesas
    var savedUseTables = await storage.get('useTables');
    if (savedUseTables != null) {
      useTables.value = savedUseTables == true || savedUseTables == 'true';
    }

    // Busca a quantidade de mesas
    var savedTableCount = await storage.get('tableCount');
    if (savedTableCount != null) {
      tableCount.value = int.tryParse(savedTableCount.toString()) ?? 0;
    }
  }

  saveConfig(String? url, bool useTablesValue, int tableCountValue) {
    // Atualiza a memória
    baseURL.value = url;
    useTables.value = useTablesValue;
    tableCount.value = tableCountValue;

    // Salva no armazenamento local (convertendo para string para evitar erros no DB local)
    storage.put('urlBase', url);
    storage.put('useTables', useTablesValue.toString());
    storage.put('tableCount', tableCountValue.toString());
  }
}
