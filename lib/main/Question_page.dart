import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../detail/detail_page.dart';

class QuestionPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const QuestionPage({super.key, required this.question});

  @override
  State<QuestionPage> createState() => _QuestionPage();
}

class _QuestionPage extends State<QuestionPage> {
  int? selectedOption;

  @override
  Widget build(BuildContext context) {
    final title = widget.question['title'].toString();
    final selects = widget.question['selects'] as List<dynamic>;
    final answers = widget.question['answer'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question['question'].toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RadioGroup<int>(
                groupValue: selectedOption,
                onChanged: (value) => setState(() => selectedOption = value),
                child: ListView.builder(
                  itemCount: selects.length,
                  itemBuilder: (context, index) => RadioListTile<int>(
                    title: Text(selects[index].toString()),
                    value: index,
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: selectedOption == null
                    ? null
                    : () async {
                        final answerIndex = selectedOption!;
                        try {
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'personal_select',
                            parameters: {
                              'test_name': title,
                              'select': answerIndex,
                            },
                          );
                          if (!context.mounted) return;
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                question: widget.question['question']
                                    .toString(),
                                answer: answers[answerIndex].toString(),
                              ),
                            ),
                          );
                        } catch (error) {
                          debugPrint('Failed to log event: $error');
                        }
                      },
                child: const Text('성격 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
