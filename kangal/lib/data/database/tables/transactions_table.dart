import 'package:drift/drift.dart';
import 'categories_table.dart';

class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get date => text()();
  RealColumn get amount => real()();
  TextColumn get source => text()();
  TextColumn get type => text().nullable()();
  TextColumn get transactionId => text().nullable().unique()();
  TextColumn get beneficiary => text().nullable()();
  TextColumn get subject => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(CategoriesTable, #id)();
  TextColumn get note => text().nullable()();
  TextColumn get extra => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
