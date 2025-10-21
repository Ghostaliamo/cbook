// screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:cbook/screens/login_screen.dart';
import 'package:cbook/screens/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Track Your Business Finances',
      'description': 'Easily record sales and expenses with our simple interface designed for businesses',
      'image': '💰',
    },
    {
      'title': 'Manage Customer Debts',
      'description': 'Keep track of who owes you money and receive payments easily. Perfect for Nigerian market businesses',
      'image': '📊',
    },
    {
      'title': 'Nigerian Business Focused',
      'description': 'Built for Nigerian businesses with VAT support, Naira currency, and local business practices',
      'image': '🇳🇬',
    },
    {
      'title': 'Works Offline',
      'description': 'No internet? No problem! Your data is safe and accessible even without network connection',
      'image': '📱',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button for non-first pages
            if (_currentPage > 0)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Skip', style: TextStyle(color: Colors.orange)),
                ),
              ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),
            
            _buildIndicator(),
            SizedBox(height: 20),
            _buildNavigationButtons(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> data) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data['image']!,
            style: TextStyle(fontSize: 80),
          ),
          SizedBox(height: 32),
          Text(
            data['title']!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            data['description']!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingData.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.orange : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (_currentPage == _onboardingData.length - 1)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                'Get Started',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          
          if (_currentPage == _onboardingData.length - 1) 
            SizedBox(height: 16),
          
          if (_currentPage == _onboardingData.length - 1)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'I already have an account',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          
          if (_currentPage < _onboardingData.length - 1)
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              },
              child: Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          
          if (_currentPage < _onboardingData.length - 1)
            SizedBox(height: 8),
          
          if (_currentPage < _onboardingData.length - 1)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Skip onboarding'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}