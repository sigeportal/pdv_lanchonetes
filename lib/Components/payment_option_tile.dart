import 'package:flutter/material.dart';

/// Widget para exibir uma opção de pagamento
class PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const PaymentOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  _listaOptions(bool isHorizontal) {
    return [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 32,
        ),
      ),
      isHorizontal ? SizedBox(height: 12) : SizedBox(width: 12),
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      isHorizontal ? SizedBox(height: 4) : SizedBox(width: 4),
      Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 8),
      Icon(
        Icons.arrow_forward_ios,
        color: Colors.black38,
        size: 18,
      ),
    ];
  }

  _buildOptions(bool isHorizontal) {
    if (isHorizontal) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _listaOptions(isHorizontal),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _listaOptions(isHorizontal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isHorizontal = orientation == Orientation.landscape;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: _buildOptions(isHorizontal),
        ),
      ),
    );
  }
}
