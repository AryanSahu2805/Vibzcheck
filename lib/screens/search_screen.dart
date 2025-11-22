import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  final String? playlistId;
  const SearchScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Songs')),
      body: const Center(child: Text('Search - To be implemented')),
    );
  }
}