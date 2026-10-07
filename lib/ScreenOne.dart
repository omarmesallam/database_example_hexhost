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
  final TextEditingController _itemController = TextEditingController(text: '20-70-01-127-A');

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Title(color: Colors.blueAccent, child: Text('new Title'))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 20-70-01-127-A',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await getItemData(_itemController.text);
              },
              child: const Text('Get Row by Item'),
            ),
            ElevatedButton(onPressed: () async{
               await getData();
            }, child: const Text('Get saved data')),
            ElevatedButton(onPressed: () async{
              await importKpcData();
            }, child: const Text('Import KPC CSV Data')),
            ElevatedButton(onPressed: () async{
              await emptyDatabase_method();
            }, child: const Text('empty database')),
            ElevatedButton(onPressed: () async{
             // await createTable_method();
            }, child: const Text('clear all rows')),
          ],
        ),
      ),
    );
  }

   Future<void> getItemData(String itemCode) async {
    final connection = await connectToDb();
    if (connection != null) {
      final results = await getRowByItem(connection, itemCode, tableName: 'kpc_data');
      await connection.close();
      print('\nConnection closed.');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Item: $itemCode'),
            content: SingleChildScrollView(
              child: Text(
                results.isNotEmpty
                    ? results.first.entries.map((e) => '${e.key}: ${e.value}').join('\n')
                    : 'No record found for item "$itemCode"',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

   Future<void> getData() async {
    final connection = await connectToDb();

    if (connection != null) {

      await readTableData(connection, 'kpc_data');

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
      await connection.close();
      print('\nConnection closed.');
    }
  }

  Future<void> createTable_method() async {
    final connection = await connectToDb();
    if (connection != null) {
      await createTable(connection, 'kpc_data');
      await connection.close();
    }
  }

  Future<void> emptyDatabase_method() async {
    final connection = await connectToDb();
    if (connection != null) {
      await emptyDatabase(connection);
      await connection.close();
    }
  }

  Future<void> importKpcData() async {
    final connection = await connectToDb();
    if (connection != null) {
      await importCsvToKpcData(connection);
      await connection.close();
      print('\nConnection closed.');
    }
  }



}
