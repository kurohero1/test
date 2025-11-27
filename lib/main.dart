import 'package:flutter/material.dart';
import 'pedometer_page.dart';
import 'map_launcher_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("アプリメニュー")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.directions_walk),
              label: Text("歩数計（Pedometer）"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PedometerPage()),
                );
              },
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text("地図アプリ（Colab/Vercel）"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MapLauncherPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

