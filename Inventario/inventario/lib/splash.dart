import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/home.dart';
import 'package:inventario/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  late AnimationController _textController;
  late Animation<double> _textAnimation;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Animación para el ícono: rotación y escalado
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    );
    _iconController.forward();

    // Animación para el texto: aparición con fundido
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    _textController.forward();

    // Animación para el indicador de progreso: rotación continua
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: 1).animate(_progressController);
    _progressController.repeat();

    // Espera 4 segundos antes de redirigir según el estado de sesión
    Timer(const Duration(seconds: 4), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('userEmail');
      bool isLoggedIn = userEmail != null;

      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo degradado para un look moderno
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono animado con rotación y escalado, con sombra para dar profundidad
              AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _iconAnimation.value * 2 * 3.141592653589793,
                    child: Transform.scale(
                      scale: _iconAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Título animado con FadeTransition
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  "Bienvenido a Inventario UTS",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo animado con FadeTransition
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  "Gestiona tus inventarios de forma inteligente",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              const SizedBox(height: 30),
              // Indicador de progreso animado (rotación)
              RotationTransition(
                turns: _progressAnimation,
                child: const Icon(
                  Icons.sync,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
