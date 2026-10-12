import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personalitytest/detail/detail_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class QuestionPage extends StatefulWidget {
  final String question;

  const QuestionPage({super.key, required this.question});

  @override
  State<QuestionPage> createState() {
    return _QuestionPage();
  }
}

class _QuestionPage extends State<QuestionPage> {
  int selectNumber = -1;

  Future<String> loadAsset(String fileName) async {
    return await rootBundle.loadString('res/api/$fileName.json');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: loadAsset(widget.question),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final Map<String, dynamic> questions =
        jsonDecode(snapshot.data!);

        final String title = questions['title'].toString();
        final List<dynamic> selects = questions['selects'];

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Column(
            children: [
              Text(questions['question'].toString()),
              Expanded(
                child: RadioGroup<int>(
                  groupValue: selectNumber == -1 ? null : selectNumber,
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        selectNumber = value;
                      });
                    }
                  },
                  child: ListView.builder(
                    itemCount: selects.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        height: 100,
                        child: Column(
                          children: [
                            Text(selects[index].toString()),
                            Radio<int>(
                              value: index,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (selectNumber != -1)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAnalytics.instance.logEvent(
                        name: 'personal_select',
                        parameters: {
                          'test_name': title,
                          'select': selectNumber,
                        },
                      );

                      if (!context.mounted) return;

                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) {
                            return DetailPage(
                              answer:
                              questions['answer'][selectNumber]
                                  .toString(),
                              question:
                              questions['question'].toString(),
                            );
                          },
                        ),
                      );
                    } catch (e) {
                      debugPrint('Failed to log event: $e');
                    }
                  },
                  child: const Text('성격보기'),
                ),
            ],
          ),
        );
      },
    );
  }
}