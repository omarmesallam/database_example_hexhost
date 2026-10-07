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
  final TextEditingController _itemMESCController = TextEditingController(text: '20-70-01-127');
  final TextEditingController _partNumberController = TextEditingController();
  final buttonsEnabled=false;

  @override
  void dispose() {
    _itemMESCController.dispose();
    _partNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Title(color: Colors.blueAccent, child: Text('KPC Turbines Stock'))),
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
                controller: _itemMESCController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Item MESC',
                  border: OutlineInputBorder(),
                  hint: Text(textAlign: TextAlign.end,
                      'e.g. 20-70-01-127'),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: _partNumberController,
                decoration: const InputDecoration(

                  labelText: 'Part Number',
                  border: OutlineInputBorder(),
                  hint: Text(textAlign: TextAlign.right,
                      'e.g. 912755C1'),

                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {

                if (_itemMESCController.text.trim().isNotEmpty) {
                  await getItemDataByMESC('${_itemMESCController.text.trim()}-A');
                }
                else if( _partNumberController.text.trim().isNotEmpty )  {
                  await getItemDataByPartNumber(_partNumberController.text.trim());
                }
              },
              child: const Text('Get Item Information'),
            ),
            const Spacer(),

            buttonsEnabled? ElevatedButton(onPressed: () async{
               await getAllData(); },
                child: const Text('get all rows')):Spacer(),

            buttonsEnabled? ElevatedButton(onPressed:   () async{
              await importKpcData();
                        }
               , child: const Text('Import KPC CSV Data')):Spacer(),

            buttonsEnabled? ElevatedButton(onPressed:  () async{
              await emptyDatabase_method();}
             , child: const Text('empty database')):Spacer(),

            buttonsEnabled? ElevatedButton(onPressed: () async{
             // await createTable_method();
            }, child: const Text('clear all rows')):Spacer(),
          ],
        ),
      ),
    );
  }

   Future<void> getItemDataByMESC(String itemCode) async {
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

  Future<void> getItemDataByPartNumber(String partNumber) async {
    final connection = await connectToDb();
    if (connection != null) {
      final results = await getRowByPartNumber(connection, partNumber, tableName: 'kpc_data');
      await connection.close();
      print('\nConnection closed.');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Part Number: $partNumber'),
            content: SingleChildScrollView(
              child: Text(
                results.isNotEmpty
                    ? results.map((r) => r.entries.map((e) => '${e.key}: ${e.value}').join('\n')).join('\n-------------------\n')
                    : 'No record found for Part Number "$partNumber"',
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

   Future<void> getAllData() async {
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
