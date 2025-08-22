import 'package:entrepreneur_growth_guide/SignUp_with_email.dart';
import 'package:entrepreneur_growth_guide/signin_with_email.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class Auth extends StatefulWidget {
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isSignUp = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void toggleScreens() {
    if (isSignUp) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      isSignUp = !isSignUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 133, 67, 67),
                    const Color.fromARGB(255, 39, 38, 38)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  stops: [0.3, 0.7],
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    double angle = _animation.value * pi;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: angle <= pi / 2
                          ? ListView(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!isKeyboardVisible)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 10.0, bottom: 20),
                                        child: Animate(
                                          onPlay: (controller) =>
                                              controller.repeat(),
                                          effects: [
                                            FadeEffect(
                                              begin: 0.5,
                                              end: 1.5,
                                              duration: 1500.ms,
                                              delay: 0.ms,
                                            ),
                                            FadeEffect(
                                              begin: 1.5,
                                              end: 0.5,
                                              duration: 2500.ms,
                                              delay: 1500.ms,
                                            ),
                                          ],
                                          child: Image.asset(
                                            'assets/icon3.png',
                                            width: 200,
                                            height: 150,
                                          ),
                                        ),
                                      ),
                                    SignUpWithEmail(),
                                    SizedBox(height: 10),
                                    TextButton(
                                      onPressed: toggleScreens,
                                      child: Text(
                                        'Already have an account? Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    /*
                                    SizedBox(height: 5),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignInWithNumber()),
                                        );
                                      },
                                      child: Text(
                                        'Continue with Phone Number',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    */
                                  ],
                                ),
                              ],
                            )
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isKeyboardVisible)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10.0, bottom: 20),
                                      child: Animate(
                                        onPlay: (controller) =>
                                            controller.repeat(),
                                        effects: [
                                          FadeEffect(
                                            begin: 0.5,
                                            end: 1.5,
                                            duration: 1500.ms,
                                            delay: 0.ms,
                                          ),
                                          FadeEffect(
                                            begin: 1.5,
                                            end: 0.5,
                                            duration: 2500.ms,
                                            delay: 1500.ms,
                                          ),
                                        ],
                                        child: Image.asset(
                                          'assets/icon3.png',
                                          width: 200,
                                          height: 150,
                                        ),
                                      ),
                                    ),
                                  SignInWithEmail(),
                                  SizedBox(height: 10),
                                  TextButton(
                                    onPressed: toggleScreens,
                                    child: Text(
                                      'Dont have an account? Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  /*
                                  SizedBox(height: 5),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SignInWithNumber()),
                                      );
                                    },
                                    child: Text(
                                      'Continue with Phone Number',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  */
                                ],
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
