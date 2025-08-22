import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entrepreneur_growth_guide/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilesScreen extends StatefulWidget {
  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineUserRole();
  }

  Future<void> _determineUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Auth()),
      );
      return;
    }

    try {
      final mentorDoc = await FirebaseFirestore.instance
          .collection('Mentors')
          .doc(user.uid)
          .get();
      if (mentorDoc.exists) {
        setState(() {
          userRole = 'Mentor';
          isLoading = false;
        });
      } else {
        final menteeDoc = await FirebaseFirestore.instance
            .collection('Mentees')
            .doc(user.uid)
            .get();
        if (menteeDoc.exists) {
          setState(() {
            userRole = 'Mentee';
            isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User data not found'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Auth()),
          );
        }
      }
    } catch (e) {
      print('Error determining user role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching user data: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Color(0xFF1D1E33),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        automaticallyImplyLeading: false,
        title: Text(
          "Profiles",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white70, size: 26),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
                strokeWidth: 4,
              ),
            )
          : userRole == 'Mentee'
              ? MenteeProfilesView()
              : MentorProfilesView(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MenteeProfilesView extends StatefulWidget {
  @override
  _MenteeProfilesViewState createState() => _MenteeProfilesViewState();
}

class _MenteeProfilesViewState extends State<MenteeProfilesView> {
  String? _selectedField;
  List<String> _fields = ['All']; // Include 'All' for no filter

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Mentors').get();
      final fields = snapshot.docs
          .map((doc) => doc['Field']?.toString())
          .where((field) => field != null && field.isNotEmpty)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _fields.addAll(fields);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching fields: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Mentees')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, menteeSnapshot) {
        if (menteeSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
            ),
          );
        }
        if (!menteeSnapshot.hasData || !menteeSnapshot.data!.exists) {
          return Center(
            child: Text(
              'Mentee data not found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          );
        }

        final menteeData = menteeSnapshot.data!.data() as Map<String, dynamic>;
        final activeConnections =
            List<String>.from(menteeData['Active_connections'] ?? []);
        final requestedTo = List<String>.from(menteeData['Requested_to'] ?? []);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Mentors').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No mentors available',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }

            final mentors = snapshot.data!.docs.where((doc) {
              final mentorData = doc.data() as Map<String, dynamic>;
              final field = mentorData['Field']?.toString() ?? '';
              return _selectedField == null ||
                  _selectedField == 'All' ||
                  field == _selectedField;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedField,
                    hint: Text(
                      'Select a field',
                      style: TextStyle(color: Colors.white54),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1D1E33),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Color(0xFF1D1E33),
                    style: TextStyle(color: Colors.white),
                    items: _fields.map((field) {
                      return DropdownMenuItem<String>(
                        value: field,
                        child: Text(field),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedField = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      itemCount: mentors.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final mentor =
                            mentors[index].data() as Map<String, dynamic>;
                        final mentorId = mentors[index].id;
                        String buttonText = 'Connect';
                        Color buttonColor = Color(0xFFEB1555);
                        if (activeConnections.contains(mentorId)) {
                          buttonText = 'Connected';
                          buttonColor = Colors.green;
                        } else if (requestedTo.contains(mentorId)) {
                          buttonText = 'Requested';
                          buttonColor = Colors.orange;
                        }

                        return ProfileCard(
                          name: mentor['Name'] ?? 'Unknown',
                          designation:
                              mentor['Designation'] ?? 'No Designation',
                          email: mentor['Email'] ?? 'No Email',
                          // phone: '123-456-7890',
                          image: mentor['Profile_picture'] ?? '',
                          field: mentor['Field'] ?? 'Not specified',
                          experience: mentor['Experience'] ?? 'Not specified',
                          achievements:
                              mentor['Achievements'] ?? 'Not specified',
                          mentorId: mentorId,
                          buttonText: buttonText,
                          buttonColor: buttonColor,
                          onConnectPressed: buttonText == 'Connect'
                              ? () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('Mentees')
                                        .doc(user.uid)
                                        .update({
                                      'Requested_to':
                                          FieldValue.arrayUnion([mentorId])
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('Mentors')
                                        .doc(mentorId)
                                        .update({
                                      'Requested_by':
                                          FieldValue.arrayUnion([user.uid])
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class MentorProfilesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Mentors')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Mentor data not found',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          );
        }

        final mentorData = snapshot.data!.data() as Map<String, dynamic>;
        final requestedBy = List<String>.from(mentorData['Requested_by'] ?? []);

        if (requestedBy.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 60,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'No connection requests',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: requestedBy.length,
            separatorBuilder: (context, index) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Mentees')
                    .doc(requestedBy[index])
                    .get(),
                builder: (context, menteeSnapshot) {
                  if (menteeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
                      ),
                    );
                  }
                  if (!menteeSnapshot.hasData || !menteeSnapshot.data!.exists) {
                    return SizedBox.shrink();
                  }

                  final menteeData =
                      menteeSnapshot.data!.data() as Map<String, dynamic>;
                  final menteeId = requestedBy[index];

                  return RequestCard(
                    name: menteeData['Name'] ?? 'Unknown',
                    email: menteeData['Email'] ?? 'No Email',
                    onAccept: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('Mentors')
                            .doc(user.uid)
                            .update({
                          'Requested_by': FieldValue.arrayRemove([menteeId]),
                          'Active_connections':
                              FieldValue.arrayUnion([menteeId]),
                        });
                        await FirebaseFirestore.instance
                            .collection('Mentees')
                            .doc(menteeId)
                            .update({
                          'Requested_to': FieldValue.arrayRemove([user.uid]),
                          'Active_connections':
                              FieldValue.arrayUnion([user.uid]),
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    onDecline: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('Mentors')
                            .doc(user.uid)
                            .update({
                          'Requested_by': FieldValue.arrayRemove([menteeId]),
                        });
                        await FirebaseFirestore.instance
                            .collection('Mentees')
                            .doc(menteeId)
                            .update({
                          'Requested_to': FieldValue.arrayRemove([user.uid]),
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name,
      designation,
      email,
      // phone,
      image,
      mentorId,
      buttonText,
      field,
      experience,
      achievements;
  final Color buttonColor;
  final VoidCallback? onConnectPressed;

  ProfileCard({
    required this.name,
    required this.designation,
    required this.email,
    // required this.phone,
    required this.image,
    required this.mentorId,
    required this.buttonText,
    required this.buttonColor,
    required this.onConnectPressed,
    required this.field,
    required this.experience,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFEB1555),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white70,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white70,
                        ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      designation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.email, email),
          //SizedBox(height: 8),
          //_buildInfoRow(Icons.phone, phone),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onConnectPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onConnectPressed != null
                        ? buttonColor
                        : buttonColor.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullProfileScreen(
                          name: name,
                          designation: designation,
                          email: email,
                          // phone: phone,
                          image: image,
                          field: field,
                          experience: experience,
                          achievements: achievements,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0A0E21),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Color(0xFFEB1555)),
                    ),
                  ),
                  child: Text(
                    "View Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Color(0xFFEB1555),
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RequestCard extends StatelessWidget {
  final String name, email;
  final VoidCallback onAccept, onDecline;

  RequestCard({
    required this.name,
    required this.email,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Request',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFEB1555),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          _buildInfoRow(Icons.email, email),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C853),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDecline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD50000),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Color(0xFFEB1555),
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class FullProfileScreen extends StatelessWidget {
  final String name,
      designation,
      email,
      // phone,
      image,
      field,
      experience,
      achievements;

  FullProfileScreen({
    required this.name,
    required this.designation,
    required this.email,
    // required this.phone,
    required this.image,
    required this.field,
    required this.experience,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Color(0xFF1D1E33),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text(
          'Profile Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFEB1555),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white70,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white70,
                      ),
              ),
            ),
            SizedBox(height: 24),
            _buildProfileDetail('Name', name),
            _buildProfileDetail('Designation', designation),
            _buildProfileDetail('Field', field),
            _buildProfileDetail('Email', email),
            // _buildProfileDetail('Phone', phone),
            _buildProfileDetail('Experience', experience),
            _buildProfileDetail('Achievements', achievements),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFEB1555),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
