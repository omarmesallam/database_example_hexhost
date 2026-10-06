import 'package:mysql1/mysql1.dart';

/// Establishes a connection to the MariaDB database.
Future<MySqlConnection?> connectToDb() async {
  final settings = ConnectionSettings(
    host: 'mohamed.hexhost.online',
    port: 3306,
    user: 'mohamedm_mohamedelwan',
    password: '3030@Salma',
    db: 'mohamedm_nouralislam',
    timeout: Duration(seconds: 10),
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

/// Creates a new table in the database.
Future<void> createTable(MySqlConnection connection, String tableName, List<String> fields) async {
  try {
    final fieldsStr = fields.join(', ');
    final sql = 'CREATE TABLE $tableName ($fieldsStr)';

    print('Creating table "$tableName"...');
    await connection.query(sql);
    print('Table "$tableName" created successfully.');
  } catch (e) {
    print('Error creating table: $e');
  }
}

/// Reads and displays data from a specific table.
Future<void> readTableData(MySqlConnection connection, String tableName) async {
  try {
    print('\nFetching data from "$tableName"...');
    final results = await connection.query('SELECT * FROM $tableName');

    if (results.isEmpty) {
      print('The table "$tableName" is empty.');
    } else {
      // Print column names
      final columnNames = results.fields.map((f) => f.name).toList();
      print('Columns: $columnNames');
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
    // Get column names to build the query
    final columnsResult = await connection.query('SHOW COLUMNS FROM $tableName');

    // Filter columns that are not AUTO_INCREMENT
    final targetColumns = <String>[];
    for (var row in columnsResult) {
      // Row is list-like, col[0] is Field, col[5] is Extra
      final extra = row[5]?.toString().toLowerCase() ?? '';
      if (!extra.contains('auto_increment')) {
        targetColumns.add(row[0].toString());
      }
    }

    final numDataCols = dataRows[0].length;
    final insertColumns = targetColumns.take(numDataCols).toList();

    final colNamesStr = insertColumns.join(', ');
    final placeholders = List.filled(numDataCols, '?').join(', ');

    final sql = 'INSERT INTO $tableName ($colNamesStr) VALUES ($placeholders)';

    print('Inserting data into "$tableName"...');

    // mysql1 handles transactions via .transaction()
    await connection.transaction((ctx) async {
      for (var row in dataRows) {
        await ctx.query(sql, row);
      }
    });

    print('Successfully inserted ${dataRows.length} rows.');
  } catch (e) {
    print('Error inserting data into "$tableName": $e');
  }
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
