import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/complementos_model.dart';

class SelecaoComplementoWidget extends StatefulWidget {
  final Itens item;

  const SelecaoComplementoWidget({Key? key, required this.item})
      : super(key: key);

  @override
  _SelecaoComplementoWidgetState createState() =>
      _SelecaoComplementoWidgetState();
}

class _SelecaoComplementoWidgetState extends State<SelecaoComplementoWidget> {
  final _formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Lista temporária dos complementos selecionados nesta tela
  List<Complementos> _complementosSelecionados = [];

  // MOCK: Lista de complementos disponíveis (Substitua pela sua API)
  // Exemplo: final complementosDisponiveis = await service.getComplementos(widget.item.produto);
  final List<Complementos> _complementosDisponiveis = [
    Complementos(codigo: 1, nome: "Bacon Extra", valor: 3.50, quantidade: 0),
    Complementos(codigo: 2, nome: "Queijo Cheddar", valor: 2.00, quantidade: 0),
    Complementos(codigo: 3, nome: "Ovo", valor: 1.50, quantidade: 0),
    Complementos(codigo: 4, nome: "Maionese Verde", valor: 0.00, quantidade: 0),
    Complementos(
        codigo: 5, nome: "Cebola Caramelizada", valor: 2.50, quantidade: 0),
  ];

  @override
  void initState() {
    super.initState();
    // Carrega os complementos que o item já possui (para edição)
    if (widget.item.complementos != null) {
      // Clona a lista para não alterar o original antes de salvar
      _complementosSelecionados = List.from(widget.item.complementos!);

      // Atualiza as quantidades na lista de disponíveis para refletir o que já tem
      for (var selecionado in _complementosSelecionados) {
        var index = _complementosDisponiveis
            .indexWhere((c) => c.codigo == selecionado.codigo);
        if (index != -1) {
          _complementosDisponiveis[index].quantidade = selecionado.quantidade;
        }
      }
    }
  }

  void _atualizarQuantidade(Complementos complemento, int delta) {
    setState(() {
      int novaQtd = (complemento.quantidade!) + delta;
      if (novaQtd < 0) novaQtd = 0;
      complemento.quantidade = novaQtd;

      // Atualiza a lista de selecionados
      _complementosSelecionados
          .removeWhere((c) => c.codigo == complemento.codigo);
      if (novaQtd > 0) {
        _complementosSelecionados.add(complemento);
      }
    });
  }

  void _salvar() {
    // Chama o controller para atualizar o item
    Provider.of<ComandaController>(context, listen: false)
        .adicionaComplementos(widget.item.codigo, _complementosSelecionados);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.amber, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Adicionais para ${widget.item.nome}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),

            // Lista de Opções
            Expanded(
              child: ListView.separated(
                itemCount: _complementosDisponiveis.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final comp = _complementosDisponiveis[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comp.nome!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            Text("+ ${_formatMoeda.format(comp.valor)}",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                        Row(
                          children: [
                            _btnCirculo(
                                icon: Icons.remove,
                                color: Colors.grey[200]!,
                                onTap: () => _atualizarQuantidade(comp, -1)),
                            Container(
                              width: 35,
                              alignment: Alignment.center,
                              child: Text(
                                "${comp.quantidade}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            _btnCirculo(
                                icon: Icons.add,
                                color: Colors.amber[100]!,
                                colorIcon: Colors.amber[900],
                                onTap: () => _atualizarQuantidade(comp, 1)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botão Salvar
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _salvar,
                child: const Text("SALVAR ADICIONAIS",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _btnCirculo(
      {required IconData icon,
      required Color color,
      Color? colorIcon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: colorIcon ?? Colors.black87),
      ),
    );
  }
}
