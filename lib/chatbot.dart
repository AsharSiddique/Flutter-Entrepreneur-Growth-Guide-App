import 'dart:io';
import 'package:entrepreneur_growth_guide/authentication.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  GenerativeModel? _model;
  bool _isTyping = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize Gemini AI model
    final apiKey = dotenv.env['GEMINI_API_KEY'] ??
        'your_api_key_here'; // Replace with your API key
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Function to send a message or image to Gemini API
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // Add user message to chat
    setState(() {
      if (_selectedImage != null) {
        messages.add({
          'text': text.isNotEmpty ? text : 'Image',
          'isUser': true,
          'isImage': true,
          'imagePath': _selectedImage!.path,
        });
      } else {
        messages.add({
          'text': text,
          'isUser': true,
          'isImage': false,
        });
      }
      _isTyping = true;
    });

    try {
      final content = <Content>[];
      if (_selectedImage != null) {
        final imageBytes = await _selectedImage!.readAsBytes();
        content.add(Content.multi([
          TextPart(text.isEmpty ? 'Describe this image' : text),
          DataPart('image/jpeg', imageBytes),
        ]));
      } else {
        content.add(Content.text(text));
      }

      final response = await _model!.generateContent(content);
      final botResponse = response.text ?? 'Sorry, I couldn\'t process that.';

      setState(() {
        messages.add({
          'text': botResponse,
          'isUser': false,
          'isImage': false,
        });
        _isTyping = false;
        _selectedImage = null; // Clear image after sending
      });
    } catch (e) {
      setState(() {
        messages.add({
          'text': 'Error: $e',
          'isUser': false,
          'isImage': false,
        });
        _isTyping = false;
        _selectedImage = null;
      });
    }
    _controller.clear();
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
          "AI Chatbot",
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                reverse: false,
                itemCount: messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == messages.length) {
                    return ChatBubble(
                      text: "Typing...",
                      isUser: false,
                    );
                  }
                  final message = messages[index];
                  return message['isImage'] == true
                      ? ImageBubble(
                          imagePath: message['imagePath'],
                          isUser: message['isUser'],
                          text: message['text'],
                        )
                      : ChatBubble(
                          text: message["text"],
                          isUser: message["isUser"],
                        );
                },
              ),
            ),
          ),
          ChatInputField(
            controller: _controller,
            onSend: _sendMessage,
            onPickImage: _pickImage,
            selectedImage: _selectedImage,
            onClearImage: () {
              setState(() {
                _selectedImage = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatBubble({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFFEB1555) : Color(0xFF1D1E33),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16 : 0),
            topRight: Radius.circular(isUser ? 0 : 16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class ImageBubble extends StatelessWidget {
  final String imagePath;
  final bool isUser;
  final String text;

  ImageBubble({
    required this.imagePath,
    required this.isUser,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (text.isNotEmpty && text != 'Image')
            ChatBubble(
              text: text,
              isUser: isUser,
            ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 16 : 0),
                topRight: Radius.circular(isUser ? 0 : 16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 16 : 0),
                topRight: Radius.circular(isUser ? 0 : 16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;
  final File? selectedImage;

  ChatInputField({
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    this.selectedImage,
    this.onClearImage,
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
      child: Column(
        children: [
          if (selectedImage != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFFEB1555),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        selectedImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Image selected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFEB1555)),
                    onPressed: onClearImage,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.white70),
                onPressed: onPickImage,
                tooltip: 'Attach Image',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF0A0E21),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: TextStyle(color: Colors.white54),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB1555),
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: onSend,
                  tooltip: 'Send',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
