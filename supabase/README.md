# Supabase SQL Migration Scripts

Run the following **single script** in Supabase SQL Editor to create all tables
for Kangal and configure Row Level Security (RLS).

This script is idempotent and safe to rerun:
- Uses `create table if not exists`
- Uses `public.` schema qualification
- Drops/recreates policies to avoid duplicate-policy errors

---

## Full migration (recommended)

```sql
-- 1) Tables
create table if not exists public.categories (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  name text not null,
  emoji text not null,
  color text not null,
  is_default boolean not null
);

create table if not exists public.rules (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  keyword text not null,
  category_id integer not null references public.categories(id)
);

create table if not exists public.transactions (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  remote_id text,
  date text not null,
  amount double precision not null,
  source text not null,
  type text,
  transaction_id text unique,
  beneficiary text,
  subject text,
  category_id integer references public.categories(id),
  note text,
  extra text,
  synced_at timestamp,
  updated_at timestamp not null default now(),
  created_at timestamp not null default now()
);

create table if not exists public.sync_log (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  table_name text not null,
  last_synced_at timestamp not null,
  status text not null
);

-- 2) Enable RLS
alter table public.categories enable row level security;
alter table public.rules enable row level security;
alter table public.transactions enable row level security;
alter table public.sync_log enable row level security;

-- 3) Policies
drop policy if exists "Users can only access own rows" on public.categories;
create policy "Users can only access own rows"
on public.categories
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can only access own rows" on public.rules;
create policy "Users can only access own rows"
on public.rules
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can only access own rows" on public.transactions;
create policy "Users can only access own rows"
on public.transactions
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can only access own rows" on public.sync_log;
create policy "Users can only access own rows"
on public.sync_log
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
```

## Quick verification

```sql
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('categories', 'rules', 'transactions', 'sync_log')
order by table_name;
```

If you see `ERROR: relation "rules" does not exist`, run the full migration
above in one go (starting from table creation), not only the policy section.
