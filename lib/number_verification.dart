import 'package:entrepreneur_growth_guide/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise.dart';
import 'dart:io' show Platform;

class NumberVerification extends StatefulWidget {
  final String phoneNumber;

  const NumberVerification({required this.phoneNumber});

  @override
  _NumberVerificationState createState() => _NumberVerificationState();
}

class _NumberVerificationState extends State<NumberVerification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String verificationId = '';
  String smsCode = '';
  bool isCodeSent = false;
  String recaptchaToken = '';

  @override
  void initState() {
    super.initState();
    _initializeRecaptchaAndSendCode();
  }

  Future<void> _initializeRecaptchaAndSendCode() async {
    try {
      // Initialize reCAPTCHA client
      const String siteKey = '6Lcvg8UqAAAAAOHpJ7bEnmbo4dKYWSC_Z8oOpCtY';
      final bool isRecaptchaInitialized =
          // ignore: deprecated_member_use
          await RecaptchaEnterprise.initClient(siteKey);

      if (isRecaptchaInitialized) {
        // ignore: deprecated_member_use
        recaptchaToken = await RecaptchaEnterprise.execute(
          RecaptchaAction.LOGIN(),
        );
        _sendCode();
      } else {
        throw Exception("Failed to initialize reCAPTCHA");
      }
    } catch (e) {
      debugPrint("Error initializing reCAPTCHA: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize reCAPTCHA: $e")),
      );
    }
  }

  void _sendCode() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
        forceResendingToken: null,
      );
    } catch (e) {
      debugPrint("Error in sending code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification code')),
      );
    }
  }

  void _verifyCode() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 40,
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.length == 1) {
                        smsCode = smsCode + value;
                        if (smsCode.length == 6) {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text('Verify Code'),
            ),
            TextButton(
              onPressed: _initializeRecaptchaAndSendCode,
              child: Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}

/*
import 'package:entrepreneur_growth_guide/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'dart:io' show Platform;

import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise.dart';

class NumberVerification extends StatefulWidget {
  final String phoneNumber;

  const NumberVerification({required this.phoneNumber});

  @override
  _NumberVerificationState createState() => _NumberVerificationState();
}

class _NumberVerificationState extends State<NumberVerification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String verificationId = '';
  String smsCode = '';
  bool isCodeSent = false;
  RecaptchaClient? _recaptchaClient;

  @override
  void initState() {
    super.initState();
    _initializeRecaptcha();
    _sendCode();
  }

  void _initializeRecaptcha() async {
    try {
      final siteKey = '6Lcvg8UqAAAAAOHpJ7bEnmbo4dKYWSC_Z8oOpCtY';

      bool initialized =
          // ignore: deprecated_member_use
          await RecaptchaEnterprise.initClient(siteKey, timeout: 10000);

      if (initialized) {
        _recaptchaClient = await Recaptcha.fetchClient(siteKey);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('reCAPTCHA initialized successfully')),
        );
      } else {
        throw Exception('Failed to initialize reCAPTCHA');
      }
    } catch (e) {
      debugPrint('Error initializing reCAPTCHA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize reCAPTCHA: $e')),
      );
    }
  }

  void _sendCode() async {
    try {
      // Ensure reCAPTCHA is initialized before proceeding
      if (_recaptchaClient == null) {
        throw Exception('reCAPTCHA is not initialized');
      }

      // Execute reCAPTCHA to get a token
      final token = await _recaptchaClient!.execute(RecaptchaAction.LOGIN());

      if (token.isEmpty) {
        throw Exception('reCAPTCHA token is empty');
      }

      // Send verification code using Firebase
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,

        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
        // Pass the reCAPTCHA token in the request
        forceResendingToken: null,
      );
    } catch (e) {
      debugPrint('Error sending code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification code: $e')),
      );
    }
  }

  void _verifyCode() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 40,
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.length == 1) {
                        smsCode = smsCode + value;
                        if (smsCode.length == 6) {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text('Verify Code'),
            ),
            TextButton(
              onPressed: _sendCode,
              child: Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:io';
import 'package:entrepreneur_growth_guide/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise.dart';

class NumberVerification extends StatefulWidget {
  final String phoneNumber;

  const NumberVerification({required this.phoneNumber});

  @override
  _NumberVerificationState createState() => _NumberVerificationState();
}

class _NumberVerificationState extends State<NumberVerification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String verificationId = '';
  String smsCode = '';
  bool isCodeSent = false;

  String recaptchaToken = '';

  @override
  void initState() {
    super.initState();
    _initializeRecaptcha();
  }

  void _initializeRecaptcha() async {
    try {
      // ignore: deprecated_member_use
      await RecaptchaEnterprise.initClient(
        '6Lcvg8UqAAAAAOHpJ7bEnmbo4dKYWSC_Z8oOpCtY',
      );
      print('reCAPTCHA initialized successfully.');
      _sendCode();
    } catch (e) {
      print('Error initializing reCAPTCHA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize reCAPTCHA.')),
      );
    }
  }

  Future<void> _executeRecaptcha() async {
    try {
      // ignore: deprecated_member_use
      final token = await RecaptchaEnterprise.execute(RecaptchaAction.LOGIN());
      setState(() {
        recaptchaToken = token;
      });
      print('reCAPTCHA token: $token');
    } catch (e) {
      print('Error executing reCAPTCHA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reCAPTCHA verification failed.')),
      );
    }
  }

  void _sendCode() async {
    await _executeRecaptcha();
    if (recaptchaToken.isEmpty) {
      return; // Abort if reCAPTCHA failed.
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
        forceResendingToken: null,
        autoRetrievedSmsCodeForTesting: recaptchaToken,
      );
    } catch (e) {
      print("Error in sending code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification code')),
      );
    }
  }

  void _verifyCode() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 40,
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.length == 1) {
                        smsCode = smsCode + value;
                        if (smsCode.length == 6) {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text('Verify Code'),
            ),
            TextButton(
              onPressed: _sendCode,
              child: Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:entrepreneur_growth_guide/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NumberVerification extends StatefulWidget {
  final String phoneNumber;

  const NumberVerification({required this.phoneNumber});

  @override
  _NumberVerificationState createState() => _NumberVerificationState();
}

class _NumberVerificationState extends State<NumberVerification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String verificationId = '';
  String smsCode = '';
  bool isCodeSent = false;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  void _sendCode() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _navigateToHome();
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle the error appropriately
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isCodeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      print("Error in sending code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification code')),
      );
    }
  }

  void _verifyCode() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 40,
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.length == 1) {
                        smsCode = smsCode + value;
                        if (smsCode.length == 6) {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text('Verify Code'),
            ),
            TextButton(
              onPressed: _sendCode,
              child: Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
*/