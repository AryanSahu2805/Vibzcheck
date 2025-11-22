import 'package:flutter/material.dart';

class PlaylistViewScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistViewScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: const Center(child: Text('Playlist View - To be implemented')),
    );
  }
}