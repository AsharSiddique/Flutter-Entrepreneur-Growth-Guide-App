import 'package:entrepreneur_growth_guide/email_verification.dart';
import 'package:entrepreneur_growth_guide/forget_password.dart';
import 'package:entrepreneur_growth_guide/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_zim/zego_zim.dart';

class SignInWithEmail extends StatefulWidget {
  @override
  _SignInWithEmailState createState() => _SignInWithEmailState();
}

class _SignInWithEmailState extends State<SignInWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password cannot be empty")),
      );
      return;
    }

    try {
      // Attempt to sign in the user
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          // Email is verified, initialize ZIM
          await _initializeZegoCloud(user);

          // Navigate to HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // If email is not verified, send a verification email and navigate to VerificationScreen
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Email is not verified. A verification email has been sent."),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerificationScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";

      if (e.code == "user-not-found") {
        errorMessage = "No user found with this email.";
      } else if (e.code == "wrong-password") {
        errorMessage = "Incorrect password.";
      } else if (e.code == "invalid-email") {
        errorMessage = "Invalid email format.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  // Initialize ZEGOCLOUD ZIM SDK
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
      print('ZEGOCLOUD initialized and user logged in: ${user.uid}');
    } catch (e) {
      print('ZEGOCLOUD initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize chat service: $e')),
      );
      throw e; // Prevent navigation if initialization fails
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  text: 'S',
                  style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  children: [
                    TextSpan(
                      text: 'ign ',
                      style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    TextSpan(
                      text: 'i',
                      style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    TextSpan(
                      text: 'n with Email',
                      style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // Email Text Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email,
                      color: const Color.fromARGB(255, 245, 127, 129)),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 245, 127, 129),
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: const Color.fromARGB(255, 245, 127, 129),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Password Text Field
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock,
                      color: const Color.fromARGB(255, 245, 127, 129)),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 245, 127, 129),
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: const Color.fromARGB(255, 245, 127, 129),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Forgot Password Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgetPassword()),
                  );
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // Sign In Button
              ElevatedButton(
                onPressed: _signIn,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    const Color.fromARGB(255, 241, 86, 86),
                  ),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(
                        vertical: 15, horizontal: screenWidth * 0.2),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                      fontSize: screenWidth * 0.05, color: Colors.white),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
