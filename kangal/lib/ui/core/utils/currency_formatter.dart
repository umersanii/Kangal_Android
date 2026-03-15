import 'package:intl/intl.dart';

final NumberFormat _pkrFormatter = NumberFormat.currency(
  locale: 'en_PK',
  symbol: 'Rs. ',
  decimalDigits: 2,
);

String formatPkr(double amount) => _pkrFormatter.format(amount);
