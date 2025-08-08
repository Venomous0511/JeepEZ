import 'package:dart_backend/dart_backend.dart' as dart_backend;
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

final dbUri =
    'mongodb+srv://Venomous:Venomous0511@jeepcluster.lorfccn.mongodb.net/?retryWrites=true&w=majority&appName=jeepcluster';
final dbName = 'jeepcluster';

Future<void> main() async {
  final db = await Db.create(dbUri);
  await db.open();
  final userCollection = db.collection('users');

  final router = Router();

  // POST METHOD /users
  router.post('/users', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    await userCollection.insertOne(data);

    return Response.ok(
      jsonEncode({'status': 'User Added'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET METHOD /users
  router.get('/users', (Request request) async {
    final users = await userCollection.find().toList();
    return Response.ok(
      jsonEncode(users),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, '0.0.0.0', 8080);

  print('Server listening on port ${server.port}');
}
