import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'number_verification.dart';

class SignInWithNumber extends StatefulWidget {
  @override
  _SignInWithNumberState createState() => _SignInWithNumberState();
}

class _SignInWithNumberState extends State<SignInWithNumber> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? phoneNumber;

  void _onSignIn() async {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NumberVerification(phoneNumber: phoneNumber!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 133, 67, 67),
                  const Color.fromARGB(255, 39, 38, 38),
                ],
                begin: Alignment.topLeft,
                end: Alignment.center,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'S',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'ign in with Number',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Colors.white, width: 1.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      initialCountryCode: 'PK',
                      onChanged: (phone) {
                        phoneNumber = phone.completeNumber;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _onSignIn,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          const Color.fromARGB(255, 241, 86, 86),
                        ),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
