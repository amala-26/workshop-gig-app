import 'package:flutter/material.dart';

class AddRatingForeman extends StatelessWidget {
  const AddRatingForeman({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Rating (Foreman)'),
      ),
      body: const Center(
        child: Text('Add Rating Form for Foreman'),
      ),
    );
  }
}