import 'package:drift/drift.dart';

class SyncLogTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncTableName => text().named('table_name')();
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get status => text()();
}
