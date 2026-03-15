import 'dart:io';

void main() {
  final dFile = File('kangal/lib/data/models/date_range.dart');
  dFile.writeAsStringSync('''class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
''');

  final dashFile = File('kangal/lib/ui/dashboard/dashboard_view_model.dart');
  String dashContent = dashFile.readAsStringSync();
  dashContent = dashContent.replaceFirst('class DateRange {\n  final DateTime start;\n  final DateTime end;\n\n  DateRange({required this.start, required this.end});\n}\n\n', '');
  dashContent = "import 'package:kangal/data/models/date_range.dart';\n" + dashContent;
  dashFile.writeAsStringSync(dashContent);
}
