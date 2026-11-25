import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CurvedHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height - 60);

    // Create the ellipse/curve
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Optional: Draw some subtle circles for modern look as seen in some designs
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(size.width * 0.9, 0), 70, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 80, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 90, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 100, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 110, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 120, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 130, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 140, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, 0), 150, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CurvedSection extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showBackButton;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;

  const CurvedSection({
    super.key,
    this.child = const SizedBox.shrink(),
    this.height = 300,
    this.showBackButton = false,
    this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, height),
            painter: CurvedHeaderPainter(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showBackButton)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (actions != null)
                        Row(children: actions!)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 30),
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
