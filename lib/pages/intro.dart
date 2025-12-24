import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> slides = [
    {
      "title": "Welcome to Vault",
      "description": "Your secure and private photo & file vault.",
      "icon": CupertinoIcons.lock_shield_fill,
      "color": CupertinoColors.systemBlue,
    },
    {
      "title": "Encrypted Storage",
      "description": "Your data stays encrypted and private at all times.",
      "icon": CupertinoIcons.doc_text_fill,
      "color": CupertinoColors.systemGreen,
    },
    {
      "title": "Easy Password Setup",
      "description": "Protect your vault with a simple password.",
      "icon": CupertinoIcons.lock_fill,
      "color": CupertinoColors.systemOrange,
    },
  ];

  void _nextPage() {
    if (_currentIndex < slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go("/setup");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final bgColor = CupertinoColors.systemBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.transparent,
        border: null,
        trailing: _currentIndex < slides.length - 1
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text("Skip"),
                onPressed: () => context.go("/setup"),
              )
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // --- PAGE CONTENT ---
            PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Icon (Matching your other pages)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (slide["color"] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          slide["icon"],
                          size: 100,
                          color: slide["color"],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        slide["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slide["description"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom UI
                    ],
                  ),
                );
              },
            ),

            // --- BOTTOM OVERLAY (Dots & Button) ---
            Positioned(
              bottom: 40,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  // iOS Style Pagination Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentIndex == index
                              ? theme.primaryColor
                              : CupertinoColors.systemFill.resolveFrom(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _nextPage,
                      child: Text(
                        _currentIndex == slides.length - 1
                            ? "Get Started"
                            : "Continue",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
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
