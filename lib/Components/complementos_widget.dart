import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';

class SelecaoOpcoesProdutoWidget extends StatefulWidget {
  final Itens item;
  final List<Nivel>? niveis;

  const SelecaoOpcoesProdutoWidget({
    Key? key,
    required this.item,
    this.niveis,
  }) : super(key: key);

  @override
  _SelecaoOpcoesProdutoWidgetState createState() =>
      _SelecaoOpcoesProdutoWidgetState();
}

class _SelecaoOpcoesProdutoWidgetState
    extends State<SelecaoOpcoesProdutoWidget> {
  final _formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  late List<Nivel> _niveis;
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _inicializarNiveis();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _inicializarNiveis() {
    // Se houver niveis fornecidos
    if (widget.niveis != null && widget.niveis!.isNotEmpty) {
      _niveis = widget.niveis!.map((nivel) {
        // Criar cópia dos niveis com opções clonadas
        final novasOpcoes = nivel.opcoes.map((opcao) {
          return OpcaoNivel(
            codigo: opcao.codigo,
            nome: opcao.nome,
            valorAdicional: opcao.valorAdicional,
            ativo: opcao.ativo,
            ativoStr: opcao.ativoStr,
            codNivel: opcao.codNivel,
            selecionado: false,
            quantidade: 0,
          );
        }).toList();

        return Nivel(
          codigo: nivel.codigo,
          titulo: nivel.titulo,
          descricao: nivel.descricao,
          selecaoMin: nivel.selecaoMin,
          selecaoMax: nivel.selecaoMax,
          opcoes: novasOpcoes,
          codProduto: nivel.codProduto,
        );
      }).toList();
    } else {
      _niveis = [];
    }

    // Restaura seleções anteriores se existirem
    if (widget.item.opcoesNiveis != null) {
      _restaurarSelecoes();
    }

    // Gerar chaves para scroll
    for (var i = 0; i < _niveis.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  void _restaurarSelecoes() {
    for (var salvo in widget.item.opcoesNiveis!) {
      for (var nivel in _niveis) {
        var indiceOpcao =
            nivel.opcoes.indexWhere((o) => o.codigo == salvo.codigo);
        if (indiceOpcao != -1) {
          var opcao = nivel.opcoes[indiceOpcao];
          if (nivel.selecaoMax == 1) {
            // Escolha única
            for (var o in nivel.opcoes) o.selecionado = false;
            opcao.selecionado = true;
          } else {
            // Múltipla escolha
            opcao.quantidade = salvo.quantidade ?? 1;
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

  void _selecionarOpcaoUnica(int nivelIndex, OpcaoNivel opcao) {
    setState(() {
      final nivel = _niveis[nivelIndex];
      for (var op in nivel.opcoes) {
        op.selecionado = (op == opcao);
      }
    });
    _rolarParaProximoGrupo(nivelIndex);
  }

  void _atualizarQuantidade(OpcaoNivel opcao, int delta) {
    setState(() {
      int novaQtd = opcao.quantidade + delta;
      if (novaQtd >= 0) {
        opcao.quantidade = novaQtd;
      }
    });
  }

  double _calcularTotalAdicionais() {
    double total = 0;
    for (var nivel in _niveis) {
      for (var op in nivel.opcoes) {
        if (nivel.selecaoMax == 1 && op.selecionado) {
          total += op.valorAdicional;
        } else if (nivel.selecaoMax > 1 && op.quantidade > 0) {
          total += (op.valorAdicional * op.quantidade);
        }
      }
    }
    return total;
  }

  void _salvar() {
    List<OpcaoNivel> listaFinal = [];

    for (var nivel in _niveis) {
      if (nivel.selecaoMax == 1) {
        // Escolha única
        var selecionado = nivel.opcoes.firstWhere((o) => o.selecionado,
            orElse: () => OpcaoNivel(
                  codigo: -1,
                  nome: '',
                  valorAdicional: 0,
                  ativo: false,
                  ativoStr: 'N',
                  codNivel: nivel.codigo,
                ));

        if (selecionado.codigo != -1) {
          listaFinal.add(OpcaoNivel(
            codigo: selecionado.codigo,
            nome: "${nivel.titulo}: ${selecionado.nome}",
            valorAdicional: selecionado.valorAdicional,
            codNivel: selecionado.codNivel,
            ativo: selecionado.ativo,
            ativoStr: selecionado.ativoStr,
            quantidade: 1,
          ));
        }
      } else {
        // Múltipla escolha
        for (var op in nivel.opcoes) {
          if (op.quantidade > 0) {
            listaFinal.add(OpcaoNivel(
              codigo: op.codigo,
              nome: "${nivel.titulo}: ${op.nome}",
              valorAdicional: op.valorAdicional,
              codNivel: op.codNivel,
              ativo: op.ativo,
              ativoStr: op.ativoStr,
              quantidade: op.quantidade,
            ));
          }
        }
      }
    }

    Provider.of<ComandaController>(context, listen: false)
        .adicionaOpcoesNivel(widget.item.codigo, listaFinal);

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

            // LISTA DE NIVEIS
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _niveis.length,
                itemBuilder: (context, index) {
                  return _buildNivelContainer(index);
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

  Widget _buildNivelContainer(int index) {
    final nivel = _niveis[index];

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
                      nivel.titulo.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 13,
                          letterSpacing: 0.5),
                    ),
                    Text(
                      nivel.descricao,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (nivel.selecaoMin > 0)
                      Text(
                        "Mínimo: ${nivel.selecaoMin} | Máximo: ${nivel.selecaoMax}",
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      )
                  ],
                ),
              ],
            ),
          ),
          ...nivel.opcoes.map((opcao) {
            return nivel.selecaoMax == 1
                ? _buildRadioOption(index, nivel, opcao)
                : _buildCounterOption(opcao);
          }).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRadioOption(int nivelIndex, Nivel nivel, OpcaoNivel opcao) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _selecionarOpcaoUnica(nivelIndex, opcao),
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

  Widget _buildCounterOption(OpcaoNivel opcao) {
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
