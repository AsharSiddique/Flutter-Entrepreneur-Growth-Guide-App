import 'dart:async';
import 'package:entrepreneur_growth_guide/authentication.dart';
import 'package:entrepreneur_growth_guide/home.dart';
import 'package:entrepreneur_growth_guide/onboarding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zim/zego_zim.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  final appID = int.parse(dotenv.env['ZEGO_APP_ID']!);
  final appSign = dotenv.env['ZEGO_APP_SIGN']!;

  final navigatorKey = GlobalKey<NavigatorState>();

  // Initialize ZegoUIKitPrebuiltCallInvitationService
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await ZegoUIKit().initLog().then((value) {
      ZegoUIKitPrebuiltCallInvitationService()
        ..setNavigatorKey(navigatorKey)
        ..useSystemCallingUI([ZegoUIKitSignalingPlugin()])
        ..init(
          appID: appID,
          appSign: appSign,
          userID: user.uid,
          userName: user.email ?? 'User_${user.uid}',
          plugins: [ZegoUIKitSignalingPlugin()],
        );
    });
  }

  runApp(EntrepreneurGrowthGuideApp(navigatorKey: navigatorKey));
}

class EntrepreneurGrowthGuideApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  EntrepreneurGrowthGuideApp({required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  Future<void> _initializeZegoCloud(User user) async {
    try {
      await dotenv.load(fileName: ".env");
      final appID = int.parse(dotenv.env['ZEGO_APP_ID']!);
      final appSign = dotenv.env['ZEGO_APP_SIGN']!;

      ZIMAppConfig appConfig = ZIMAppConfig()
        ..appID = appID
        ..appSign = appSign;
      await ZIM.create(appConfig);
      ZIM? zimInstance = ZIM.getInstance();
      if (zimInstance == null) {
        throw Exception('Failed to get ZIM instance');
      }

      final userInfo = ZIMUserInfo()
        ..userID = user.uid
        ..userName = user.email ?? 'User_${user.uid}';
      await zimInstance.login(
        userInfo.userID,
        ZIMLoginConfig()..userName = userInfo.userName,
      );
      print('ZEGOCLOUD initialized and user logged in: ${user.uid}');
    } catch (e) {
      print('ZEGOCLOUD initialization error: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.emailVerified) {
          return FutureBuilder<void>(
            future: _initializeZegoCloud(snapshot.data!),
            builder: (context, zimSnapshot) {
              if (zimSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (zimSnapshot.hasError) {
                print('ZIM initialization failed: ${zimSnapshot.error}');
                return Auth();
              } else {
                return HomeScreen();
              }
            },
          );
        } else {
          return OnboardingScreen();
        }
      },
    );
  }
}


/*
class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  late AnimationController _gradientController;
  late Animation<Color?> _gradientAnimationStart;
  late Animation<Color?> _gradientAnimationEnd;

  final List<String> sentences = [
    'Where Passion meets Expertise',
    'Lets Get Started...',
    'Expert Guidance Guaranteed',
    'Mentorship for Success',
    'Grow with Expert Advice',
    'Transform Your Business',
    'Proven Path to Success',
    'Fuel Your Business Growth',
    'Unlock Your Full Potential',
    'Grow Your Business Smarter',
    'Empower Your Business Dreams',
    'Transform Your Business Life',
    'Achieve the Impossible Now',
    'Success Starts Now'
  ];

  int _currentSentenceIndex = 0;
  String _displayedText = "";
  Timer? _sentenceTimer;
  Timer? _typingTimer;
  int _typingCharIndex = 0;

  @override
  void initState() {
    super.initState();

    _zoomController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _zoomAnimation = Tween<double>(begin: 0.6, end: 0.7).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );

    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimationStart = ColorTween(
      begin: Color.fromARGB(255, 133, 67, 67),
      end: Color.fromARGB(255, 39, 38, 38),
    ).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _gradientAnimationEnd = ColorTween(
      begin: Color.fromARGB(255, 39, 38, 38),
      end: Color.fromARGB(255, 133, 67, 67),
    ).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _startTypingEffect();
  }

  void _startTypingEffect() {
    _displayedText = "";
    _typingCharIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_typingCharIndex < sentences[_currentSentenceIndex].length) {
        setState(() {
          _displayedText += sentences[_currentSentenceIndex][_typingCharIndex];
          _typingCharIndex++;
        });
      } else {
        timer.cancel();
        _startSentenceTimer();
      }
    });
  }

  void _startSentenceTimer() {
    _sentenceTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _currentSentenceIndex = (_currentSentenceIndex + 1) % sentences.length;
      });
      _startTypingEffect();
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _gradientController.dispose();
    _sentenceTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _gradientAnimationStart.value!,
                      _gradientAnimationEnd.value!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                    stops: [0.3, 0.7],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _zoomController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _zoomAnimation.value,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/icon3.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 300,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _displayedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Auth()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 241, 86, 86),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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


*/