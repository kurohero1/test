import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  late Stream<StepCount> _stepStream;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _stepStream = Pedometer.stepCountStream;
    _stepStream.listen((event) {
      setState(() {
        _steps = event.steps;
      });
    }).onError((error) {
      print("Pedometer Error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("歩数計")),
      body: Center(
        child: Text(
          "歩数: $_steps",
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
