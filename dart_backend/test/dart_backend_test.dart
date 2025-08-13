import 'package:mongo_dart/mongo_dart.dart';

class DBService {
  static final dbUri = 'your-db-uri';
  static final dbName = 'your-db-name';

  static Future<Db> connect() async {
    final db = await Db.create(dbUri);
    await db.open();
    return db;
  }
}
