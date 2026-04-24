import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart'; // The code generator will create this

// ==========================================
// 1. TABLE DEFINITIONS
// ==========================================

@DataClassName('Session')
class Sessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get averageRmssd => real().nullable()();
  RealColumn get signalQuality => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HrvWindow')
class HrvWindows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get rmssd => real()();
  IntColumn get bpm => integer()();
  BoolColumn get isReliable => boolean()();
}

// ==========================================
// 2. DATABASE CONFIGURATION & QUERIES
// ==========================================

@DriftDatabase(tables: [Sessions, HrvWindows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- Session Queries ---
  Future<void> createSession(Session session) => into(sessions).insert(session);
  
  Future<void> updateSession(Session session) => update(sessions).replace(session);
  
  Future<Session> getSession(String id) => 
      (select(sessions)..where((s) => s.id.equals(id))).getSingle();
      
  Future<List<Session>> getAllSessions() => 
      (select(sessions)..orderBy([(s) => OrderingTerm.desc(s.startTime)])).get();

  // --- HRV Window Queries ---
  Future<void> addHrvWindow(HrvWindow window) => into(hrvWindows).insert(window);
  
  Future<List<HrvWindow>> getWindowsForSession(String sId) =>
      (select(hrvWindows)
        ..where((w) => w.sessionId.equals(sId))
        ..orderBy([(w) => OrderingTerm.asc(w.timestamp)])).get();
}

// ==========================================
// 3. CONNECTION OPENER
// ==========================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dhritam_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Global singleton so the whole app shares one connection
final appDb = AppDatabase();