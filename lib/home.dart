import 'package:entrepreneur_growth_guide/authentication.dart';
import 'package:entrepreneur_growth_guide/calls.dart';
import 'package:entrepreneur_growth_guide/chatbot.dart';
import 'package:entrepreneur_growth_guide/chats.dart';
import 'package:entrepreneur_growth_guide/profiles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_zim/zego_zim.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    ProfilesScreen(),
    ChatsScreen(),
    CallsScreen(),
    ChatbotScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1D1E33), // Dark blue from app bar
              Color(0xFFEB1555), // Pink accent color
              Color(0xFF1D1E33), // Dark blue from app bar
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.2, 1.1, 0.2],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profiles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.call),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'Chatbot',
            ),
          ],
        ),
      ),
    );
  }
}

/*

class ProfilesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 27, 31, 47),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 133, 67, 67),
        automaticallyImplyLeading: false,
        title: Text(
          " Profiles",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Perform logout logic here (e.g., clear user session)
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ListView.separated(
            itemCount: mentorsData.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey,
              thickness: 0.5,
              height: 16,
            ),
            itemBuilder: (context, index) {
              return ProfileCard(
                name: mentorsData[index]["name"]!,
                designation: mentorsData[index]["designation"]!,
                email: mentorsData[index]["email"]!,
                phone: mentorsData[index]["phone"]!,
                image: mentorsData[index]["image"]!,
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name, designation, email, phone, image;

  ProfileCard({
    required this.name,
    required this.designation,
    required this.email,
    required this.phone,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF23283E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(image),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      designation,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text(email, style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.greenAccent, size: 18),
              SizedBox(width: 8),
              Text(phone, style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, color: Colors.blue),
                label: Text(
                  "Connect",
                  style: TextStyle(color: Colors.blue),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullProfileScreen(
                        name: name,
                        designation: designation,
                        email: email,
                        phone: phone,
                        image: image,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.file_copy, color: Colors.blue),
                label: Text(
                  "See Profile",
                  style: TextStyle(color: Colors.blue),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final List<Map<String, String>> mentorsData = [
  {
    "name": "Dr. Muhammad Naseem",
    "designation": "Chairperson, Associate Professor",
    "email": "mnaseem@ssuet.edu.pk",
    "phone": "(021) 34988000 Ext: 316",
    "image": "assets/naseem.jpg",
  },
  {
    "name": "Engr. Tauseef Mubeen",
    "designation": "Assistant Professor",
    "email": "tmubeen@ssuet.edu.pk",
    "phone": "(021) 34988000 Ext: 326",
    "image": "assets/tauseef.jpg",
  },
  {
    "name": "Engr. Syed Haris Mehboob",
    "designation": "Assistant Professor",
    "email": "smahboob@ssuet.edu.pk",
    "phone": "(021) 34988000 Ext: 287",
    "image": "assets/haris.jpg",
  },
  {
    "name": "Dr. Engr. Muhammad Imran",
    "designation": "Assistant Professor",
    "email": "mimransaleem@hotmail.com",
    "phone": "(021) 34988000",
    "image": "assets/imran.jpg",
  },
  {
    "name": "Dr. Engr. Muhammad Saad",
    "designation": "Senior Lecturer",
    "email": "msaad@ssuet.edu.pk",
    "phone": "(021) 34988000 Ext: 725",
    "image": "assets/saad.jpg",
  }
];

*/

