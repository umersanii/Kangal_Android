abstract class SmsImportRepository {
  Future<int> importHistoricalSms();
  void startRealtimeListener();
}
