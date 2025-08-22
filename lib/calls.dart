import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chats.dart'; // Import for OneOnOneChatScreen
import 'authentication.dart'; // Import for Auth screen

class CallsScreen extends StatefulWidget {
  @override
  _CallsScreenState createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  String? userRole;
  bool isLoading = true;
  List<Map<String, dynamic>> callHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
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
        await _fetchCallHistory('Mentor', user.uid);
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
          await _fetchCallHistory('Mentee', user.uid);
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
      print('Error fetching user data: $e');
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

  Future<void> _fetchCallHistory(String role, String userId) async {
    try {
      // Query calls where the user is either caller or callee
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Calls')
          .where('caller_id', isEqualTo: userId)
          .get();
      final querySnapshot2 = await FirebaseFirestore.instance
          .collection('Calls')
          .where('callee_id', isEqualTo: userId)
          .get();

      List<QueryDocumentSnapshot> allCalls = [
        ...querySnapshot.docs,
        ...querySnapshot2.docs
      ];

      List<Map<String, dynamic>> callDetails = [];
      final collection = role == 'Mentor' ? 'Mentees' : 'Mentors';

      for (var doc in allCalls) {
        final data = doc.data() as Map<String, dynamic>;
        final peerUid =
            data['caller_id'] == userId ? data['callee_id'] : data['caller_id'];

        try {
          // Fetch peer user details
          final peerDoc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(peerUid)
              .get();

          if (peerDoc.exists) {
            // Format timestamp
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final formattedTime = timestamp != null
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)
                : 'Unknown time';

            callDetails.add({
              'uid': peerUid,
              'name': peerDoc['Name'] ?? 'Unknown',
              'email': peerDoc['Email'] ?? 'No Email',
              'profile_picture': peerDoc['Profile_picture'] ?? '',
              'call_type': data['call_type'],
              'status': data['status'],
              'timestamp': formattedTime,
              'is_outgoing': data['caller_id'] == userId,
            });
          }
        } catch (e) {
          print('Error fetching user details for $peerUid: $e');
        }
      }

      // Sort by timestamp (newest first)
      callDetails.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        callHistory = callDetails;
      });
    } catch (e) {
      print('Error fetching call history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load call history: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      setState(() {
        callHistory = [];
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
          "Call History",
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
            icon: Icon(Icons.search, color: Colors.white70, size: 26),
            onPressed: () {},
            tooltip: 'Search',
          ),
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
          : callHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_end_outlined,
                        size: 60,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No call history',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16),
                  child: ListView.separated(
                    itemCount: callHistory.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final call = callHistory[index];
                      return CallCard(
                        name: call['name'],
                        email: call['email'],
                        callType: call['call_type'],
                        status: call['status'],
                        timestamp: call['timestamp'],
                        isOutgoing: call['is_outgoing'],
                        avatar: call['profile_picture'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OneOnOneChatScreen(
                                name: call['name'],
                                avatar: call['profile_picture'],
                                peerUid: call['uid'],
                                isMentor: userRole != 'Mentor',
                                onMessageReceived: _fetchUserData,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class CallCard extends StatelessWidget {
  final String name;
  final String email;
  final String callType;
  final String status;
  final String timestamp;
  final bool isOutgoing;
  final String? avatar;
  final VoidCallback onTap;

  const CallCard({
    required this.name,
    required this.email,
    required this.callType,
    required this.status,
    required this.timestamp,
    required this.isOutgoing,
    this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    child: avatar != null && avatar!.isNotEmpty
                        ? Image.network(
                            avatar!,
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
                      Row(
                        children: [
                          Icon(
                            isOutgoing ? Icons.call_made : Icons.call_received,
                            size: 16,
                            color: status == 'missed'
                                ? Colors.red
                                : Colors.white70,
                          ),
                          SizedBox(width: 4),
                          Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              fontSize: 14,
                              color: status == 'missed'
                                  ? Colors.red
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          callType == 'video' ? Icons.videocam : Icons.call,
                          size: 16,
                          color: Color(0xFFEB1555),
                        ),
                        SizedBox(width: 4),
                        Text(
                          callType == 'video' ? 'Video Call' : 'Voice Call',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(
              color: Colors.white.withOpacity(0.1),
              thickness: 1,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email,
                  color: Color(0xFFEB1555),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
