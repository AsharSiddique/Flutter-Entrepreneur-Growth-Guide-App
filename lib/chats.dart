import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:entrepreneur_growth_guide/authentication.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_zim/zego_zim.dart';
import 'dart:convert';

// Add the StringExtension here
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String? userRole;
  bool isLoading = true;
  List<Map<String, dynamic>> activeConnections = [];

  @override
  void initState() {
    super.initState();
    _initializeAndSetupZegoCloud();
    _fetchUserData();
  }

  Future<void> _initializeAndSetupZegoCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Auth()),
      );
      return;
    }

    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      try {
        await _initializeZegoCloud(user);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize chat service'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Auth()),
        );
        return;
      }
    }

    ZIMEventHandler.onReceivePeerMessage = (zim, messageList, fromUserID) {
      _fetchUserData();
    };
  }

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
    } catch (e) {
      throw e;
    }
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
        await _fetchConnections('Mentor', mentorDoc);
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
          await _fetchConnections('Mentee', menteeDoc);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching user data'),
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

  Future<void> _fetchConnections(String role, DocumentSnapshot userDoc) async {
    final connections = List<String>.from(userDoc['Active_connections'] ?? []);
    if (connections.isEmpty) {
      setState(() {
        activeConnections = [];
      });
      return;
    }

    List<Map<String, dynamic>> connectionDetails = [];
    final collection = role == 'Mentor' ? 'Mentees' : 'Mentors';
    for (String uid in connections) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get();
        if (doc.exists) {
          final messageData = await _fetchLatestMessage(uid);
          connectionDetails.add({
            'uid': uid,
            'name': doc['Name'] ?? 'Unknown',
            'email': doc['Email'] ?? 'No Email',
            'profile_picture':
                role == 'Mentor' ? '' : (doc['Profile_picture'] ?? ''),
            'latest_message': messageData['message'] ?? '',
            'timestamp': messageData['timestamp'] ?? '',
            'is_unread': messageData['is_unread'] ?? false,
          });
        }
      } catch (e) {
        print('Error fetching connection $uid: $e');
      }
    }
    setState(() {
      activeConnections = connectionDetails;
    });
  }

  Future<Map<String, dynamic>> _fetchLatestMessage(String peerUid) async {
    const maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final zimInstance = ZIM.getInstance();
        if (zimInstance == null) {
          return {'message': '', 'timestamp': '', 'is_unread': false};
        }
        final result = await zimInstance.queryHistoryMessage(
          peerUid,
          ZIMConversationType.peer,
          ZIMMessageQueryConfig()
            ..count = 1
            ..reverse = true,
        );
        if (result.messageList.isNotEmpty) {
          final message = result.messageList.first;
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(message.timestamp)
                  .toString()
                  .substring(11, 16);
          String messageContent = '';
          if (message is ZIMTextMessage) {
            messageContent = message.message;
          } else if (message is ZIMImageMessage) {
            messageContent = '[Image]';
          } else if (message is ZIMVideoMessage) {
            messageContent = '[Video]';
          } else if (message is ZIMAudioMessage) {
            messageContent = '[Audio]';
          }
          return {
            'message': messageContent,
            'timestamp': timestamp,
            'is_unread':
                message.senderUserID != FirebaseAuth.instance.currentUser!.uid,
          };
        }
        return {'message': '', 'timestamp': '', 'is_unread': false};
      } catch (e) {
        if (i == maxRetries - 1) {
          return {'message': '', 'timestamp': '', 'is_unread': false};
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return {'message': '', 'timestamp': '', 'is_unread': false};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1D1E33),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Text(
          "Messages",
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
          : activeConnections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No active connections',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: activeConnections.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final connection = activeConnections[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OneOnOneChatScreen(
                              name: connection['name'],
                              avatar: connection['profile_picture'],
                              peerUid: connection['uid'],
                              isMentor: userRole != 'Mentor',
                              onMessageReceived: _fetchUserData,
                            ),
                          ),
                        );
                      },
                      child: ChatTile(
                        name: connection['name'],
                        message: connection['latest_message'],
                        time: connection['timestamp'],
                        avatar: connection['profile_picture'],
                        isUnread: connection['is_unread'],
                      ),
                    );
                  },
                ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name, message, time;
  final String? avatar;
  final bool isUnread;

  ChatTile({
    required this.name,
    required this.message,
    required this.time,
    this.avatar,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                        size: 24,
                        color: Colors.white70,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 24,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFEB1555),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class OneOnOneChatScreen extends StatefulWidget {
  final String name;
  final String? avatar;
  final String peerUid;
  final bool isMentor;
  final VoidCallback onMessageReceived;

  OneOnOneChatScreen({
    required this.name,
    this.avatar,
    required this.peerUid,
    required this.isMentor,
    required this.onMessageReceived,
  });

  @override
  _OneOnOneChatScreenState createState() => _OneOnOneChatScreenState();
}

class _OneOnOneChatScreenState extends State<OneOnOneChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ZIMMessage> messages = [];
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  Map<int, String> _sentMediaPaths = {};
  DateTime _recordingStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageListener();
    _requestPermissions();
    _initRecorder();
  }

  Future<void> _scheduleAppointment() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (selectedDate == null) return;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    // Show dialog for mode and duration
    String? mode;
    int? duration;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Call Type'),
              items: [
                DropdownMenuItem(value: 'video', child: Text('Video Call')),
                DropdownMenuItem(value: 'voice', child: Text('Voice Call')),
              ],
              onChanged: (value) => mode = value,
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Duration (minutes)'),
              items: [
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('60 minutes')),
              ],
              onChanged: (value) => duration = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (mode != null && duration != null) {
                Navigator.pop(context);
              }
            },
            child: Text('Schedule'),
          ),
        ],
      ),
    );

    if (mode == null || duration == null) return;

    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat service not initialized'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final formattedTime = selectedTime.format(context);
    final messageText =
        'Appointment: $mode call on $formattedDate at $formattedTime for $duration minutes';
    final message = ZIMTextMessage(message: messageText)
      ..senderUserID = FirebaseAuth.instance.currentUser!.uid
      ..timestamp = DateTime.now().millisecondsSinceEpoch
      ..extendedData = jsonEncode({
        'type': 'appointment',
        'date': formattedDate,
        'time': formattedTime,
        'mode': mode,
        'duration': duration,
      });

    try {
      final userList = await zimInstance
          .queryUsersInfo([widget.peerUid], ZIMUserInfoQueryConfig());
      if (userList.userList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipient is not available'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      await zimInstance.sendMessage(
        message,
        widget.peerUid,
        ZIMConversationType.peer,
        ZIMMessageSendConfig(),
        ZIMMessageSendNotification(),
      );

      setState(() {
        messages.add(message);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });

      widget.onMessageReceived();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send appointment'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<String?> _uploadToCloudinary(String filePath) async {
    try {
      final cloudinary = CloudinaryPublic('doyb8klya', 'preset', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Auto,
        ),
      );
      if (response.secureUrl.isEmpty) {
        print('Cloudinary upload failed: Empty secureUrl returned');
        return null;
      }
      print('Cloudinary upload successful: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('Cloudinary upload error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize audio recorder'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.photos,
      if (Platform.isAndroid) Permission.storage,
      if (await Permission.systemAlertWindow.isDenied)
        Permission.systemAlertWindow,
    ].request();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _setupMessageListener() async {
    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat service not initialized'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Auth()),
      );
      return;
    }

    ZIMEventHandler.onReceivePeerMessage = (zim, messageList, fromUserID) {
      if (fromUserID == widget.peerUid) {
        setState(() {
          for (var message in messageList) {
            if (message is ZIMAudioMessage ||
                message is ZIMImageMessage ||
                message is ZIMVideoMessage) {
              print('Received media message: ${message.extendedData}');
            }
            messages.add(message);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          });
        });
        widget.onMessageReceived();
      }
    };
  }

  Future<void> _loadMessages() async {
    const maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        final zimInstance = ZIM.getInstance();
        if (zimInstance == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat service not initialized'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        final result = await zimInstance.queryHistoryMessage(
          widget.peerUid,
          ZIMConversationType.peer,
          ZIMMessageQueryConfig()
            ..count = 100
            ..reverse = true,
        );

        final sortedMessages = result.messageList.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        setState(() {
          messages = sortedMessages;
          for (var message in messages) {
            if ((message is ZIMImageMessage ||
                    message is ZIMVideoMessage ||
                    message is ZIMAudioMessage) &&
                message.extendedData.isNotEmpty) {
              try {
                final extendedData = jsonDecode(message.extendedData);
                if (extendedData['cloudinaryUrl'] != null) {
                  _sentMediaPaths[message.timestamp] =
                      extendedData['cloudinaryUrl'];
                }
              } catch (e) {
                print('Error decoding extendedData: $e');
              }
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          });
        });
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load messages'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat service not initialized'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final message = ZIMTextMessage(message: _messageController.text)
      ..senderUserID = FirebaseAuth.instance.currentUser!.uid
      ..timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      final userList = await zimInstance
          .queryUsersInfo([widget.peerUid], ZIMUserInfoQueryConfig());
      if (userList.userList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipient is not available'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      await zimInstance.sendMessage(
        message,
        widget.peerUid,
        ZIMConversationType.peer,
        ZIMMessageSendConfig(),
        ZIMMessageSendNotification(),
      );

      setState(() {
        messages.add(message);
        _messageController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });

      widget.onMessageReceived();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _sendMediaMessage(XFile file, {required bool isImage}) async {
    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat service not initialized'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final userList = await zimInstance
          .queryUsersInfo([widget.peerUid], ZIMUserInfoQueryConfig());
      if (userList.userList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipient is not available'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Check if file exists
      final fileObject = File(file.path);
      if (!await fileObject.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Media file not found at ${file.path}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Upload to Cloudinary
      final cloudinaryUrl = await _uploadToCloudinary(file.path);
      if (cloudinaryUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload media to Cloudinary'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      ZIMMessage message;
      if (isImage) {
        message = ZIMImageMessage(file.path)
          ..senderUserID = FirebaseAuth.instance.currentUser!.uid
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..extendedData = jsonEncode({
            'localPath': file.path,
            'cloudinaryUrl': cloudinaryUrl,
          });
      } else {
        message = ZIMVideoMessage(file.path)
          ..senderUserID = FirebaseAuth.instance.currentUser!.uid
          ..timestamp = DateTime.now().millisecondsSinceEpoch
          ..extendedData = jsonEncode({
            'localPath': file.path,
            'cloudinaryUrl': cloudinaryUrl,
          });
      }

      await zimInstance.sendMessage(
        message,
        widget.peerUid,
        ZIMConversationType.peer,
        ZIMMessageSendConfig(),
        ZIMMessageSendNotification(),
      );

      setState(() {
        messages.add(message);
        _sentMediaPaths[message.timestamp] =
            file.path; // Keep local path for sender
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });
      widget.onMessageReceived();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send media: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _sendAudioMessage(String filePath) async {
    final zimInstance = ZIM.getInstance();
    if (zimInstance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat service not initialized'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final userList = await zimInstance
          .queryUsersInfo([widget.peerUid], ZIMUserInfoQueryConfig());
      if (userList.userList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipient is not available'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file not found'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file is empty or corrupted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Upload to Cloudinary
      final cloudinaryUrl = await _uploadToCloudinary(filePath);
      if (cloudinaryUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload audio to Cloudinary'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      int duration = await _getAudioDuration(filePath);
      if (duration == 0) duration = 1000;

      final message = ZIMAudioMessage(filePath)
        ..senderUserID = FirebaseAuth.instance.currentUser!.uid
        ..timestamp = DateTime.now().millisecondsSinceEpoch
        ..extendedData = jsonEncode({
          'localPath': filePath,
          'cloudinaryUrl': cloudinaryUrl,
          'duration': duration,
        });

      setState(() {
        messages.add(message);
        _sentMediaPaths[message.timestamp] =
            filePath; // Keep local path for sender
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      });

      await zimInstance.sendMessage(
        message,
        widget.peerUid,
        ZIMConversationType.peer,
        ZIMMessageSendConfig(),
        ZIMMessageSendNotification(),
      );

      widget.onMessageReceived();
    } catch (e) {
      if (e.toString().contains('110021')) {
        widget.onMessageReceived();
      } else {
        setState(() {
          messages.removeWhere(
              (m) => m.timestamp == DateTime.now().millisecondsSinceEpoch);
          _sentMediaPaths.remove(DateTime.now().millisecondsSinceEpoch);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send audio: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<int> _getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return 0;

      final player = ja.AudioPlayer();
      await player.setFilePath(filePath);
      final duration = await player.duration;
      await player.dispose();
      return duration?.inMilliseconds ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _pickAndSendMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Send Image'),
            onTap: () => Navigator.pop(context, 'image'),
          ),
          ListTile(
            leading: Icon(Icons.videocam),
            title: Text('Send Video'),
            onTap: () => Navigator.pop(context, 'video'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    try {
      final XFile? file = choice == 'image'
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        await _sendMediaMessage(file, isImage: choice == 'image');
      }
    } catch (e) {
      print('Error picking media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick media: $e')),
      );
    }
  }

  Future<void> _recordAndSendAudio() async {
    if (_isRecording) {
      try {
        if (DateTime.now().difference(_recordingStartTime).inSeconds < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please record for at least 1 second')),
          );
          return;
        }
        final path = await _recorder.stopRecorder();
        if (path != null && await File(path).exists()) {
          await _sendAudioMessage(path); // Use .m4a directly
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save recording')),
          );
        }
        setState(() => _isRecording = false);
      } catch (e) {
        print('Error stopping recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording')),
        );
        setState(() => _isRecording = false);
      }
    } else {
      try {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission required')),
          );
          return;
        }

        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacMP4, // Record directly to .m4a
          sampleRate: 44100,
          bitRate: 128000,
        );
        print('Recorder started successfully: $filePath');
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
        });

        Timer(Duration(seconds: 60), () async {
          if (_isRecording) {
            await _recorder.stopRecorder();
            setState(() => _isRecording = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recording stopped: 60s limit reached')),
            );
          }
        });
      } catch (e) {
        print('Failed to start recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _saveCallRecord(String callId, String callType) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection('Calls').add({
        'call_id': callId,
        'caller_id': FirebaseAuth.instance.currentUser!.uid,
        'callee_id': widget.peerUid,
        'call_type': callType,
        'status': 'initiated',
        'timestamp': FieldValue.serverTimestamp(),
        'accept_time': null,
        'end_time': null,
        'duration': 0,
      });

      Timer(Duration(seconds: 60), () async {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists &&
            docSnapshot.data()!['status'] == 'initiated') {
          await docRef.update({'status': 'missed'});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save call record'),
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
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final messageGroups = <String, List<ZIMMessage>>{};
    final dateFormat = DateFormat('MMM dd, yyyy');
    for (var message in messages) {
      final date = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      final dateKey = dateFormat.format(date);
      if (!messageGroups.containsKey(dateKey)) {
        messageGroups[dateKey] = [];
      }
      messageGroups[dateKey]!.add(message);
    }

    // Sort dates chronologically
    final sortedDates = messageGroups.keys.toList()
      ..sort((a, b) {
        final dateA = dateFormat.parse(a);
        final dateB = dateFormat.parse(b);
        return dateA.compareTo(dateB);
      });

    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1D1E33),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFEB1555),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: widget.isMentor &&
                        widget.avatar != null &&
                        widget.avatar!.isNotEmpty
                    ? Image.network(
                        widget.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white70,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white70,
                      ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (!widget.isMentor) ...[
            // Show call buttons only for mentors
            ZegoSendCallInvitationButton(
              isVideoCall: false,
              resourceID: "zego_call",
              invitees: [
                ZegoUIKitUser(
                  id: widget.peerUid,
                  name: widget.name,
                ),
              ],
              icon: ButtonIcon(
                icon: Icon(Icons.call, color: Colors.white70),
                backgroundColor: Colors.transparent,
              ),
              iconSize: Size(24, 24),
              buttonSize: Size(40, 40),
              timeoutSeconds: 60,
              callID:
                  "${FirebaseAuth.instance.currentUser!.uid}_${widget.peerUid}_${DateTime.now().millisecondsSinceEpoch}",
              onPressed:
                  (String code, String message, List<String> errorInvitees) {
                if (errorInvitees.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to invite ${widget.name}'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  _saveCallRecord(
                      "${FirebaseAuth.instance.currentUser!.uid}_${widget.peerUid}_${DateTime.now().millisecondsSinceEpoch}",
                      'voice');
                }
              },
            ),
            ZegoSendCallInvitationButton(
              isVideoCall: true,
              resourceID: "zego_call",
              invitees: [
                ZegoUIKitUser(
                  id: widget.peerUid,
                  name: widget.name,
                ),
              ],
              icon: ButtonIcon(
                icon: Icon(Icons.videocam, color: Colors.white70),
                backgroundColor: Colors.transparent,
              ),
              iconSize: Size(24, 24),
              buttonSize: Size(40, 40),
              timeoutSeconds: 60,
              callID:
                  "${FirebaseAuth.instance.currentUser!.uid}_${widget.peerUid}_${DateTime.now().millisecondsSinceEpoch}",
              onPressed:
                  (String code, String message, List<String> errorInvitees) {
                if (errorInvitees.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to invite ${widget.name}'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  _saveCallRecord(
                      "${FirebaseAuth.instance.currentUser!.uid}_${widget.peerUid}_${DateTime.now().millisecondsSinceEpoch}",
                      'video');
                }
              },
            ),
          ],
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final groupMessages = messageGroups[date]!;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF1D1E33),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    ...groupMessages.map((message) {
                      final isUser = message.senderUserID ==
                          FirebaseAuth.instance.currentUser!.uid;
                      Map<String, dynamic>? appointmentData;
                      bool isAppointment = false;

                      if (message is ZIMTextMessage &&
                          message.extendedData.isNotEmpty) {
                        try {
                          final extendedData = jsonDecode(message.extendedData);
                          if (extendedData['type'] == 'appointment') {
                            isAppointment = true;
                            appointmentData = extendedData;
                          }
                        } catch (e) {
                          print('Error decoding extendedData: $e');
                        }
                      }

                      if (isAppointment) {
                        return OneOnOneChatBubble(
                          text: (message as ZIMTextMessage)
                              .message, // Cast to ZIMTextMessage
                          isUser: isUser,
                          isAppointment: true,
                          appointmentData: appointmentData,
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp),
                        );
                      } else if (message is ZIMTextMessage) {
                        return OneOnOneChatBubble(
                          text: message.message, // Safe to access message here
                          isUser: isUser,
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp),
                        );
                      } else if (message is ZIMImageMessage) {
                        return OneOnOneChatBubble(
                          text: '',
                          isUser: isUser,
                          isImage: true,
                          imagePath: _sentMediaPaths[message.timestamp],
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp),
                        );
                      } else if (message is ZIMVideoMessage) {
                        return OneOnOneChatBubble(
                          text: '',
                          isUser: isUser,
                          isVideo: true,
                          videoPath: _sentMediaPaths[message.timestamp],
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp),
                        );
                      } else if (message is ZIMAudioMessage) {
                        final extendedData = message.extendedData.isNotEmpty
                            ? jsonDecode(message.extendedData)
                            : {};
                        return OneOnOneChatBubble(
                          text: '',
                          isUser: isUser,
                          isAudio: true,
                          audioPath: _sentMediaPaths[message.timestamp],
                          audioDuration: extendedData['duration'] ?? 0,
                          timestamp: DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp),
                        );
                      }
                      return SizedBox.shrink();
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          OneOnOneChatInputField(
            controller: _messageController,
            onSend: _sendMessage,
            onAttach: _pickAndSendMedia,
            onRecord: _recordAndSendAudio,
            isRecording: _isRecording,
            isMentor: !widget.isMentor, // Pass true if user is a mentor
            onAppointment: _scheduleAppointment,
          ),
        ],
      ),
    );
  }
}

class OneOnOneChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final bool isEmail;
  final bool isReaction;
  final bool isImage;
  final bool isVideo;
  final bool isAudio;
  final bool isAppointment;
  final String? imagePath;
  final String? videoPath;
  final String? audioPath;
  final int audioDuration;
  final DateTime timestamp;
  final Map<String, dynamic>? appointmentData;

  OneOnOneChatBubble({
    required this.text,
    required this.isUser,
    this.isEmail = false,
    this.isReaction = false,
    this.isImage = false,
    this.isVideo = false,
    this.isAudio = false,
    this.isAppointment = false,
    this.imagePath,
    this.videoPath,
    this.audioPath,
    this.audioDuration = 0,
    required this.timestamp,
    this.appointmentData,
  });

  @override
  _OneOnOneChatBubbleState createState() => _OneOnOneChatBubbleState();
}

class _OneOnOneChatBubbleState extends State<OneOnOneChatBubble> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  ja.AudioPlayer? _player;
  bool _isPlaying = false;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _player!.setLoopMode(ja.LoopMode.off);
    if (widget.isVideo && widget.videoPath != null) {
      // Check if videoPath is a local path or a URL
      if (widget.videoPath!.startsWith('http')) {
        _videoController = VideoPlayerController.network(widget.videoPath!)
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
          }).catchError((e) {
            print('Video initialization error: $e');
          });
      } else {
        _videoController = VideoPlayerController.file(File(widget.videoPath!))
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
          }).catchError((e) {
            print('Video initialization error: $e');
          });
      }
    }
    if (widget.isAudio && widget.audioPath != null) {
      if (widget.audioPath!.startsWith('http')) {
        _player!.setUrl(widget.audioPath!);
      } else {
        _player!.setFilePath(widget.audioPath!);
      }
      _playerStateSubscription = _player!.playerStateStream.listen((state) {
        if (state.processingState == ja.ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _player!.seek(Duration.zero);
          });
        } else if (state.playing != _isPlaying) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback() async {
    if (widget.audioPath == null || _player == null) return;

    try {
      if (_isPlaying) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isAppointment
              ? Colors.blueGrey.withOpacity(0.8)
              : widget.isReaction
                  ? Color(0xFF1D1E33)
                  : widget.isUser
                      ? Color(0xFFEB1555).withOpacity(0.8)
                      : Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.isAppointment && widget.appointmentData != null)
              Column(
                crossAxisAlignment: widget.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Scheduled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date: ${widget.appointmentData!['date']}',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  Text(
                    'Time: ${widget.appointmentData!['time']}',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  Text(
                    'Mode: ${widget.appointmentData!['mode'].toString().capitalize()}',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  Text(
                    'Duration: ${widget.appointmentData!['duration']} minutes',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              )
            else if (widget.isReaction)
              Icon(
                widget.text == "?" ? Icons.help : Icons.thumb_up,
                color: Colors.white,
                size: 20,
              )
            else if (widget.isImage)
              widget.imagePath != null
                  ? Container(
                      constraints:
                          BoxConstraints(maxWidth: 200, maxHeight: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.imagePath!.startsWith('http')
                            ? Image.network(
                                widget.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Image.file(
                                File(widget.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                ),
                              ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
                    )
            else if (widget.isVideo)
              widget.videoPath != null
                  ? Container(
                      constraints:
                          BoxConstraints(maxWidth: 200, maxHeight: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _isVideoInitialized
                            ? Stack(
                                children: [
                                  VideoPlayer(_videoController!),
                                  Center(
                                    child: IconButton(
                                      icon: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_videoController!
                                              .value.isPlaying) {
                                            _videoController!.pause();
                                          } else {
                                            _videoController!.play();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: Colors.white.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFEB1555)),
                                  ),
                                ),
                              ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white70,
                          size: 40,
                        ),
                      ),
                    )
            else if (widget.isAudio)
              widget.audioPath != null
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _toggleAudioPlayback,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _formatDuration(widget.audioDuration),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_off,
                            color: Colors.white70,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Audio',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
            else
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isEmail ? Colors.blueAccent : Colors.white,
                  fontWeight:
                      widget.isEmail ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            SizedBox(height: 4),
            Text(
              timeFormat.format(widget.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OneOnOneChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRecord;
  final bool isRecording;
  final bool isMentor; // New parameter
  final VoidCallback onAppointment; // New callback

  OneOnOneChatInputField({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onRecord,
    required this.isRecording,
    required this.isMentor,
    required this.onAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1D1E33),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMentor) ...[
            IconButton(
              icon: Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 26,
              ),
              onPressed: onAppointment,
              tooltip: 'Schedule Appointment',
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: Colors.white70,
              size: 26,
            ),
            onPressed: onAttach,
            tooltip: 'Attach file',
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isRecording ? Colors.red : Color(0xFFEB1555).withOpacity(0.8),
            ),
            child: IconButton(
              icon: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
              onPressed: onRecord,
              tooltip: isRecording ? 'Stop recording' : 'Record audio',
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEB1555).withOpacity(0.8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
              onPressed: onSend,
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}
