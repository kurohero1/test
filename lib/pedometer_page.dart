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
    // 一次请求两个可能必要的权限
    Map<Permission, PermissionStatus> statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    bool granted = statuses[Permission.activityRecognition]!.isGranted &&
        statuses[Permission.sensors]!.isGranted;

    if (!granted) {
      setState(() {
        _statusMessage = "権限が許可されていません。歩数を取得できません。";
      });
      return;
    }

    setState(() {
      _statusMessage = "歩数計が起動しました";
    });

    // 初始化步数监听
    _stepStream = Pedometer.stepCountStream;
    _stepStream.listen((StepCount event) {
      setState(() {
        _steps = event.steps;
        _statusMessage = "歩数データを受信中…";
      });
    }).onError((error) {
      setState(() {
        _statusMessage = "歩数計エラー: $error";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("歩数計")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 歩数永远显示，不会被盖掉
            Text(
              "歩数: $_steps",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 状态显示在步数下面
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

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
