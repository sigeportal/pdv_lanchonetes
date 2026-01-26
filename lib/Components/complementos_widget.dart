import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/complementos_model.dart';

// Modelos Auxiliares
class GrupoModificacao {
  final String titulo;
  final bool escolhaUnica;
  final bool obrigatorio;
  final int maximo;
  final List<OpcaoModificacao> opcoes;

  GrupoModificacao({
    required this.titulo,
    required this.escolhaUnica,
    this.obrigatorio = false,
    this.maximo = 1,
    required this.opcoes,
  });
}

class OpcaoModificacao {
  final int codigo;
  final String nome;
  final double valorAdicional;
  bool selecionado;
  int quantidade;

  OpcaoModificacao({
    required this.codigo,
    required this.nome,
    required this.valorAdicional,
    this.selecionado = false,
    this.quantidade = 0,
  });
}

class SelecaoOpcoesProdutoWidget extends StatefulWidget {
  final Itens item;

  const SelecaoOpcoesProdutoWidget({Key? key, required this.item})
      : super(key: key);

  @override
  _SelecaoOpcoesProdutoWidgetState createState() =>
      _SelecaoOpcoesProdutoWidgetState();
}

class _SelecaoOpcoesProdutoWidgetState
    extends State<SelecaoOpcoesProdutoWidget> {
  final _formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<GrupoModificacao> _grupos = [];
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosMockados();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _carregarDadosMockados() {
    _grupos = [
      GrupoModificacao(
        titulo: "Escolha a Proteína",
        escolhaUnica: true,
        obrigatorio: true,
        opcoes: [
          OpcaoModificacao(
              codigo: 101,
              nome: "Filé de Frango",
              valorAdicional: 0.0,
              selecionado: true),
          OpcaoModificacao(
              codigo: 102,
              nome: "Filé Mignon",
              valorAdicional: 8.0), // Valor +8
          OpcaoModificacao(codigo: 103, nome: "Tilápia", valorAdicional: 4.0),
        ],
      ),
      GrupoModificacao(
        titulo: "Ponto da Carne",
        escolhaUnica: true,
        obrigatorio: true,
        opcoes: [
          OpcaoModificacao(codigo: 201, nome: "Ao Ponto", valorAdicional: 0.0),
          OpcaoModificacao(
              codigo: 202, nome: "Bem Passada", valorAdicional: 0.0),
          OpcaoModificacao(
              codigo: 203, nome: "Mal Passada", valorAdicional: 0.0),
        ],
      ),
      GrupoModificacao(
        titulo: "Escolha o Molho",
        escolhaUnica: true,
        obrigatorio: true,
        opcoes: [
          OpcaoModificacao(
              codigo: 301, nome: "Molho Sugo", valorAdicional: 3.0), // Valor +3
          OpcaoModificacao(
              codigo: 302, nome: "Molho Branco", valorAdicional: 0.0),
          OpcaoModificacao(
              codigo: 303, nome: "Molho Rosê", valorAdicional: 0.0),
        ],
      ),
      GrupoModificacao(
        titulo: "Adicionais e Extras",
        escolhaUnica: false,
        obrigatorio: false,
        maximo: 10,
        opcoes: [
          OpcaoModificacao(
              codigo: 1, nome: "Bacon Extra", valorAdicional: 3.50),
          OpcaoModificacao(
              codigo: 2, nome: "Queijo Cheddar", valorAdicional: 2.00),
          OpcaoModificacao(codigo: 3, nome: "Ovo Frito", valorAdicional: 1.50),
          OpcaoModificacao(
              codigo: 4, nome: "Arroz Extra", valorAdicional: 4.00),
          OpcaoModificacao(
              codigo: 5, nome: "Batata Frita Extra", valorAdicional: 6.00),
        ],
      ),
    ];

    for (var i = 0; i < _grupos.length; i++) {
      _keys.add(GlobalKey());
    }

    // Restaura seleções anteriores
    if (widget.item.complementos != null) {
      for (var salvo in widget.item.complementos!) {
        for (var grupo in _grupos) {
          var opcao = grupo.opcoes.firstWhere((o) => o.codigo == salvo.codigo,
              orElse: () =>
                  OpcaoModificacao(codigo: -1, nome: '', valorAdicional: 0));

          if (opcao.codigo != -1) {
            if (grupo.escolhaUnica) {
              for (var o in grupo.opcoes) o.selecionado = false;
              opcao.selecionado = true;
            } else {
              opcao.quantidade = salvo.quantidade!;
            }
          }
        }
      }
    }
  }

  void _rolarParaProximoGrupo(int indexAtual) {
    if (indexAtual + 1 < _keys.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_keys[indexAtual + 1].currentContext != null) {
          Scrollable.ensureVisible(
            _keys[indexAtual + 1].currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.05,
          );
        }
      });
    }
  }

  void _selecionarOpcaoUnica(int grupoIndex, OpcaoModificacao opcao) {
    setState(() {
      final grupo = _grupos[grupoIndex];
      for (var op in grupo.opcoes) {
        op.selecionado = (op == opcao);
      }
    });
    _rolarParaProximoGrupo(grupoIndex);
  }

  void _atualizarQuantidade(OpcaoModificacao opcao, int delta) {
    setState(() {
      int novaQtd = opcao.quantidade + delta;
      if (novaQtd >= 0) {
        opcao.quantidade = novaQtd;
      }
    });
  }

  double _calcularTotalAdicionais() {
    double total = 0;
    for (var grupo in _grupos) {
      for (var op in grupo.opcoes) {
        if (grupo.escolhaUnica && op.selecionado) {
          total += op.valorAdicional;
        } else if (!grupo.escolhaUnica && op.quantidade > 0) {
          total += (op.valorAdicional * op.quantidade);
        }
      }
    }
    return total;
  }

  void _salvar() {
    List<Complementos> listaFinal = [];

    // 1. Salva Escolhas Únicas (Radio)
    for (var grupo in _grupos) {
      if (grupo.escolhaUnica) {
        var selecionado = grupo.opcoes.firstWhere((o) => o.selecionado,
            orElse: () =>
                OpcaoModificacao(codigo: -1, nome: '', valorAdicional: 0));

        if (selecionado.codigo != -1) {
          // Cria o complemento com o valor correto
          listaFinal.add(Complementos(
              codigo: selecionado.codigo,
              nome: "${grupo.titulo}: ${selecionado.nome}",
              valor: selecionado.valorAdicional, // AQUI ESTÁ O VALOR (+8.00)
              quantidade: 1));
        }
      } else {
        // 2. Salva Escolhas Múltiplas (Contador)
        for (var op in grupo.opcoes) {
          if (op.quantidade > 0) {
            listaFinal.add(Complementos(
                codigo: op.codigo,
                nome: op.nome,
                valor: op.valorAdicional, // AQUI ESTÁ O VALOR (+3.50)
                quantidade: op.quantidade));
          }
        }
      }
    }

    // Envia para o controller atualizar a lista principal
    Provider.of<ComandaController>(context, listen: false)
        .adicionaComplementos(widget.item.codigo, listaFinal);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.nome ?? "Detalhes do Item",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text("Personalize ao seu gosto",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // LISTA DE GRUPOS
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _grupos.length,
                itemBuilder: (context, index) {
                  return _buildGrupoContainer(index);
                },
              ),
            ),

            // FOOTER (TOTAL + BOTÃO)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Total Adicionais",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        _formatMoeda.format(_calcularTotalAdicionais()),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.green[700]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0),
                    onPressed: _salvar,
                    child: const Text("CONFIRMAR",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrupoContainer(int index) {
    final grupo = _grupos[index];

    return Container(
      key: _keys[index],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.titulo.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 13,
                          letterSpacing: 0.5),
                    ),
                    if (grupo.escolhaUnica)
                      Text("Escolha 1 opção",
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]))
                  ],
                ),
                if (grupo.obrigatorio)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text("OBRIGATÓRIO",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          ...grupo.opcoes.map((opcao) {
            return grupo.escolhaUnica
                ? _buildRadioOption(index, grupo, opcao)
                : _buildCounterOption(opcao);
          }).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
      int grupoIndex, GrupoModificacao grupo, OpcaoModificacao opcao) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _selecionarOpcaoUnica(grupoIndex, opcao),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opcao.nome,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87)),
                    if (opcao.valorAdicional > 0)
                      Text("+ ${_formatMoeda.format(opcao.valorAdicional)}",
                          style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 13))
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: opcao.selecionado
                          ? Colors.amber[700]!
                          : Colors.grey[400]!,
                      width: 2),
                ),
                child: opcao.selecionado
                    ? Center(
                        child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.amber[700],
                                shape: BoxShape.circle)))
                    : null,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterOption(OpcaoModificacao opcao) {
    bool ativo = opcao.quantidade > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opcao.nome,
                    style: TextStyle(
                        fontSize: 16,
                        color: ativo ? Colors.black87 : Colors.grey[700],
                        fontWeight:
                            ativo ? FontWeight.w500 : FontWeight.normal)),
                if (opcao.valorAdicional > 0)
                  Text("+ ${_formatMoeda.format(opcao.valorAdicional)}",
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13))
              ],
            ),
          ),
          Row(
            children: [
              if (ativo) ...[
                _btnAcao(
                    icon: Icons.remove,
                    color: Colors.white,
                    borderColor: Colors.grey[300]!,
                    iconColor: Colors.grey[600]!,
                    onTap: () => _atualizarQuantidade(opcao, -1)),
                Container(
                  width: 35,
                  alignment: Alignment.center,
                  child: Text("${opcao.quantidade}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
              _btnAcao(
                  icon: Icons.add,
                  color: ativo ? Colors.white : Colors.white,
                  borderColor: ativo ? Colors.amber[600]! : Colors.grey[300]!,
                  iconColor: ativo ? Colors.amber[700]! : Colors.grey[600]!,
                  onTap: () => _atualizarQuantidade(opcao, 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _btnAcao(
      {required IconData icon,
      required Color color,
      required Color borderColor,
      required Color iconColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5)),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
