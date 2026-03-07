import 'package:drift/drift.dart';

class SyncLogTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  @override
  String get tableName => 'sync_log';
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get status => text()();
}
