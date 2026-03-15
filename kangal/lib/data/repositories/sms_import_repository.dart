abstract class SmsImportRepository {
  Future<int> importHistoricalSms({int? daysBack});
  void startRealtimeListener();
}
