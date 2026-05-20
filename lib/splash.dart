import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _textController;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;

  late AnimationController _subtitleController;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;

  late AnimationController _loaderController;
  late Animation<double> _loaderAnimation;

  late AnimationController _circleController;
  late Animation<double> _circleScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Background circles pulse
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _circleScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // Logo pops in with scale + fade
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Title slides up + fades in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Subtitle slides up + fades in after title
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
        );
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Progress loader
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    _loaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    // Staggered sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _subtitleController.forward();
    });

    // Navigate after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _loaderController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0C447C);
    const Color midBlue = Color(0xFF185FA5);
    const Color accentBlue = Color(0xFF378ADD);
    const Color lightBlue = Color(0xFFB5D4F4);
    const Color palest = Color(0xFFE6F1FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Decorative circles ──────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: ScaleTransition(
              scale: _circleScaleAnimation,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: midBlue.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: ScaleTransition(
              scale: _circleScaleAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: midBlue.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circle with Lottie
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentBlue, width: 2),
                      ),
                      child: ClipOval(
                        child: Lottie.asset(
                          'assets/images/Doctor.json',
                          width: 130,
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App title
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: const Text(
                      'Acne Detection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: palest,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                SlideTransition(
                  position: _subtitleSlideAnimation,
                  child: FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: const Text(
                      'Smart skin analysis at your fingertips',
                      style: TextStyle(
                        fontSize: 14,
                        color: lightBlue,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56),

                // Dot indicators
                FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(accentBlue, wide: true),
                      const SizedBox(width: 6),
                      _dot(midBlue),
                      const SizedBox(width: 6),
                      _dot(midBlue),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Progress bar
                FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 180,
                        child: AnimatedBuilder(
                          animation: _loaderAnimation,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _loaderAnimation.value,
                                backgroundColor: midBlue,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  accentBlue,
                                ),
                                minHeight: 4,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Loading resources...',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentBlue,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, {bool wide = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: wide ? 28 : 8,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
