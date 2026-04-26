import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbService {
  static Db? _db;

  static Future<Db> getDb() async {
    if (_db != null && _db!.isConnected) return _db!;
    _db = await Db.create(dotenv.env['mongodb+srv://soalku_admin:KXmghCdEnVnwL170@soalku-cluster.u04nbqy.mongodb.net/?appName=soalku-cluster']!);
    await _db!.open();
    return _db!;
  }

  static DbCollection getCollection(String name) {
    return _db!.collection(name);
  }
}