import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  const ChatScreen({Key? key, required this.playlistId, required this.playlistName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(playlistName)),
      body: const Center(child: Text('Chat - To be implemented')),
    );
  }
}
