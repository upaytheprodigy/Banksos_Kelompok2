import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbService {
  static Db? _db;

  static Future<Db> getDb() async {
    if (_db != null && _db!.isConnected) return _db!;
    
    final uri = dotenv.env['MONGO_URI'];
    if (uri == null || uri.isEmpty) {
      throw Exception('MONGO_URI tidak ditemukan di .env');
    }

    _db = await Db.create(uri);
    await _db!.open();
    return _db!;
  }

  static DbCollection getCollection(String name) {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database belum terhubung');
    }
    return _db!.collection(name);
  }
}