/*

class ChatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 27, 31, 47),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 133, 67, 67),
        title: Text(
          " Messages",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Perform logout logic here (e.g., clear user session)
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: chatData.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey.shade800, thickness: 0.5),
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                // Navigate to 1-on-1 chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OneOnOneChatScreen(
                        name: chatData1[index]["name"] ?? "Unknown",
                        avatar: chatData1[index]["avatar"]),
                  ),
                );
              },
              child: ChatTile(
                name: chatData1[index]["name"] ?? "Unknown",
                message: chatData1[index]["message"] ?? "",
                time: chatData1[index]["time"] ?? "",
                avatar: chatData1[index]["avatar"],
                isUnread: chatData1[index]["isUnread"] ?? false,
              ));
        },
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name, message, time;
  final avatar;
  final bool isUnread;

  ChatTile(
      {required this.name,
      required this.message,
      required this.time,
      this.avatar,
      this.isUnread = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: AssetImage(avatar), // Placeholder
        backgroundColor: Colors.grey.shade700,
      ),
      title: Text(name,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
        ],
      ),
      trailing:
          Text(time, style: TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }
}

// 1-on-1 Chat Screen
class OneOnOneChatScreen extends StatelessWidget {
  final String name;
  final avatar;

  OneOnOneChatScreen({required this.name, this.avatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 27, 31, 47),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 133, 67, 67),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(avatar), // Placeholder
              backgroundColor: Colors.grey.shade700,
            ),
            SizedBox(width: 10),
            Text(
              name,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),

          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Perform logout logic here (e.g., clear user session)
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return OneOnOneChatBubble(
                  text: message["text"]!,
                  isUser: message["isUser"]!,
                  isEmail: message["isEmail"] ?? false,
                  isReaction: message["isReaction"] ?? false,
                );
              },
            ),
          ),
          OneOnOneChatInputField(),
        ],
      ),
    );
  }
}

class OneOnOneChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isEmail;
  final bool isReaction;

  OneOnOneChatBubble({
    required this.text,
    required this.isUser,
    this.isEmail = false,
    this.isReaction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isReaction
              ? Colors.grey.shade400
              : isUser
                  ? Colors.black87
                  : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isReaction
            ? Icon(
                text == "?" ? Icons.help : Icons.thumb_up,
                color: Colors.white,
                size: 20,
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isEmail ? Colors.blueAccent : Colors.white,
                  fontWeight: isEmail ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}

class OneOnOneChatInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.white),
            onPressed: () {
              // TODO: Implement file attachment functionality
            },
          ),
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Message",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              // TODO: Implement voice message functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              // TODO: Implement send message functionality
            },
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> chatData = [
  {"text": "Hey!", "isUser": true},
  {"text": "Hi there! How may I help you?", "isUser": false},
  {"text": "I will let you know", "isUser": true},
  {"text": "Sure, I will be happy to help you!", "isUser": false},
  {"text": "maciej.kowalski@email.com", "isUser": true, "isEmail": true},
];

final List<Map<String, dynamic>> chatData1 = [
  {
    "name": "Dr. Muhammad Naseem",
    "message": "dannylove@gmail.com",
    "time": "08:43",
    "avatar": "assets/naseem.jpg"
  },
  {
    "name": "Engr. Tauseef Mubeen",
    "message": "Will do, super, thank you 😊❤️",
    "time": "Tue",
    "avatar": "assets/tauseef.jpg"
  },
  {
    "name": "Engr. Syed Haris Mehboob",
    "message": "Uploaded file.",
    "time": "Sun",
    "avatar": "assets/haris.jpg"
  },
  {
    "name": "Dr. Engr. Muhammad Imran",
    "message": "Here is another tutorial, if you...",
    "time": "23 Mar",
    "avatar": "assets/imran.jpg"
  },
  {
    "name": "Dr. Engr. Muhammad Saad",
    "message": "😏",
    "time": "18 Mar",
    "avatar": "assets/saad.jpg",
    "isUnread": true
  },
];

*/

/*


class CallsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 27, 31, 47),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 133, 67, 67),
        automaticallyImplyLeading: false,
        title: Text(
          " Calls",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Perform logout logic here (e.g., clear user session)
              try {
                final zimInstance = ZIM.getInstance();
                if (zimInstance != null) {
                  await zimInstance.logout();
                  zimInstance.destroy();
                  print('ZEGOCLOUD logged out and destroyed');
                }
              } catch (e) {
                print('ZEGOCLOUD logout error: $e');
              }
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: callData.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          return CallTile(
            name: callData[index]["name"]!,
            details: callData[index]["details"]!,
            isMissed: callData[index]["isMissed"] ?? false,
          );
        },
      ),
    );
  }
}

class CallTile extends StatelessWidget {
  final String name, details;
  final bool isMissed;

  CallTile({required this.name, required this.details, this.isMissed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 106, 106, 106)
            .withOpacity(0.2), // Slightly lighter card color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(
            isMissed ? Icons.phone_missed : Icons.call,
            color: isMissed ? Colors.redAccent : Colors.blueAccent,
            size: 24,
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> callData = [
  {
    "name": "Dr. Muhammad Naseem",
    "details": "JUST NOW Outgoing 32min",
    "isMissed": false
  },
  {
    "name": "Engr. Tauseef Mubeen",
    "details": "TODAY AT 11:30 AM Rejected",
    "isMissed": true
  },
  {
    "name": "Engr. Syed Haris Mehboob",
    "details": "YESTERDAY AT 3PM Incoming 24s",
    "isMissed": false
  },
  {
    "name": "Dr. Engr. Muhammad Imran Saleem",
    "details": "JUN 1 Outgoing 1hr 30min",
    "isMissed": false
  },
  {
    "name": "Dr. Engr. Muhammad Saad",
    "details": "JUN 3 Incoming 5min",
    "isMissed": false
  },
  {
    "name": "Dr. Engr. Muhammad Saad",
    "details": "TODAY AT 11:30 AM Rejected",
    "isMissed": true
  },
  {
    "name": "Dr. Muhammad Naseem",
    "details": "JUN 1 Outgoing 1hr 30min",
    "isMissed": false
  },
];


*/

