-- Employee Time Tracker: initial portable PostgreSQL schema
-- Run in Supabase SQL Editor as project owner.
create extension if not exists pgcrypto;

create table if not exists public.ett_employees (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  name text not null check (length(trim(name)) between 1 and 100),
  color text not null default '#6366d9',
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  unique (id, owner_id)
);

create table if not exists public.ett_intervals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  employee_id uuid not null,
  kind text not null check (kind in ('work','lunch','break','personal','business','unexplained')),
  started_at timestamptz not null,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  check (ended_at is null or ended_at > started_at),
  foreign key (employee_id, owner_id) references public.ett_employees(id, owner_id)
);

create unique index if not exists ett_one_open_interval
on public.ett_intervals(employee_id) where ended_at is null;

create index if not exists ett_intervals_owner_start
on public.ett_intervals(owner_id, started_at);

create table if not exists public.ett_preferences (
  owner_id uuid primary key,
  work_start time not null default '10:00',
  work_end time not null default '19:00',
  lunch_minutes integer not null default 60 check (lunch_minutes between 0 and 1440),
  lost_limit_minutes integer not null default 30 check (lost_limit_minutes between 0 and 1440),
  late_grace_minutes integer not null default 15 check (late_grace_minutes between 0 and 1440),
  updated_at timestamptz not null default now()
);

alter table public.ett_employees enable row level security;
alter table public.ett_intervals enable row level security;
alter table public.ett_preferences enable row level security;

-- Authenticated users only; every operation is scoped to the account.
revoke all on public.ett_employees, public.ett_intervals, public.ett_preferences from anon;
grant select, insert, update, delete on public.ett_employees, public.ett_intervals, public.ett_preferences to authenticated;

create policy "ett_employees_owner" on public.ett_employees
for all to authenticated using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "ett_intervals_owner" on public.ett_intervals
for all to authenticated using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "ett_preferences_owner" on public.ett_preferences
for all to authenticated using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);
