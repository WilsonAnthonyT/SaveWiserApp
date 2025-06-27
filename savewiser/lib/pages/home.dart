import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "breakfast",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.grey, offset: Offset(2, 2), blurRadius: 3),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0.0, // this controls the AppBar's shadow (below it)
      ),
    );
  }
}
