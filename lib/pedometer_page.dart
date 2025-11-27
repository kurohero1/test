import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  late Stream<StepCount> _stepStream;
  int _steps = 0;
  String _statusMessage = "歩数計を読み込み中…";

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitPedometer();
  }

  Future<void> _requestPermissionAndInitPedometer() async {
    // 権限をチェック
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isGranted) {
      setState(() {
        _statusMessage = "歩数計が起動しました";
      });

      // 歩数ストリームを初期化
      _stepStream = Pedometer.stepCountStream;
      _stepStream.listen((event) {
        setState(() {
          _steps = event.steps;
        });
      }).onError((error) {
        setState(() {
          _statusMessage = "歩数計エラー: $error";
        });
        print("Pedometer Error: $error");
      });
    } else {
      setState(() {
        _statusMessage = "権限が許可されていません。歩数を取得できません";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("歩数計")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _steps > 0 ? "歩数: $_steps" : _statusMessage,
              style: TextStyle(fontSize: 40),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissionAndInitPedometer,
              child: Text("権限を再リクエスト / 歩数計を再起動"),
            ),
          ],
        ),
      ),
    );
  }
}
