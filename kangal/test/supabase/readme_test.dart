import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supabase README contains required migration SQL', () {
    final file = File('../supabase/README.md');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'supabase/README.md should exist',
    );

    final content = file.readAsStringSync();

    // check for each table create statement and RLS policy
    expect(content.contains('create table if not exists transactions'), isTrue);
    expect(
      content.contains('user_id uuid not null references auth.users(id)'),
      isTrue,
    );
    expect(
      content.contains('alter table transactions enable row level security'),
      isTrue,
    );
    expect(
      content.contains(
        'create policy "Users can only access own rows" on transactions',
      ),
      isTrue,
    );

    expect(content.contains('create table if not exists categories'), isTrue);
    expect(
      content.contains('alter table categories enable row level security'),
      isTrue,
    );

    expect(content.contains('create table if not exists rules'), isTrue);
    expect(
      content.contains('alter table rules enable row level security'),
      isTrue,
    );

    expect(content.contains('create table if not exists sync_log'), isTrue);
    expect(
      content.contains('alter table sync_log enable row level security'),
      isTrue,
    );
  });
}
