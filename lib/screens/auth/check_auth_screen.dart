import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  static const Duration _minimumSplashDuration = Duration(seconds: 2);
  bool _hasNavigated = false;

  Future<bool> _estAdmin(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _navigate(String route) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_minimumSplashDuration, () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, route);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageDeep,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashView();
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<bool>(
              future: _estAdmin(user.uid),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const _SplashView();
                }

                final isAdmin = adminSnapshot.data ?? false;
                _navigate(isAdmin ? '/admin' : '/accueil');
                return const _SplashView();
              },
            );
          }

          _navigate('/login');
          return const _SplashView();
        },
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.sageDeep,
      child: Stack(
        children: [
          Positioned.fill(child: _BreathingHalos()),
          Center(child: _SplashBrand()),
          Positioned(
            left: 32,
            right: 32,
            bottom: 80,
            child: _SplashButton(),
          ),
        ],
      ),
    );
  }
}

class _BreathingHalos extends StatefulWidget {
  const _BreathingHalos();

  @override
  State<_BreathingHalos> createState() => _BreathingHalosState();
}

class _BreathingHalosState extends State<_BreathingHalos> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.94 + (_controller.value * 0.1),
                child: const _Halo(size: 520, opacity: 0.22),
              ),
              Transform.scale(
                scale: 1.04 - (_controller.value * 0.08),
                child: const _Halo(size: 320, opacity: 0.35),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Halo extends StatelessWidget {
  final double size;
  final double opacity;

  const _Halo({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.sageBg.withValues(alpha: opacity),
            AppColors.sageBg.withValues(alpha: 0),
          ],
          stops: const [0, 0.6],
        ),
      ),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.only(bottom: 28),
          decoration: BoxDecoration(
            color: AppColors.bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(painter: _PilateMarkPainter()),
            ),
          ),
        ),
        Text(
          'Pilate',
          style: AppText.display(size: 48, color: AppColors.bg).copyWith(height: 1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'STUDIO',
          style: AppText.label(size: 13, color: AppColors.bg, letterSpacing: 3).copyWith(
            color: AppColors.bg.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SplashButton extends StatelessWidget {
  const _SplashButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Commencer',
        style: AppText.body(size: 16, weight: FontWeight.w600, color: AppColors.ink),
      ),
    );
  }
}

class _PilateMarkPainter extends CustomPainter {
  const _PilateMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sageDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawOval(Rect.fromCenter(center: center, width: 12, height: 26), paint);
    canvas.drawOval(Rect.fromCenter(center: center, width: 26, height: 12), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
