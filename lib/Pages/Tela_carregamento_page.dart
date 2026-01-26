import 'package:flutter/material.dart';

class TelaCarregamento extends StatefulWidget {
  final String messageAwait;
  final String messageSuccess;
  final String messageError;
  final bool finalization;

  const TelaCarregamento({
    Key? key,
    required this.messageAwait,
    required this.messageSuccess,
    required this.messageError,
    required this.finalization,
  }) : super(key: key);

  @override
  _TelaCarregamentoState createState() => _TelaCarregamentoState();
}

class _TelaCarregamentoState extends State<TelaCarregamento> {
  bool isLoading = false;
  bool isSuccess = false;

  _aguardando() {
    return Column(
      children: [
        Text(widget.messageAwait),
        Container(
          margin: EdgeInsets.only(top: 20),
          child: CircularProgressIndicator(
            backgroundColor: Colors.amber,
          ),
        )
      ],
    );
  }

  _sucesso() {
    return Column(
      children: [
        Container(
          height: 80,
          child: Image.asset(
            'assets/images/confirmacao.png',
            height: 50,
          ),
        ),
        Text(
          widget.messageSuccess,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  _erro() {
    return Column(
      children: [
        Container(
          height: 80,
          child: Icon(
            Icons.cancel,
            color: Colors.red,
            size: 50,
          ),
        ),
        Text(
          widget.messageError,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Container(
          height: 130,
          margin: EdgeInsets.all(5.0),
          child: Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: !isLoading
                  ? (isSuccess ? _sucesso() : _erro())
                  : _aguardando(),
            ),
          ),
        ),
      ),
    );
  }
}
