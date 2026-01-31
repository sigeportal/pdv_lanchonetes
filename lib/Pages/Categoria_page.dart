import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Imports do seu projeto
import 'package:lanchonete/Components/ProdutoItem.dart';
import 'package:lanchonete/Components/complementos_widget.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Models/categoria_model.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';
import 'package:lanchonete/Services/ProdutosService.dart';
import 'package:lanchonete/Services/CategoriaService.dart';
// import 'package:lanchonete/Services/CupomFiscalService.dart'; // Import opcional

class CategoriaPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CategoriaPage({Key? key, this.onOpenDrawer}) : super(key: key);

  @override
  _CategoriaPageState createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage> {
  final _serviceProdutos = ProdutosService();
  final _formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Categoria> _categorias = [];
  List<Produtos> _produtos = [];
  int? _selectedCategoriaId;

  bool _isLoadingProdutos = false;
  bool _isLoadingCategorias = true;
  String? _erroMensagem;

  final ScrollController _produtosScrollController = ScrollController();
  final ScrollController _comandaScrollController = ScrollController();
  final ScrollController _categoriasScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();
    });
  }

  @override
  void dispose() {
    _produtosScrollController.dispose();
    _comandaScrollController.dispose();
    _categoriasScrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoadingCategorias = true;
      _erroMensagem = null;
    });

    try {
      final categorias = await fetchCategorias();
      if (mounted) {
        setState(() {
          _categorias = categorias;
          _isLoadingCategorias = false;
        });

        if (categorias.isNotEmpty) {
          _selecionarCategoria(categorias[0].codigo);
        } else {
          setState(() => _erroMensagem = "Nenhuma categoria encontrada.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategorias = false;
          _erroMensagem = "Erro de conexão com o servidor.";
        });
      }
    }
  }

  void _selecionarCategoria(int? idCategoria) async {
    if (_selectedCategoriaId == idCategoria) return;

    setState(() {
      _selectedCategoriaId = idCategoria;
      _isLoadingProdutos = true;
    });

    try {
      String filtro = idCategoria != null ? '?categoria=$idCategoria' : '';
      final produtos = await _serviceProdutos.fetchProdutos(filtro);

      if (mounted) {
        setState(() {
          _produtos = produtos;
          _isLoadingProdutos = false;
        });
        if (_produtosScrollController.hasClients) {
          _produtosScrollController.jumpTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _produtos = [];
          _isLoadingProdutos = false;
        });
      }
    }
  }

  Future<bool> _confirmarExclusao(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Remover Item",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
                "Tem certeza que deseja remover este item do carrinho?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR",
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("REMOVER",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildCategoriaTab(Categoria item) {
    bool isSelected = _selectedCategoriaId == item.codigo;
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selecionarCategoria(item.codigo),
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber[600] : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: isSelected ? Colors.amber[600]! : Colors.grey[300]!,
                  width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                item.nome ?? '',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogoArea() {
    if (_erroMensagem != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_erroMensagem!),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _carregarDadosIniciais,
                child: const Text("Tentar Novamente"))
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: const Color(0xFFF5F5F7),
          child: _isLoadingCategorias
              ? const Center(child: CircularProgressIndicator())
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView.builder(
                    controller: _categoriasScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) =>
                        _buildCategoriaTab(_categorias[index]),
                  ),
                ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F7),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoadingProdutos
                ? Center(
                    child: CircularProgressIndicator(color: Colors.amber[700]))
                : _produtos.isEmpty
                    ? const Center(
                        child: Text("Nenhum produto nesta categoria"))
                    : Scrollbar(
                        controller: _produtosScrollController,
                        thumbVisibility: true,
                        radius: const Radius.circular(8),
                        child: GridView.builder(
                          controller: _produtosScrollController,
                          padding: const EdgeInsets.only(
                              bottom: 40, top: 10, left: 4, right: 4),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _produtos.length,
                          itemBuilder: (context, index) {
                            return ProdutoItem(
                              produto: _produtos[index],
                              categoria: _selectedCategoriaId ?? 0,
                            );
                          },
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildComandaItem(Itens item, ComandaController controller) {
    double valorBaseUnitario = item.valor ?? 0;
    double valorAdicionaisUnitario = 0;

    if (item.complementos != null) {
      for (var comp in item.complementos!) {
        valorAdicionaisUnitario += (comp.valor * comp.quantidade);
      }
    }

    if (item.opcoesNiveis != null) {
      for (var op in item.opcoesNiveis!) {
        valorAdicionaisUnitario += (op.valorAdicional * op.quantidade);
      }
    }

    double valorTotalLinha =
        (valorBaseUnitario + valorAdicionaisUnitario) * (item.quantidade ?? 1);

    return Dismissible(
      key: Key("item_${item.codigo}_${DateTime.now().millisecondsSinceEpoch}"),
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.red[100],
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 15),
          child: const Icon(Icons.delete, color: Colors.red)),
      confirmDismiss: (direction) async {
        return await _confirmarExclusao(context);
      },
      onDismissed: (_) => controller.removeItemCarrinho(item),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            List<Nivel>? niveis;
            try {
              niveis = await _serviceProdutos.getNiveis(item.produto ?? 0);
            } catch (e) {
              print('Erro ao buscar niveis: $e');
            }

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => SelecaoOpcoesProdutoWidget(
                  item: item,
                  niveis: niveis,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nome ?? 'Produto',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        bool confirmar = await _confirmarExclusao(context);
                        if (confirmar) {
                          controller.removeItemCarrinho(item);
                        }
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${item.quantidade}x  ${_formatMoeda.format(valorBaseUnitario)}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Text(_formatMoeda.format(valorTotalLinha),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                if (item.complementos != null && item.complementos!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.complementos!
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text(
                                            "+ ${c.nome} (${c.quantidade}x)",
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis)),
                                    Text(
                                        "${_formatMoeda.format(c.valor * c.quantidade)}",
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.opcoesNiveis!
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text(
                                            "+ ${c.nome} (${c.quantidade}x)",
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis)),
                                    Text(
                                        "${_formatMoeda.format(c.valorAdicional * c.quantidade)}",
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                if (item.obs != null && item.obs!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(item.obs!,
                            style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComandaSidebar() {
    return Consumer<ComandaController>(
      builder: (context, controller, _) {
        double totalItens = controller.itens
            .fold(0, (sum, item) => sum + (item.quantidade ?? 0));

        return Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber[500],
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text("PEDIDO ATUAL",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                          totalItens % 1 == 0
                              ? totalItens.toInt().toString()
                              : totalItens.toStringAsFixed(1),
                          style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: controller.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 50, color: Colors.grey[300]),
                        Text("Carrinho Vazio",
                            style: TextStyle(color: Colors.grey[400]))
                      ]))
                    : Scrollbar(
                        controller: _comandaScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _comandaScrollController,
                          itemCount: controller.itens.length,
                          itemBuilder: (context, index) => _buildComandaItem(
                              controller.itens[index], controller),
                        ),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        const Border(top: BorderSide(color: Colors.black12))),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("TOTAL",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              Text(_formatMoeda.format(controller.valorComanda),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold))
                            ]),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600]),
                            onPressed: controller.isEmpty
                                ? null
                                : () async {
                                    //Vai para pagamento
                                    await Navigator.pushNamed(
                                      context,
                                      '/payment_mode',
                                      arguments: {
                                        'valorPagamento':
                                            controller.valorComanda,
                                      },
                                    );
                                  },
                            child: const Text("FINALIZAR",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            // CORREÇÃO CRUCIAL PARA TABLET:
            // Remove o foco do teclado antes de tentar abrir o menu
            FocusScope.of(context).unfocus();

            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              // Fallback caso a navegação tenha sido feita incorretamente
              try {
                Scaffold.of(context).openDrawer();
              } catch (_) {}
            }
          },
        ),
        title: const Text("PDV / Vendas",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _carregarDadosIniciais),
        ],
      ),
      body: Row(
        children: [
          Expanded(child: _buildCatalogoArea()),
          _buildComandaSidebar(),
        ],
      ),
    );
  }
}
