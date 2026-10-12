import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:personalitytest/main/Question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage>{

  Future<String> loadAsset() async{
    return await rootBundle.loadString('res/api/list.json');
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body:FutureBuilder<String>(
        future : loadAsset(),
        builder : (context, snapshot){
          switch (snapshot.connectionState){
            case ConnectionState.waiting:
              return const Center(
                child : CircularProgressIndicator(),
              );
            case ConnectionState.done:
              if(snapshot.hasData){
                Map<String, dynamic> list = jsonDecode(snapshot.data!);
                return ListView.builder(
                  itemCount: list['count'],
                  itemBuilder: (context,index){
                    return InkWell(
                      onTap: () async {
                        try{
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'test_click',
                            parameters: {
                              'test_name':
                                  list['questions'][index]['title'].toString(),
                            },
                          );

                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context){
                          return QuestionPage(question: list['questions'][index]['file'].toString(),
);
                        },),);
                      } catch(e) {
                        print('Failed to log event: $e');
                        }
                      },
                      child : SizedBox(
                        height : 50,
                        child : Card(
                          child : Text(
                            list['questions'][index]['title'].toString(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }else if (snapshot.hasError){
                return Center(
                  child : Text('Error : $snapshot.error'),
                );
              }else {
                return const Center(
                  child : Text('No Data'),
                );
              }
          /// 0930 여기까지 작성
            default:
              return const Center(
                child: Text('No Data'),
              );
          }
        },
      ),
    );
  }
}