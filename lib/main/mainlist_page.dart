import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:async';

import 'package:personalitytest/main/question_page.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;
  late Future<List<Map<String, dynamic>>> testsFuture;

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    remoteConfigInit();
    _testRef = database.ref('test');
    testsFuture = loadTests();
    _checkInternetConnection(); // 초기 연결 상태 확인하기
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _handleConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _handleConnectionStatus(result);
  }

  void _handleConnectionStatus(List<ConnectivityResult> result) {
    for (var element in result) {
      if (element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi) {
        if (_isDialogOpen) {
          Navigator.of(context).pop(); // 대화 상자 닫기
          _isDialogOpen = false;
        }
        _testRef = database.ref('test');
        remoteConfigInit();
        return;
      } else {
        _showOfflineDialog(); // 인터넷에 연결되지 않으면 대화 상자 표시하기
      }
    }
  }

  void _showOfflineDialog() {
    if (!_isDialogOpen && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          _isDialogOpen = true;
          return AlertDialog(
            title: const Text('심리 테스트 앱'),
            content: const Text(
              '지금은 인터넷에 연결되지 않아 심리 테스트 앱을 '
              '사용할 수 없습니다. 나중에 다시 실행해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _isDialogOpen = false;
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      ).then((_) => _isDialogOpen = false); // 대화 상자를 닫을 때 _isDialogOpen = false
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // StreamSubscription 해제하기
    super.dispose();
  }

  void remoteConfigInit() async {
    await remoteConfig.fetch();
    await remoteConfig.activate();

    if (!mounted) return;
    setState(() {
      welcomeTitle = remoteConfig.getString('welcome');
      bannerUse = remoteConfig.getBool('banner');
      final configuredHeight = remoteConfig.getInt('item_height');
      itemHeight = configuredHeight > 0 ? configuredHeight : 50;
    });
  }

  Future<List<Map<String, dynamic>>> loadTests() async {
    try {
      final snapshot = await _testRef.get().timeout(const Duration(seconds: 5));
      final tests = <Map<String, dynamic>>[];

      for (final child in snapshot.children) {
        final value = child.value;
        if (value is String) {
          tests.add(Map<String, dynamic>.from(jsonDecode(value) as Map));
        } else if (value is Map) {
          tests.add(Map<String, dynamic>.from(value));
        }
      }

      if (tests.isNotEmpty) return tests;
    } catch (e) {
      debugPrint('Failed to load Realtime Database data: $e');
    }

    return loadLocalTests();
  }

  Future<List<Map<String, dynamic>>> loadLocalTests() async {
    final listData = await rootBundle.loadString('res/api/list.json');
    final list = jsonDecode(listData) as Map<String, dynamic>;
    final questions = list['questions'] as List<dynamic>;

    return Future.wait(
      questions.map((question) async {
        final fileName = (question as Map<String, dynamic>)['file'] as String;
        final questionData = await rootBundle.loadString(
          'res/api/$fileName.json',
        );
        return Map<String, dynamic>.from(jsonDecode(questionData) as Map);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bannerUse
          ? AppBar(title: Text(remoteConfig.getString('welcome')))
          : null,

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: testsFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return InkWell(
                      child: SizedBox(
                        height: itemHeight.toDouble(),
                        child: Card(
                          color: Colors.amber,
                          child: Text(item['title'].toString()),
                        ),
                      ),
                      onTap: () async {
                        await FirebaseAnalytics.instance.logEvent(
                          name: 'test_click',
                          parameters: {'test_name': item['title'].toString()},
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return QuestionPage(question: item);
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error : $snapshot.error'));
              } else {
                return const Center(child: Text('No Data'));
              }

            /// 0930 여기까지 작성
            default:
              return const Center(child: Text('No Data'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          FirebaseDatabase database = FirebaseDatabase.instance;
          DatabaseReference testRef = database.ref('test');
          testRef.push().set("""{
  "title": "당신이 좋아하는 애완동물은",
  "question": "당신이 무인도에 도착했는데 마침 떠내려온 상자를 열었을때 보이는 이것은",
  "selects": [
    "생존키트",
    "휴대폰",
    "텐트",
    "무인도에서 살아남기"
  ],
  "answer": [
    "당신은 현실주의 동물은 안키운다!!",
    "당신은 늘 함께 있는 걸 좋아하는 강아지가 딱입니다",
    "당신은 같은 공간을 공유하는 고양이",
    "당신은 낭만을 좋아하는 앵무새"
  ]
}""");
          testRef.push().set("""{
  "title": "5초 MBTI I/E 편",
  "question": "친구와 함께 간 미술관 당신이라면",
  "selects": [
    "말이 많아짐",
    "생각이 많아짐"
  ],
  "answer": [
    "당신의 성향은 E",
    "당신의 성향은 I"
  ]
}""");
          testRef.push().set("""{
  "title": "당신은 어떤 사랑을 하고 싶나요",
  "question": "목욕을 할때 가장 먼저 비누칠을 하는 곳은",
  "selects": [
    "머리",
    "상체",
    "하체"
  ],
  "answer": [
    "당신은 자만추를 추천해요",
    "당신은 소개팅을 통한 새로운 사람의 소개를 좋아합니다",
    "당신은 길가다가 우연히 지나친 그런 인연을 좋아합니다"
  ]
}""");
        },
      ),
    );
  }
}
