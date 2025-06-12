import 'package:flutter/material.dart';

class GetStartedScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const GetStartedScreen({super.key, required this.onContinue});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      image: 'assets/images/logo-v10.png',
      title: 'Welcome to AdoPals!',
      description: 'Find your furry, feathery, or scaly friend. Discover, adopt, and connect with loving pets and responsible sellers. Your new family member is just a tap away!',
      iconBg: Colors.purple,
    ),
    _OnboardingPageData(
      image: 'assets/images/profile.jpg',
      title: 'Adopt or Buy',
      description: 'Browse a wide variety of pets for adoption or sale. Save your favorites and revisit them anytime.',
      iconBg: Colors.orange,
    ),
    _OnboardingPageData(
      image: 'assets/images/login-gradient1.png',
      title: 'Connect & Chat',
      description: 'Chat with sellers, ask questions, and make informed decisions. Your perfect companion is waiting!',
      iconBg: Colors.green,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      widget.onContinue();
    }
  }

  void _onPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _onSkip() {
    widget.onContinue();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: page.iconBg,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Image.asset(page.image, height: 80),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? Colors.purple : Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _onPrevious,
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _onSkip,
                      child: const Text('Skip'),
                    ),
                  if (_currentPage == _pages.length - 1)
                    const SizedBox(width: 64),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _onNext,
                      child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
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

class _OnboardingPageData {
  final String image;
  final String title;
  final String description;
  final Color iconBg;
  const _OnboardingPageData({required this.image, required this.title, required this.description, required this.iconBg});
}
