import 'dart:math';

import 'package:flutter/material.dart';
import 'package:word_generator/word_generator.dart';

import 'access_dbase.dart';

class ScreenOne extends StatefulWidget {
  ScreenOne({super.key});

  @override
  State<ScreenOne> createState() => _ScreenOneState();
}

class _ScreenOneState extends State<ScreenOne> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Title(color: Colors.blueAccent, child: Text('new Title'))),
      ),
      body: Center(
        child: Column(

          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () async{
               await getData();
            }, child: Text('Get saved data')),
            ElevatedButton(onPressed: () async{
              await addRandomData();
            }, child: Text('add random data'))
            //const Text("This is Screen One"),
          ],
        ),
      ),
    );
  }

   Future<void> getData() async {
    final connection = await connectToDb();

    if (connection != null) {

      await readTableData(connection, 'secretdata');

      // 4. Close Connection
      await connection.close();
      print('\nConnection closed.');
    }
  }

  Future<void> addRandomData() async {
    final connection = await connectToDb();
    final randomInst = Random();
    final rndNum= randomInst.nextInt(100);
    final wordGenerator = WordGenerator();

    // Generate a single random word
    final String randomWord = wordGenerator.randomNoun();
    final String randomEmail = "${wordGenerator.randomNoun()}@gmail.com";

   // 2. Example Data
    final dataRows = [

      [randomWord, randomEmail]
    ];

    //3. Add and Read Data
    if (connection != null) {
      print('Adding data...');
      await addDataToTable(connection, 'secretdata', dataRows);
      print('Data added successfully.');
    }
  }
}
