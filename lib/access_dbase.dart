import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mysql1/mysql1.dart';

/// Establishes a connection to the MariaDB database.
Future<MySqlConnection?> connectToDb() async {
  final settings = ConnectionSettings(
    host: 'mohamed.hexhost.online',
    port: 3306,
    user: 'mohamedm_mohamedelwan',
    password: '3030@Salma',
    db: 'mohamedm_nouralislam',
    timeout: Duration(seconds: 60),
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    print('Successfully connected to the database!');
    return conn;
  } catch (e) {
    final errorMsg = e.toString();
    if (errorMsg.contains('1130')) {
      print('\n[REMOTE ACCESS DENIED] MariaDB Error 1130');
      print('Details: $errorMsg');
      print('TO FIX: Log into your cPanel, find "Remote MySQL", and add your IP to the whitelist.');
    } else {
      print('Error while connecting to MariaDB: $e');
    }

    if (errorMsg.contains('110') || errorMsg.contains('10060')) {
      print('\nTIP: Connection Timed Out. Check your IP whitelist in cPanel.');
    }
    return null;
  }
}
/// Sanitizes a raw CSV column name to be a valid SQL table field name.
String sanitizeColumnName(String rawName) {
  var name = rawName.trim().toLowerCase();
  // Replace special characters, punctuation, and spaces with underscores
  name = name.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  // Collapse consecutive underscores into a single underscore
  name = name.replaceAll(RegExp(r'_+'), '_');
  // Remove leading and trailing underscores
  name = name.replaceAll(RegExp(r'^_+|_+$'), '');
  // Prefix with 'yr_' if the name starts with a digit (e.g. 1yr -> yr_1)
  if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = 'yr_$name';
  }
  return name;
}

/// Sanitized table column names suitable for database fields.
final List<String> columnNames = [
  'uom',
  'sub_inv',
  'org',
  'item',
  'long_desc',
  'onhand',
  'min_qty',
  'max_qty',
  'onorder',
  'inprocess',
  'last_yr',
  'yr_1',
  'relation_type',
  'yr_2',
  'yr_3',
  'location',
  'manufacturer',
  'average_price_usd',
  'status',
  'serial_no',
  'last_po_price',
  'curr',
  'creation_date',
  'has_attch',
  'category',
  'asset_group',
  'parts_for',
  'ass_internal_info',
  'item_type',
  'relation_qty_remarks',
  'hold',
];
final List<String> ProjectNum=[
  '77111'	,'74681',	'3c703_3G682' ,'3A921',	'3E651'	,'3A111',	'53091',	'53092'	,'3A673',	'3C951',	'3C851',	'3C941'	,'3P991'	,'A4030',	'A4031',	'74121'
];



/// Creates a new table in the database using the [columnNames] list.
Future<void> createTable(MySqlConnection connection, String tableName, [List<String>? fields]) async {
  try {
    // If fields are provided, use them; otherwise construct field definitions from columnNames with TEXT data type
    final columnDefs = (fields != null && fields.isNotEmpty)
        ? fields
        : columnNames.map((col) => '`$col` TEXT').toList();

    final fieldsStr = 'id INT AUTO_INCREMENT PRIMARY KEY, ${columnDefs.join(', ')}';
    final sql = 'CREATE TABLE IF NOT EXISTS `$tableName` ($fieldsStr)';

    print('Creating table "$tableName"...');
    await connection.query(sql);
    print('Table "$tableName" created successfully.');
  } catch (e) {
    print('Error creating table: $e');
  }
}

/// Reads and displays data from a specific table (limited to [limit] rows for optimal network performance).
Future<void> readTableData(MySqlConnection connection, String tableName, {int limit = 50}) async {
  try {
    print('\nFetching data from "$tableName"...');

    // Get total row count first
    final countResult = await connection.query('SELECT COUNT(*) FROM `$tableName`');
    final totalRows = countResult.first[0] ?? 0;
    print('Total rows in "$tableName": $totalRows');

    final results = await connection.query('SELECT * FROM `$tableName` LIMIT $limit');

    if (results.isEmpty) {
      print('The table "$tableName" is empty.');
    } else {
      // Print column names
      final headers = results.fields.map((f) => f.name ?? '').toList();
      print('Columns: $headers');
      print('Displaying first ${results.length} row(s):');
      print('-' * 50);

      for (var row in results) {
        print(row.values);
      }
    }
  } catch (e) {
    final errorMsg = e.toString();
    print('Error accessing table "$tableName": $e');
    if (errorMsg.contains('1146')) {
      print('TIP: Table "$tableName" does not exist.');
    }
  }
}

