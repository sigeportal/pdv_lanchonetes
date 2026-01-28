import 'package:flutter/material.dart';

class PastelarioLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const PastelarioLogo({
    Key? key,
    this.size = 200,
    this.withText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, withText ? size * 1.3 : size),
      painter: PastelarioLogoPainter(withText: withText),
    );
  }
}

class PastelarioLogoPainter extends CustomPainter {
  final bool withText;

  PastelarioLogoPainter({required this.withText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final width = size.width;
    final height = size.height;

    // Background preto
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      paint,
    );

    // Proporções
    final pastelSize = width * 0.41; // 212/512
    final pastelX = (width - pastelSize) / 2;
    final pastelY = width * 0.195; // 100/512

    // Quadrado amarelo principal (pastel)
    paint.color = Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pastelX, pastelY, pastelSize, pastelSize),
        Radius.circular(width * 0.02),
      ),
      paint,
    );

    // Triângulo do topo esquerdo
    final trianglePath = Path();
    trianglePath.moveTo(pastelX, pastelY - width * 0.078);
    trianglePath.lineTo(pastelX + width * 0.078, pastelY - width * 0.156);
    trianglePath.lineTo(pastelX + width * 0.078, pastelY - width * 0.078);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // Barra horizontal do topo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          pastelX + width * 0.098,
          pastelY - width * 0.215,
          width * 0.293,
          width * 0.098,
        ),
        Radius.circular(width * 0.01),
      ),
      paint,
    );

    // Olhos e boca
    paint.color = Colors.black;
    paint.strokeWidth = width * 0.0234;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;

    // Olho esquerdo
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(pastelX + width * 0.195, pastelY + width * 0.195),
        radius: width * 0.039,
      ),
      0,
      3.14159,
      false,
      paint,
    );

    // Olho direito
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(
            pastelX + pastelSize - width * 0.117, pastelY + width * 0.195),
        radius: width * 0.039,
      ),
      0,
      3.14159,
      false,
      paint,
    );

    // Boca
    final mouthPath = Path();
    final mouthStartX = pastelX + width * 0.117;
    final mouthEndX = pastelX + pastelSize - width * 0.117;
    final mouthY = pastelY + width * 0.293;
    mouthPath.moveTo(mouthStartX, mouthY);
    mouthPath.quadraticBezierTo(
        width / 2, mouthY + width * 0.059, mouthEndX, mouthY);
    canvas.drawPath(mouthPath, paint);

    // Texto
    if (withText) {
      _drawText(canvas, width, height);
    }
  }

  void _drawText(Canvas canvas, double width, double height) {
    final textPainter1 = TextPainter(
      text: TextSpan(
        text: 'pastelaria',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: width * 0.12,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout();
    textPainter1.paint(
      canvas,
      Offset(
        (width - textPainter1.width) / 2,
        width * 0.74,
      ),
    );

    final textPainter2 = TextPainter(
      text: TextSpan(
        text: 'ponto de amigos',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: width * 0.11,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout();
    textPainter2.paint(
      canvas,
      Offset(
        (width - textPainter2.width) / 2,
        width * 0.85,
      ),
    );
  }

  @override
  bool shouldRepaint(PastelarioLogoPainter oldDelegate) => false;
}
