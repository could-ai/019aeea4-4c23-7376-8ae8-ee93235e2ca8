import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'deliveries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE deliveries(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, latitude REAL, longitude REAL, createdAt TEXT)',
        );
      },
    );
  }

  Future<int> insertDelivery(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('deliveries', row);
  }

  Future<List<Map<String, dynamic>>> getDeliveries() async {
    Database db = await database;
    return await db.query('deliveries', orderBy: 'createdAt DESC');
  }

  Future<int> deleteDelivery(int id) async {
    Database db = await database;
    return await db.delete('deliveries', where: 'id = ?', whereArgs: [id]);
  }
}