/// Adds data to a specific table.
Future<void> addDataToTable(MySqlConnection connection, String tableName, List<List<dynamic>> dataRows) async {
  if (dataRows.isEmpty) {
    print('No data to insert.');
    return;
  }

  try {
    // Get column names from the database table
    final columnsResult = await connection.query('SHOW COLUMNS FROM `$tableName`');

    // Filter columns that are not AUTO_INCREMENT
    final targetColumns = <String>[];
    for (var row in columnsResult) {
      // Row is list-like, col[0] is Field, col[5] is Extra
      final extra = row[5]?.toString().toLowerCase() ?? '';
      if (!extra.contains('auto_increment')) {
        targetColumns.add('`${row[0]}`');
      }
    }

    if (targetColumns.isEmpty) {
      print('Error: No insertable columns found in table "$tableName".');
      return;
    }

    final numDataCols = targetColumns.length;
    final colNamesStr = targetColumns.join(', ');
    final placeholders = List.filled(numDataCols, '?').join(', ');

    final sql = 'INSERT INTO `$tableName` ($colNamesStr) VALUES ($placeholders)';

    print('Inserting ${dataRows.length} rows into "$tableName"...');

    // mysql1 handles transactions via .transaction()
    await connection.transaction((ctx) async {
      for (var row in dataRows) {
        // Guarantee parameter length matches the query parameter count exactly
        final paddedRow = List<dynamic>.from(row);
        while (paddedRow.length < numDataCols) {
          paddedRow.add('');
        }
        if (paddedRow.length > numDataCols) {
          paddedRow.removeRange(numDataCols, paddedRow.length);
        }
        await ctx.query(sql, paddedRow);
      }
    });

    print('Successfully inserted ${dataRows.length} rows.');
  } catch (e) {
    print('Error inserting data into "$tableName": $e');
  }
}

/// Empties the database by dropping all tables and their contents.
Future<void> emptyDatabase(MySqlConnection connection) async {
  try {
    print('\n[WARNING] Emptying database (dropping all tables)...');

    // Disable foreign key checks to allow dropping tables with relationships
    await connection.query('SET FOREIGN_KEY_CHECKS = 0;');

    // Get all table names in the database
    final results = await connection.query('SHOW TABLES;');
    final tables = <String>[];

    for (var row in results) {
      if (row[0] != null) {
        tables.add(row[0].toString());
      }
    }

    if (tables.isEmpty) {
      print('Database is already empty (no tables found).');
    } else {
      print('Found ${tables.length} table(s) to drop: ${tables.join(', ')}');
      for (var tableName in tables) {
        print('Dropping table "$tableName"...');
        await connection.query('DROP TABLE IF EXISTS `$tableName`;');
      }
      print('Database has been completely emptied of all tables and rows.');
    }
  } catch (e) {
    print('Error emptying database: $e');
  } finally {
    try {
      await connection.query('SET FOREIGN_KEY_CHECKS = 1;');
    } catch (_) {}
  }
}

/// Clears all rows from all tables in the database while keeping table schemas.
Future<void> clearAllTableRows(MySqlConnection connection) async {
  try {
    print('\n[WARNING] Clearing all rows from all tables...');

    await connection.query('SET FOREIGN_KEY_CHECKS = 0;');

    final results = await connection.query('SHOW TABLES;');
    final tables = <String>[];

    for (var row in results) {
      if (row[0] != null) {
        tables.add(row[0].toString());
      }
    }

    if (tables.isEmpty) {
      print('No tables found in the database.');
    } else {
      for (var tableName in tables) {
        print('Truncating table "$tableName"...');
        await connection.query('TRUNCATE TABLE `$tableName`;');
      }
      print('All table rows cleared successfully.');
    }
  } catch (e) {
    print('Error clearing table rows: $e');
  } finally {
    try {
      await connection.query('SET FOREIGN_KEY_CHECKS = 1;');
    } catch (_) {}
  }
}

/// Reads assets/KPC_OIL_STOCK.csv and imports all data into the 'kpc_data' table.
Future<void> importCsvToKpcData(MySqlConnection connection, {String tableName = 'kpc_data'}) async {
  try {
    print('Loading CSV asset...');
    final csvString = await rootBundle.loadString('assets/KPC_20.csv');

    final lines = const LineSplitter().convert(csvString);
    if (lines.isEmpty) {
      print('CSV file is empty.');
      return;
    }

    print('Total lines in CSV (including header): ${lines.length}');

    final expectedCols = columnNames.length; // 31 columns

    // Skip header line (index 0), parse data rows
    final dataRows = <List<dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      // Tab-separated values
      var fields = line.split('\t');

      // Ensure every row has exact expected length matching columnNames
      if (fields.length < expectedCols) {
        fields = List<String>.from(fields)..addAll(List.filled(expectedCols - fields.length, ''));
      } else if (fields.length > expectedCols) {
        fields = fields.sublist(0, expectedCols);
      }

      dataRows.add(fields);
    }

    print('Parsed ${dataRows.length} data rows.');

    // Ensure table exists
    await createTable(connection, tableName);

    // Insert data rows in batches of 200
    const batchSize = 200;
    for (var i = 0; i < dataRows.length; i += batchSize) {
      final end = (i + batchSize < dataRows.length) ? i + batchSize : dataRows.length;
      final batch = dataRows.sublist(i, end);
      print('Inserting batch ${(i ~/ batchSize) + 1} (${batch.length} rows)...');
      await addDataToTable(connection, tableName, batch);
    }

    print('Successfully imported all CSV data into "$tableName".');
  } catch (e) {
    print('Error importing CSV data: $e');
  }
}

