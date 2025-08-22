import 'dart:async';
import 'package:entrepreneur_growth_guide/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_zim/zego_zim.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    // Start a periodic timer to check for email verification
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  Future<void> checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      setState(() {
        isEmailVerified = user?.emailVerified ?? false;
      });

      if (isEmailVerified) {
        // Email verified, stop the timer
        timer?.cancel();

        // Initialize ZEGOCLOUD ZIM SDK
        await _initializeZegoCloud(user!);

        // Show success message and navigate to HomeScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email successfully verified!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error checking email verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error verifying email: $e")),
      );
    }
  }

  Future<void> _initializeZegoCloud(User user) async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      final appID = int.parse(dotenv.env['ZEGO_APP_ID']!);
      final appSign = dotenv.env['ZEGO_APP_SIGN']!;

      // Initialize ZIM SDK
      ZIMAppConfig appConfig = ZIMAppConfig()
        ..appID = appID
        ..appSign = appSign;
      await ZIM.create(appConfig);
      ZIM? zimInstance = ZIM.getInstance();
      if (zimInstance == null) {
        throw Exception('Failed to get ZIM instance');
      }

      // Log in user
      final userInfo = ZIMUserInfo()
        ..userID = user.uid
        ..userName = user.email ?? 'User_${user.uid}';
      await zimInstance.login(
        userInfo.userID,
        ZIMLoginConfig()..userName = userInfo.userName,
      );
      debugPrint('ZEGOCLOUD initialized and user logged in: ${user.uid}');
    } catch (e) {
      debugPrint('ZEGOCLOUD initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize chat service: $e')),
      );
      // Optionally, prevent navigation to HomeScreen on failure
      throw e; // Let the caller handle the error
    }
  }

  Future<void> resendEmailVerification() async {
    setState(() {
      isResending = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Verification email resent successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Oops! Please try again later: $e")),
      );
    } finally {
      setState(() {
        isResending = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade200, Colors.deepOrange.shade400],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We have sent a verification email to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUserEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verifying email...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: isResending ? null : resendEmailVerification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: isResending ? Colors.grey : Colors.white,
                    ),
                    child: isResending
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.orange),
                          )
                        : const Text(
                            'Resend Email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Make sure you\'ve entered a valid email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
