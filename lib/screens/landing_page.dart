import 'package:flutter/material.dart';
import 'dart:async';
import '../constants.dart';
import 'carousel_view.dart'; 

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loadingController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _loadingController, curve: Curves.easeOutBack));

    _loadingController.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLoading ? AppColors.primary : Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _isLoading ? _buildLoading() : const LandingCarousel(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey(1),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Logo.png', width: 150, height: 150),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  children: [
                    const TextSpan(text: "Temu"),
                    TextSpan(
                        text: "Aksi",
                        style: TextStyle(color: AppColors.tertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