/// Fetches row data from a database table where the 'item' column matches [itemValue].
Future<List<Map<String, dynamic>>> getRowByItem(MySqlConnection connection, String itemValue, {String tableName = 'kpc_data'}) async {
  try {
    print('\nFetching data for item "$itemValue" from "$tableName"...');
    final sql = 'SELECT * FROM `$tableName` WHERE `item` = ?';
    final results = await connection.query(sql, [itemValue.trim()]);

    final rows = <Map<String, dynamic>>[];
    if (results.isEmpty) {
      print('No record found matching item "$itemValue".');
    } else {
      print('Found ${results.length} matching record(s):');
      final headers = results.fields.map((f) => f.name ?? '').toList();

      for (var row in results) {
        final rowMap = <String, dynamic>{};
        for (var i = 0; i < headers.length; i++) {
          final headerName = headers[i];
          if (headerName.isNotEmpty) {
            rowMap[headerName] = row[i];
          }
        }
        rows.add(rowMap);
        print(rowMap);
      }
    }
    return rows;
  } catch (e) {
    print('Error searching for item "$itemValue": $e');
    return [];
  }
}

/// Fetches row data from a database table where Manufacturer, Long Desc, or other text columns contain [partNumber].
Future<List<Map<String, dynamic>>> getRowByPartNumber(MySqlConnection connection, String partNumber, {String tableName = 'kpc_data'}) async {
  try {
    print('\nSearching for Part Number "$partNumber" in "$tableName"...');
    final query = '%${partNumber.trim()}%';
    final sql = 'SELECT * FROM `$tableName` WHERE `manufacturer` LIKE ? OR `long_desc` LIKE ? OR `ass_internal_info` LIKE ?';
    final results = await connection.query(sql, [query, query, query]);

    final rows = <Map<String, dynamic>>[];
    if (results.isEmpty) {
      print('No record found matching Part Number "$partNumber".');
    } else {
      print('Found ${results.length} matching record(s):');
      final headers = results.fields.map((f) => f.name ?? '').toList();

      for (var row in results) {
        final rowMap = <String, dynamic>{};
        for (var i = 0; i < headers.length; i++) {
          final headerName = headers[i];
          if (headerName.isNotEmpty) {
            rowMap[headerName] = row[i];
          }
        }
        rows.add(rowMap);
        print(rowMap);
      }
    }
    return rows;
  } catch (e) {
    print('Error searching for Part Number "$partNumber": $e');
    return [];
  }
}

/// Searches for [partNumber] in assets/each_unit_parts.csv.
/// Returns the 1-based matched row number (or -1 if not found).
Future<List<String>> findPartNumInProjects(String partNumber) async {
  List<String> found=[];
  try {
    final csvString = await rootBundle.loadString('assets/each_unit_parts.csv');
    final lines = const LineSplitter().convert(csvString);

    final target = partNumber.trim().toLowerCase();
    if (target.isEmpty) return [];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final items = line.split(',');
      for (var item in items) {
        final cleanItem = item.trim().toLowerCase();
        //cleanItem.contains(target)
        if (cleanItem == target ) {
          print('Found Part Number "$partNumber" at row ${i} in each_unit_parts.csv');
          found.add( ProjectNum[ i]);
          break;// 1-based row number
        }
      }
    }
    print(found);
    return found;
  } catch (e) {
    print('Error searching in assets/each_unit_parts.csv: $e');
  }
  return [];
}
//
// void main() async {
//   // 1. Connect
//   final connection = await connectToDb();
//
//   if (connection != null) {
//     // 2. Example Data
//     // final dataRows = [
//     //   ['mohamed hussin', 'mhussin@fff.sss'],
//     //   ['ahmed hussin', 'sdsdad@ddd.com']
//     // ];
//
//     // 3. Add and Read Data
//     // await addDataToTable(connection, 'secretdata', dataRows);
//     await readTableData(connection, 'secretdata');
//
//     // 4. Close Connection
//     await connection.close();
//     print('\nConnection closed.');
//   }
// }
