abstract class EmailImportRepository {
  /// Fetches NayaPay emails from the last 90 days via IMAP, parses them,
  /// deduplicates by transaction ID, applies auto-categorisation rules,
  /// and inserts new transactions into the local database.
  ///
  /// Returns the count of newly inserted transactions.
  /// Throws if credentials are missing or connection fails.
  Future<int> importEmails();

  /// Tests the IMAP connection using stored credentials.
  /// Returns `true` if connection succeeds, `false` otherwise.
  Future<bool> testConnection();
}