/*
class ChatbotScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 27, 31, 47),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 133, 67, 67),
        automaticallyImplyLeading: false,
        title: Text(
          " AI Chatbot",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Perform logout logic here (e.g., clear user session)
              try {
                final zimInstance = ZIM.getInstance();
                if (zimInstance != null) {
                  await zimInstance.logout();
                  zimInstance.destroy();
                  print('ZEGOCLOUD logged out and destroyed');
                }
              } catch (e) {
                print('ZEGOCLOUD logout error: $e');
              }
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Auth()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ChatBubble(
                  text: message["text"]!,
                  isUser: message["isUser"]!,
                  isEmail: message["isEmail"] ?? false,
                  isReaction: message["isReaction"] ?? false,
                  isSender: true,
                );
              },
            ),
          ),
          ChatInputField(),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isEmail;
  final bool isReaction;

  ChatBubble({
    required this.text,
    required this.isUser,
    this.isEmail = false,
    this.isReaction = false,
    required bool isSender,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isReaction
              ? Colors.grey.shade400
              : isUser
                  ? Colors.black87
                  : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isReaction
            ? Icon(
                text == "?" ? Icons.help : Icons.thumb_up,
                color: Colors.white,
                size: 20,
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isEmail ? Colors.blueAccent : Colors.white,
                  fontWeight: isEmail ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.white),
            onPressed: () {
              // TODO: Implement file attachment functionality
            },
          ),
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Message",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              // TODO: Implement voice message functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              // TODO: Implement send message functionality
            },
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> messages = [
  {"text": "Hey!", "isUser": true},
  {"text": "Hi there! How may I help you?", "isUser": false},
  {"text": "I will let you know", "isUser": true},
  {"text": "Sure, I will be happy to help you!", "isUser": false},
  {"text": "maciej.kowalski@email.com", "isUser": true, "isEmail": true},
  {"text": "👍", "isUser": false, "isReaction": true},

  // Additional Messages
  {"text": "Do you have any UI templates for a chatbot?", "isUser": true},
  {
    "text":
        "Yes, I can share some Figma links. Do you prefer a dark or light theme?",
    "isUser": false
  },
  {"text": "Dark theme would be great!", "isUser": true},
  {"text": "Alright! Here’s a link: figma.com/sample-ui", "isUser": false},

  {
    "text": "Can you generate some AI chatbot responses for me?",
    "isUser": true
  },
  {
    "text":
        "Sure! What type of responses are you looking for? General, friendly, or professional?",
    "isUser": false
  },
  {"text": "A mix of friendly and professional would be nice.", "isUser": true},
  {
    "text":
        "Got it! Here are some: 'Hello! How can I assist you today?' or 'Hi! Feel free to ask me anything!'",
    "isUser": false
  },

  {"text": "?", "isUser": false, "isReaction": true},
  {"text": "Thank you so much!", "isUser": true},
  {"text": "You're welcome! 😊", "isUser": false},
];


*/
class FullProfileScreen extends StatelessWidget {
  final String name, designation, email, phone, image;

  FullProfileScreen({
    required this.name,
    required this.designation,
    required this.email,
    required this.phone,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1E2D),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B2F35),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: 60),
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(image),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      designation,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "An innovative leader in the tech industry, known for developing cutting-edge solutions that empower businesses with AI-driven transformation.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Skills",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SkillChip("AI & Machine Learning"),
                      SkillChip("Cloud Computing"),
                      SkillChip("Cybersecurity"),
                      SkillChip("Blockchain"),
                      SkillChip("Business Strategy"),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Achievements",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  AchievementTile("Forbes 30 Under 30 in Tech", Icons.star),
                  AchievementTile(
                      "Developed AI-driven business automation platform",
                      Icons.rocket),
                  AchievementTile("Featured in TechCrunch for Innovation",
                      Icons.trending_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final String skill;
  SkillChip(this.skill);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(skill, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blueGrey,
    );
  }
}

class AchievementTile extends StatelessWidget {
  final String title;
  final IconData icon;
  AchievementTile(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
