import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// 3-step onboarding flow matching Atoms design v2.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;

  static const _slides = [
    _SlideData(
      title: 'Private access, made simple',
      description:
          'Connect securely with one tap. LiveMask protects your network traffic without the technical complexity.',
      emoji: '🛡️',
    ),
    _SlideData(
      title: 'Fast nodes across regions',
      description:
          'Choose from servers worldwide with real-time latency and load information. Smart recommendations find the best node for you.',
      emoji: '🌍',
    ),
    _SlideData(
      title: 'Clear recovery when networks fail',
      description:
          'Connection issues happen. LiveMask provides clear actions: retry, switch nodes, or send a diagnostic report.',
      emoji: '🔄',
    ),
  ];

  void _handleNext() {
    if (_current < _slides.length - 1) {
      setState(() => _current++);
    } else {
      widget.onComplete();
    }
  }

  void _handleSkip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _handleSkip,
                child: const Text('Skip'),
              ),
            ),

            // Slide content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji placeholder (in place of image)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusXl),
                      ),
                      child: Center(
                        child: Text(
                          slide.emoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.muted.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Main CTA
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _handleNext,
                      child: Text(
                        _current < _slides.length - 1 ? 'Next' : 'Get Started',
                      ),
                    ),
                  ),

                  if (_current < _slides.length - 1) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _handleSkip,
                      child: const Text('Skip'),
                    ),
                  ],

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text('I already have an account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String description;
  final String emoji;

  const _SlideData({
    required this.title,
    required this.description,
    required this.emoji,
  });
}
