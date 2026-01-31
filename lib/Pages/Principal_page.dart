import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Pages/Categoria_page.dart';
import 'package:lanchonete/Pages/Config_page.dart';
import 'package:lanchonete/Pages/Consulta_Produtos_page.dart';
import 'package:lanchonete/Pages/Home_page.dart';
import 'package:lanchonete/Pages/PrintersConfigPage.dart';
import 'package:flutter/material.dart';

enum Paginas { home, categorias, consultaProdutos, configuracao, impressoras }

class PrincipalPage extends StatefulWidget {
  final Paginas paginas;

  const PrincipalPage({Key? key, required this.paginas}) : super(key: key);

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  late int _selectedIndex;

  // Chave global para controlar o Scaffold (Menu Lateral)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Inicializa o índice com base no parâmetro passado
    _selectedIndex = widget.paginas.index;
  }

  // Função segura para abrir o Drawer
  void _openDrawer() {
    // Garante que o teclado seja fechado antes de abrir o menu
    FocusScope.of(context).unfocus();

    // Pequeno delay para garantir que o teclado sumiu e o estado está montado
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scaffoldKey.currentState != null) {
        _scaffoldKey.currentState!.openDrawer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recriamos a lista no build para garantir que os callbacks estejam sempre atualizados
    final List<Widget> _paginas = <Widget>[
      HomePage(),
      // AQUI ESTÁ O SEGREDO: Passamos a função _openDrawer atualizada
      CategoriaPage(onOpenDrawer: _openDrawer),
      ConsultaProdutosPage(),
      ConfigPage(),
      PrinterConfigPage()
    ];

    bool isCategoriaPage = _selectedIndex == 1;

    return Scaffold(
      key: _scaffoldKey, // Vincula a chave ao Scaffold
      appBar: isCategoriaPage
          ? null // CategoriaPage tem sua própria AppBar
          : AppBar(
              title: Text(
                _titulos[_selectedIndex],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Constants.primaryColor,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Constants.primaryColor,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child:
                    Icon(Icons.store, color: Constants.primaryColor, size: 40),
              ),
              accountName: const Text(
                "PDV Lanchonete",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Operador do Caixa"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    text: 'Home',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale_rounded,
                    text: 'Realizar Venda',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.price_check_rounded,
                    text: 'Consultar Preço',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    text: 'Configurações',
                    isSelected: _selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                  _buildDrawerItem(
                    icon: Icons.print_rounded,
                    text: 'Impressoras',
                    isSelected: _selectedIndex == 4,
                    onTap: () => _onItemTapped(4),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Versão 1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: _paginas.elementAt(_selectedIndex),
    );
  }

  // Lista de Títulos
  final List<String> _titulos = [
    'Home',
    'Vendas',
    'Consultar Preço',
    'Configurações',
    'Impressoras'
  ];

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Constants.primaryColor : Colors.grey[600],
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? Constants.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Constants.primaryColor.withOpacity(0.1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      onTap: onTap,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Fecha o Drawer ao selecionar
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }
}
