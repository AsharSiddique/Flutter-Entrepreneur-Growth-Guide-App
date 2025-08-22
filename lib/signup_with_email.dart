import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entrepreneur_growth_guide/email_verification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpWithEmail extends StatefulWidget {
  @override
  _SignUpWithEmailState createState() => _SignUpWithEmailState();
}

class _SignUpWithEmailState extends State<SignUpWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();

  String _role = "Mentee"; // Default value

  bool _isPasswordVisible = false;

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your full name")),
      );
      return;
    }

    if (_role == "Mentor") {
      if (_fieldController.text.isEmpty ||
          _experienceController.text.isEmpty ||
          _achievementsController.text.isEmpty ||
          _designationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill in all mentor fields")),
        );
        return;
      }
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (_role == "Mentee") {
        await FirebaseFirestore.instance
            .collection('Mentees')
            .doc(userCredential.user?.uid)
            .set({
          'Active_connections': [],
          'Requested_to': [],
          'Name': _fullNameController.text,
          'Email': _emailController.text,
        });
      } else if (_role == "Mentor") {
        await FirebaseFirestore.instance
            .collection('Mentors')
            .doc(userCredential.user?.uid)
            .set({
          'Achievements': _achievementsController.text,
          'Active_connections': [],
          'Requested_by': [],
          'Designation': _designationController.text,
          'Email': _emailController.text,
          'Experience': _experienceController.text,
          'Field': _fieldController.text,
          'Name': _fullNameController.text,
          'Profile_picture': '',
        });
      }

      await userCredential.user?.sendEmailVerification();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerificationScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";
      switch (e.code) {
        case "email-already-in-use":
          errorMessage = "This email is already registered";
          break;
        case "weak-password":
          errorMessage = "Password is too weak";
          break;
        case "invalid-email":
          errorMessage = "The email address is invalid";
          break;
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
                  text: 'Sign up with Email',
                  style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // Name Text Field
              TextField(
                controller: _fullNameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.person,
                    color: const Color.fromARGB(255, 245, 127, 129),
                  ),
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ),
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
              SizedBox(height: screenHeight * 0.015),

              // Email Text Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.email,
                    color: const Color.fromARGB(255, 245, 127, 129),
                  ),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ),
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
              SizedBox(height: screenHeight * 0.015),

              // Password Text Field
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.lock,
                    color: const Color.fromARGB(255, 245, 127, 129),
                  ),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 1.0,
                    ),
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
              SizedBox(height: screenHeight * 0.015),

              // Role Selection (Mentor or Mentee)
              DropdownButtonFormField<String>(
                value: _role,
                dropdownColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Role",
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 245, 127, 129),
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                items: ["Mentor", "Mentee"]
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child:
                              Text(role, style: TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.015),

              // Conditional Fields for Mentor in a Row
              if (_role == "Mentor")
                Column(
                  children: [
                    Row(
                      children: [
                        // Field Text Field
                        Expanded(
                          child: TextField(
                            controller: _fieldController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.work,
                                color: const Color.fromARGB(255, 245, 127, 129),
                                size: 20,
                              ),
                              labelText: 'Field',
                              labelStyle: TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 245, 127, 129),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor:
                                const Color.fromARGB(255, 245, 127, 129),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),

                        // Designation Text Field
                        Expanded(
                          child: TextField(
                            controller: _designationController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.badge,
                                color: const Color.fromARGB(255, 245, 127, 129),
                                size: 20,
                              ),
                              labelText: 'Designation',
                              labelStyle: TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 245, 127, 129),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                            style: TextStyle(fontSize: 14),
                            cursorColor:
                                const Color.fromARGB(255, 245, 127, 129),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        // Experience Text Field
                        Expanded(
                          child: TextField(
                            controller: _experienceController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.history,
                                color: const Color.fromARGB(255, 245, 127, 129),
                                size: 20,
                              ),
                              labelText: 'Experience',
                              labelStyle: TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 245, 127, 129),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor:
                                const Color.fromARGB(255, 245, 127, 129),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),

                        // Achievements Text Field
                        Expanded(
                          child: TextField(
                            controller: _achievementsController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.star,
                                color: const Color.fromARGB(255, 245, 127, 129),
                                size: 20,
                              ),
                              labelText: 'Achievements',
                              labelStyle: TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 245, 127, 129),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor:
                                const Color.fromARGB(255, 245, 127, 129),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              SizedBox(height: screenHeight * 0.035),

              ElevatedButton(
                onPressed: _signUp,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 241, 86, 86)),
                  padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                      vertical: 15, horizontal: screenWidth * 0.2)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
                ),
                child: Text('Sign Up',
                    style: TextStyle(
                        fontSize: screenWidth * 0.05, color: Colors.white)),
              ),
              SizedBox(height: screenHeight * 0.015),
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
    _fullNameController.dispose();
    _fieldController.dispose();
    _experienceController.dispose();
    _achievementsController.dispose();
    _designationController.dispose();
    super.dispose();
  }
}
