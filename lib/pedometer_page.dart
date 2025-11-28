import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  late Stream<StepCount> _stepStream;

  int _rawSteps = 0;          // システムから取得される累計歩数
  int _baselineSteps = 0;     // リセット時の基準歩数
  String _statusMessage = "歩数計を読み込み中…"; // ステータスメッセージ

  Map<String, int> _history = {};  // 歩数履歴（日付 → 歩数）

  double _stepLength = 0.7;   // 1歩あたりの歩幅（メートル）
  Timer? _refreshTimer;       // 定期リフレッシュ用タイマー

  @override
  void initState() {
    super.initState();
    _loadHistory();             // 歩数履歴をロード
    _loadStepLength();          // 保存された歩距をロード
    _requestPermissionAndInitPedometer(); // 権限確認と歩数計初期化
    _startAutoRefresh();        // 自動リフレッシュ開始
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();    // タイマーをキャンセル
    super.dispose();
  }

  /// 自動リフレッシュを開始
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _refreshSteps();
    });
  }

  /// UIを更新するリフレッシュ処理（手動・自動）
  void _refreshSteps() {
    setState(() {
      _statusMessage = "歩数を更新しました";
    });
  }

  /// 歩数履歴をSharedPreferencesから読み込む
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString("step_history");
    if (jsonString != null) {
      setState(() {
        _history = Map<String, int>.from(json.decode(jsonString));
      });
    }
  }

  /// 歩数履歴をSharedPreferencesに保存
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

  /// 権限を確認し、歩数計を初期化
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

    // 歩数データを監視
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

  /// 歩数をリセット
  void _resetSteps() {
    setState(() {
      _baselineSteps = _rawSteps;
      _statusMessage = "歩数がリセットされました";
    });
  }

  /// 保存された歩距をロード
  Future<void> _loadStepLength() async {
    final prefs = await SharedPreferences.getInstance();
    double? saved = prefs.getDouble("step_length");
    if (saved != null) {
      setState(() {
        _stepLength = saved;
      });
    }
  }

  /// 歩距を保存（Sliderの値変更時に呼ばれる）
  Future<void> _saveStepLength(double value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stepLength = value;
      _statusMessage = "歩距を更新しました: $_stepLength m";
    });
    await prefs.setDouble("step_length", _stepLength);
  }

  @override
  Widget build(BuildContext context) {
    int displaySteps = _rawSteps - _baselineSteps;
    double distanceKm = (displaySteps * _stepLength) / 1000;

    return Scaffold(
      appBar: AppBar(title: Text("歩数計")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 歩数表示
                    Text(
                      "歩数: $displaySteps",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    // 距離表示
                    Text(
                      "距離: ${distanceKm.toStringAsFixed(2)} km",
                      style: TextStyle(fontSize: 24, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 20),
                    // ステータスメッセージ
                    Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),

                    // 手動更新ボタン
                    ElevatedButton(
                      onPressed: _refreshSteps,
                      child: Text("更新"),
                    ),
                    SizedBox(height: 10),
                    // リセットボタン
                    ElevatedButton(
                      onPressed: _resetSteps,
                      child: Text("歩数をリセット（再計算）"),
                    ),
                    SizedBox(height: 10),
                    // 今日の歩数保存
                    ElevatedButton(
                      onPressed: _saveTodaySteps,
                      child: Text("本日の歩数を履歴に保存"),
                    ),
                    SizedBox(height: 10),
                    // 権限再取得 / 歩数計再起動
                    ElevatedButton(
                      onPressed: _requestPermissionAndInitPedometer,
                      child: Text("権限を再リクエスト / 歩数計を再起動"),
                    ),

                    SizedBox(height: 20),
                    // 歩距Slider
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          // 現在の歩距表示
                          Text(
                            "歩距: ${_stepLength.toStringAsFixed(2)} m",
                            style: TextStyle(fontSize: 18),
                          ),
                          Slider(
                            min: 0.3,
                            max: 1.5,
                            divisions: 24,
                            value: _stepLength,
                            label: _stepLength.toStringAsFixed(2),
                            onChanged: (value) {
                              _saveStepLength(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 歩数履歴表示
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
