import 'package:drift/drift.dart';

class SyncLogTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get status => text()();
}