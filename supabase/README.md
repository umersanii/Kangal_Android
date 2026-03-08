# Supabase SQL Migration Scripts

The following SQL can be executed in Supabase (PostgreSQL) to create the
necessary tables for the Kangal personal finance application. Each table
includes an additional `user_id` column referencing `auth.users(id)` and has
row-level security enabled with a policy that allows users to access only their
own rows.

---

## transactions

```sql
create table if not exists transactions (
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
  category_id integer references categories(id),
  note text,
  extra text,
  synced_at timestamp,
  updated_at timestamp not null default now(),
  created_at timestamp not null default now()
);

alter table transactions enable row level security;
create policy "Users can only access own rows" on transactions
  for all
  using (auth.uid() = user_id);
```

## categories

```sql
create table if not exists categories (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  name text not null,
  emoji text not null,
  color text not null,
  is_default boolean not null
);

alter table categories enable row level security;
create policy "Users can only access own rows" on categories
  for all
  using (auth.uid() = user_id);
```

## rules

```sql
create table if not exists rules (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  keyword text not null,
  category_id integer not null references categories(id)
);

alter table rules enable row level security;
create policy "Users can only access own rows" on rules
  for all
  using (auth.uid() = user_id);
```

## sync_log

```sql
create table if not exists sync_log (
  id serial primary key,
  user_id uuid not null references auth.users(id),
  table_name text not null,
  last_synced_at timestamp not null,
  status text not null
);

alter table sync_log enable row level security;
create policy "Users can only access own rows" on sync_log
  for all
  using (auth.uid() = user_id);
```
