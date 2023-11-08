import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'kakao_login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    GuidePage(
      icon: Icons.local_taxi,
      title: '택시 요금을 줄여보세요',
      description: '공유하면 학생들이 모여 택시비를 줄일 수 있어요!',
    ),
    GuidePage(
      icon: Icons.directions_bus,
      title: '정확한 버스 정보를 받아보세요',
      description: '실시간 버스 정보를 이용하세요!',
    ),
    GuidePage(
      icon: Icons.directions_bike,
      title: '경로정보를 이용하세요',
      description: '구미 대중교통에 스트레스 받지마시고\n 마음편하게 학교로 가세요',
    ),
    KakaoLoginPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: _pages,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SmoothPageIndicator(
              controller: _pageController,
              count: _pages.length,
              effect: WormEffect(),
              onDotClicked: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuidePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const GuidePage({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

