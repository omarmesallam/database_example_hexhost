import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
          mainAxisAlignment: MainAxisAlignment.start,
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
            const SizedBox(height: 30.0, child: Text('OR')),
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
            const SizedBox(height: 20,),
            ElevatedButton(
              onPressed: () async {

                if (_itemMESCController.text.trim().isNotEmpty) {
                  await getItemDataByMESC_assets('${_itemMESCController.text.trim()}-A');
                }
                else if( _partNumberController.text.trim().isNotEmpty )  {
                  await getItemDataByPartNumber(_partNumberController.text.trim());
                }
              },
              child: const Text('Get Item Information'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () async {
                await searchPartNumInProjects();
              },
              child: const Text('Search Part Number in Projects'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () async {
                await getManufacturerFromMESC();
              },
              child: const Text('Get Manufacturer from MESC'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () async {
                await getMESCByPartNumber();
              },
              child: const Text('Get MESC by Part Number'),
            ),
            const SizedBox(height: 20,),

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

  Future<void> getItemDataByMESC_assets(String itemCode) async {
    try {
      final csvString = await rootBundle.loadString('assets/KPC_20.csv');
      final lines = const LineSplitter().convert(csvString);

      if (lines.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Item: $itemCode'),
              content: const Text('Asset file KPC_20.csv is empty.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Parse headers from first line
      final headerFields = lines[0].split('\t').map((h) => sanitizeColumnName(h)).toList();

      final results = <Map<String, dynamic>>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        final fields = line.split('\t');
        if (fields.length > 3) {
          final rowItem = fields[3].trim();
          if (rowItem.toLowerCase() == itemCode.trim().toLowerCase()) {
            final rowMap = <String, dynamic>{};
            for (var j = 0; j < headerFields.length && j < fields.length; j++) {
              rowMap[headerFields[j]] = fields[j];
            }
            results.add(rowMap);
          }
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Item: $itemCode'),
            content: SingleChildScrollView(
              child: Text(
                results.isNotEmpty
                    ? results.map((r) => r.entries.map((e) => '${e.key}: ${e.value}').join('\n')).join('\n-------------------\n')
                    : 'No record found for item "$itemCode" in KPC_20.csv',
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
    } catch (e) {
      print('Error reading asset KPC_20.csv: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to read asset: $e'),
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
    final unitProjects = await findPartNumInProjects(partNumber);
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
                'Unit Projects: ${unitProjects.isNotEmpty ? unitProjects.join(", ") : "Not found in unit parts"}\n'
                '-------------------\n'
                '${results.isNotEmpty ? results.map((r) => r.entries.map((e) => '${e.key}: ${e.value}').join('\n')).join('\n-------------------\n') : 'No record found for Part Number "$partNumber"'}',
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

  Future<void> getManufacturerFromMESC() async {
    final rawMesc = _itemMESCController.text.trim();
    if (rawMesc.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an Item MESC first.')),
        );
      }
      return;
    }

    final mescCode = rawMesc.endsWith('-A') ? rawMesc : '$rawMesc-A';

    try {
      final csvString = await rootBundle.loadString('assets/KPC_20.csv');
      final lines = const LineSplitter().convert(csvString);

      String? manufacturerInfo;
      String? itemDesc;

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        final fields = line.split('\t');
        if (fields.length > 3) {
          final rowItem = fields[3].trim();
          if (rowItem.toLowerCase() == mescCode.toLowerCase()) {
            if (fields.length > 16) {
              manufacturerInfo = fields[16].trim();
            }
            if (fields.length > 4) {
              itemDesc = fields[4].trim();
            }
            break;
          }
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Manufacturer for MESC: $mescCode'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itemDesc != null && itemDesc.isNotEmpty) ...[
                    Text('Description:\n$itemDesc', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    (manufacturerInfo != null && manufacturerInfo.isNotEmpty)
                        ? 'Manufacturer:\n$manufacturerInfo'
                        : 'No manufacturer details found for MESC "$mescCode" in KPC_20.csv.',
                  ),
                ],
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
    } catch (e) {
      print('Error getting manufacturer from MESC: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to read manufacturer data: $e'),
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

  Future<void> getMESCByPartNumber() async {
    final partNumber = _partNumberController.text.trim();
    if (partNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Part Number first.')),
        );
      }
      return;
    }

    try {
      final csvString = await rootBundle.loadString('assets/KPC_20.csv');
      final lines = const LineSplitter().convert(csvString);

      final matches = <Map<String, String>>[];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        if (line.toLowerCase().contains(partNumber.toLowerCase())) {
          final fields = line.split('\t');
          final org = (fields.length > 2) ? fields[2].trim() : '';
          final mescCode = (fields.length > 3) ? fields[3].trim() : 'Unknown';
          final desc = (fields.length > 4) ? fields[4].trim() : '';
          final manufacturer = (fields.length > 16) ? fields[16].trim() : '';

          matches.add({
            'org': org,
            'mesc': mescCode,
            'desc': desc,
            'manufacturer': manufacturer,
          });
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('MESC for Part Number: $partNumber'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: matches.isNotEmpty
                    ? matches.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MESC: ${m['mesc']}${m['org']!.isNotEmpty ? "   (Org: ${m['org']})" : ""}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (m['desc']!.isNotEmpty) Text('Description: ${m['desc']}'),
                            if (m['manufacturer']!.isNotEmpty) Text('Manufacturer: ${m['manufacturer']}'),
                            const Divider(),
                          ],
                        ),
                      )).toList()
                    : [Text('No MESC code found matching Part Number "$partNumber" in KPC_20.csv.')],
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
    } catch (e) {
      print('Error finding MESC by part number: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to search MESC by Part Number: $e'),
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

  Future<void> searchPartNumInProjects() async {
    final partNumber = _partNumberController.text.trim();
    if (partNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Part Number first.')),
        );
      }
      return;
    }

    final projects = await findPartNumInProjects(partNumber);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Part Number Search: $partNumber'),
          content: Text(
            projects.isNotEmpty
                ? 'Part Number "$partNumber" was found in ${projects.length} Projects:\n${projects.join(", ")}'
                : 'Part Number "$partNumber" was NOT found in any project in each_unit_parts.csv',
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
