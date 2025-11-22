import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  final String playlistId;
  const AnalyticsScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(child: Text('Analytics - To be implemented')),
    );
  }
}