-- Employee Time Tracker v1.0: индивидуальный недельный график
-- Выполнить один раз в Supabase SQL Editor.
create table if not exists public.ett_schedules (
  employee_id uuid primary key,
  owner_id uuid not null default auth.uid(),
  timezone text not null default 'Europe/Moscow',
  weekly jsonb not null default '{"1":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"2":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"3":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"4":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"5":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"6":{"enabled":false,"start":"09:00","end":"18:00","break_minutes":60},"0":{"enabled":false,"start":"09:00","end":"18:00","break_minutes":60}}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint ett_schedules_employee_owner_fk foreign key(employee_id,owner_id) references public.ett_employees(id,owner_id) on delete cascade,
  constraint ett_schedules_weekly_object check(jsonb_typeof(weekly)='object')
);
alter table public.ett_schedules enable row level security;
drop policy if exists ett_schedules_owner_select on public.ett_schedules;
drop policy if exists ett_schedules_owner_insert on public.ett_schedules;
drop policy if exists ett_schedules_owner_update on public.ett_schedules;
drop policy if exists ett_schedules_owner_delete on public.ett_schedules;
create policy ett_schedules_owner_select on public.ett_schedules for select to authenticated using(owner_id=auth.uid());
create policy ett_schedules_owner_insert on public.ett_schedules for insert to authenticated with check(owner_id=auth.uid());
create policy ett_schedules_owner_update on public.ett_schedules for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy ett_schedules_owner_delete on public.ett_schedules for delete to authenticated using(owner_id=auth.uid());
revoke all on public.ett_schedules from anon;
grant select,insert,update,delete on public.ett_schedules to authenticated;
