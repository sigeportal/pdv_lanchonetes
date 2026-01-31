import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PrinterConfigPage extends StatefulWidget {
  const PrinterConfigPage({Key? key}) : super(key: key);

  @override
  _PrinterConfigPageState createState() => _PrinterConfigPageState();
}

class _PrinterConfigPageState extends State<PrinterConfigPage> {
  final TextEditingController _ipCaixaController = TextEditingController();
  final TextEditingController _ipCozinhaController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
  }

  // Carrega as configurações salvas no dispositivo
  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Carrega ou define um valor padrão caso não exista
      _ipCaixaController.text =
          prefs.getString('printer_ip_caixa') ?? '192.168.0.100';
      _ipCozinhaController.text =
          prefs.getString('printer_ip_cozinha') ?? '192.168.0.101';
      _isLoading = false;
    });
  }

  // Salva as configurações
  Future<void> _saveSettings() async {
    if (_ipCaixaController.text.isEmpty || _ipCozinhaController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Os campos de IP não podem ficar vazios.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ip_caixa', _ipCaixaController.text.trim());
    await prefs.setString(
        'printer_ip_cozinha', _ipCozinhaController.text.trim());

    Fluttertoast.showToast(msg: "Configurações de impressora salvas!");
    Get.offAndToNamed('principal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Configurar Impressoras',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Salvar Configurações',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              margin: const EdgeInsets.all(50),
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.print, size: 60, color: Colors.grey),
                    const SizedBox(height: 30),

                    // --- IMPRESSORA CAIXA ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Impressora do Caixa (Cupom)",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipCaixaController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP do Caixa',
                        prefixIcon: Icon(Icons.point_of_sale),
                        hintText: 'Ex: 192.168.0.100',
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- IMPRESSORA COZINHA ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Impressora da Cozinha (Produção)",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipCozinhaController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP da Cozinha',
                        prefixIcon: Icon(Icons.restaurant),
                        hintText: 'Ex: 192.168.0.101',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
