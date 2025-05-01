import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;
  
  const ConfettiAnimation({
    Key? key,
    required this.onComplete,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];
  
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    // Iniciar la animación
    _controller.forward();
    
    // Llamar a onComplete cuando termine
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            progress: _animation.value,
            colors: _colors,
            random: _random,
            pieces: 100,
          ),
          child: Container(),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final Random random;
  final int pieces;
  late List<ConfettiPiece> _confettiPieces;
  
  ConfettiPainter({
    required this.progress,
    required this.colors,
    required this.random,
    required this.pieces,
  }) {
    _initializePieces();
  }
  
  void _initializePieces() {
    _confettiPieces = List.generate(pieces, (index) {
      return ConfettiPiece(
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 10 + 5,
        initialPosition: Offset(
          random.nextDouble(),
          -0.2 - random.nextDouble() * 0.8,
        ),
        angle: random.nextDouble() * 2 * pi,
        angleSpeed: (random.nextDouble() * 2 - 1) * 0.2,
        speed: 0.2 + random.nextDouble() * 0.3,
      );
    });
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in _confettiPieces) {
      final position = Offset(
        piece.initialPosition.dx * size.width,
        size.height * (piece.initialPosition.dy + progress * piece.speed * 2),
      );
      
      // Pintar solo si está dentro de la pantalla
      if (position.dy >= 0 && position.dy <= size.height) {
        final paint = Paint()..color = piece.color;
        
        // Aplicar rotación según el ángulo
        final angle = piece.angle + progress * piece.angleSpeed * 10;
        
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle);
        
        // Dibujar diferentes formas de confeti
        final type = piece.size.toInt() % 3;
        switch (type) {
          case 0:
            // Rectangulo
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset.zero,
                width: piece.size,
                height: piece.size * 0.5,
              ),
              paint,
            );
            break;
          case 1:
            // Círculo
            canvas.drawCircle(
              Offset.zero,
              piece.size * 0.5,
              paint,
            );
            break;
          case 2:
            // Triángulo
            final path = Path()
              ..moveTo(0, -piece.size * 0.5)
              ..lineTo(-piece.size * 0.5, piece.size * 0.5)
              ..lineTo(piece.size * 0.5, piece.size * 0.5)
              ..close();
            canvas.drawPath(path, paint);
            break;
        }
        
        canvas.restore();
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiPiece {
  final Color color;
  final double size;
  final Offset initialPosition;
  final double angle;
  final double angleSpeed;
  final double speed;
  
  ConfettiPiece({
    required this.color,
    required this.size,
    required this.initialPosition,
    required this.angle,
    required this.angleSpeed,
    required this.speed,
  });
}
