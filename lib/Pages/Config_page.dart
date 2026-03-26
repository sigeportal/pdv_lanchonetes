import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Pages/Login_page.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  String? _urlBase;
  bool _useTables = false;
  int _tableCount = 0;

  @override
  void initState() {
    super.initState();
    _urlBase = ConfigController.instance.baseURL.value;
    _useTables = ConfigController.instance.useTables.value;
    _tableCount = ConfigController.instance.tableCount.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Configurações',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () {
              // Salva todas as configurações de uma vez
              ConfigController.instance
                  .saveConfig(_urlBase, _useTables, _tableCount);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(50),
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Campo do IP do Servidor
              TextFormField(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                initialValue: _urlBase,
                keyboardType: TextInputType.number,
                onChanged: (String url) {
                  _urlBase = url;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'IP do Servidor',
                ),
              ),

              SizedBox(height: 30), // Espaçamento

              // Opção de usar mesas e comandas
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Usar mesas e comandas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Ative para gerenciar pedidos por mesa'),
                  value: _useTables,
                  onChanged: (bool value) {
                    setState(() {
                      _useTables = value;
                    });
                  },
                ),
              ),

              // Campo de Quantidade de Mesas (Só aparece se o switch estiver ativado)
              if (_useTables) ...[
                SizedBox(height: 30),
                TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  initialValue: _tableCount > 0 ? _tableCount.toString() : '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (String count) {
                    _tableCount = int.tryParse(count) ?? 0;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Quantidade de Mesas',
                    helperText: 'Ex: 15',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
