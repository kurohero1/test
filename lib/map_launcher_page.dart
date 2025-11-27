import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherPage extends StatelessWidget {
  final Uri _colabUrl = Uri.parse(
    'https://colab.research.google.com/your-notebook-link', 
  );

  Future<void> _launchURL() async {
    if (!await launchUrl(_colabUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_colabUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("地図アプリ")),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchURL,
          child: Text('Google Colab / Web App を開く'),
        ),
      ),
    );
  }
}
