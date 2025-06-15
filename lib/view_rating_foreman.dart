import 'package:flutter/material.dart';

class ViewRatingsForeman extends StatelessWidget {
  const ViewRatingsForeman({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Ratings (Foreman)'),
      ),
      body: const Center(
        child: Text('Foreman Ratings List'),
      ),
    );
  }
}