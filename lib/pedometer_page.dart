import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  late Stream<StepCount> _stepStream;

  int _rawSteps = 0;          // システムから取得される累計歩数
  int _baselineSteps = 0;     // リセット時の基準歩数
  String _statusMessage = "歩数計を読み込み中…";

  Map<String, int> _history = {};  // 歩数履歴（日付 → 歩数）

  // ===== 追加：距離計算用の歩幅（一般平均：0.7m） =====
  double _stepLength = 0.7;   // 1歩あたりの歩幅（メートル）

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _requestPermissionAndInitPedometer();
  }

  /// 履歴をSharedPreferencesから読み込む
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString("step_history");

    if (jsonString != null) {
      setState(() {
        _history = Map<String, int>.from(json.decode(jsonString));
      });
    }
  }

  /// 履歴を保存
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(_history);
    await prefs.setString("step_history", jsonString);
  }

  /// 今日の歩数を履歴に保存
  void _saveTodaySteps() {
    final today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    final int displaySteps = _rawSteps - _baselineSteps;

    setState(() {
      _history[today] = displaySteps;
    });

    _saveHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("本日の歩数を保存しました")),
    );
  }

  /// 権限チェック＆歩数計初期化
  Future<void> _requestPermissionAndInitPedometer() async {
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

    _stepStream = Pedometer.stepCountStream;

    _stepStream.listen((StepCount event) {
      setState(() {
        _rawSteps = event.steps;
        _statusMessage = "歩数データを受信中…";
      });
    }).onError((error) {
      setState(() {
        _statusMessage = "歩数計エラー: $error";
      });
    });
  }

  /// 表示歩数をゼロにリセット
  void _resetSteps() {
    setState(() {
      _baselineSteps = _rawSteps;
      _statusMessage = "歩数がリセットされました";
    });
  }

  @override
  Widget build(BuildContext context) {
    int displaySteps = _rawSteps - _baselineSteps;

    // ===== 追加：距離の計算（km単位） =====
    double distanceKm = (displaySteps * _stepLength) / 1000;

    return Scaffold(
      appBar: AppBar(title: Text("歩数計")),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "歩数: $displaySteps",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // ===== 距離表示 =====
                  Text(
                    "距離: ${distanceKm.toStringAsFixed(2)} km",
                    style: TextStyle(fontSize: 24, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 20),

                  Text(
                    _statusMessage,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _resetSteps,
                    child: Text("歩数をリセット（再計算）"),
                  ),

                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _saveTodaySteps,
                    child: Text("本日の歩数を履歴に保存"),
                  ),

                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _requestPermissionAndInitPedometer,
                    child: Text("権限を再リクエスト / 歩数計を再起動"),
                  ),
                ],
              ),
            ),
          ),

          // ===== 履歴表示エリア =====
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text("歩数履歴",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),

                _history.isEmpty
                    ? Text("まだ履歴がありません")
                    : Column(
                        children: _history.entries.map((entry) {
                          return ListTile(
                            title: Text("${entry.key}"),
                            trailing: Text("${entry.value} 歩"),
                          );
                        }).toList(),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
