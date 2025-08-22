import 'package:entrepreneur_growth_guide/authentication.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // List of onboarding pages
  final List<Map<String, String>> onboardingPages = [
    {
      'title': 'Entrepreneur Growth Guide',
      'description':
          'Embark on your entrepreneurial path with tools and guidance tailored for success.',
      'image': 'assets/lottie/page1.json', // Replace with your image
    },
    {
      'title': 'Stay Inspired',
      'description':
          '"The journey of a thousand miles begins with a single step." - Lao Tzu',
      'image': 'assets/lottie/page2.json', // Replace with your image
    },
    {
      'title': 'Mentor-Mentee Connection',
      'description':
          'Build meaningful relationships with mentors to guide and accelerate your growth.',
      'image': 'assets/lottie/page3.json', // Replace with your image
    },
    {
      'title': 'Seamless Communication',
      'description':
          'Connect effortlessly with text, voice messages, file sharing, video, and voice calls.',
      'image': 'assets/lottie/page4.json', // Replace with your image
    },
    {
      'title': 'AI-Powered Chat Support',
      'description':
          'Get instant answers and insights from our in-app AI chatbot, anytime you need.',
      'image': 'assets/lottie/page5.json', // Replace with your image
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for onboarding slides
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                title: onboardingPages[index]['title']!,
                description: onboardingPages[index]['description']!,
                image: onboardingPages[index]['image']!,
              );
            },
          ),

          // Page indicator (dots)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: onboardingPages.length,
                effect: WormEffect(
                  activeDotColor: Colors.teal[600]!,
                  dotColor: Colors.grey[300]!,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
          ),

          // Next and Get Started buttons
          Positioned(
            bottom: 40,
            right: 20, // Align to the right
            child: Row(
              children: [
                // Next or Get Started button
                if (_currentPage == onboardingPages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Auth()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Onboarding page widget
class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Lottie.asset(
            image,
            width: 300,
            height: 300,
          ),
          SizedBox(height: 40),
          // Title with typing effect
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal[600],
            ),
            child: TyperAnimatedTextKit(
              text: [title],
              speed: Duration(milliseconds: 100), // Typing speed
              isRepeatingAnimation: false, // One-time effect
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
