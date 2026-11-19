-- v1.1: единый график компании. Существующие индивидуальные графики сохраняются.
create table if not exists public.ett_company_schedule (
 owner_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
 timezone text not null default 'Europe/Moscow',
 weekly jsonb not null default '{"1":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"2":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"3":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"4":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"5":{"enabled":true,"start":"09:00","end":"18:00","break_minutes":60},"6":{"enabled":false,"start":"09:00","end":"18:00","break_minutes":60},"0":{"enabled":false,"start":"09:00","end":"18:00","break_minutes":60}}'::jsonb,
 updated_at timestamptz not null default now(),
 constraint ett_company_schedule_weekly_object check(jsonb_typeof(weekly)='object')
);
alter table public.ett_company_schedule enable row level security;
drop policy if exists ett_company_schedule_owner_select on public.ett_company_schedule;
drop policy if exists ett_company_schedule_owner_insert on public.ett_company_schedule;
drop policy if exists ett_company_schedule_owner_update on public.ett_company_schedule;
drop policy if exists ett_company_schedule_owner_delete on public.ett_company_schedule;
create policy ett_company_schedule_owner_select on public.ett_company_schedule for select to authenticated using(owner_id=auth.uid());
create policy ett_company_schedule_owner_insert on public.ett_company_schedule for insert to authenticated with check(owner_id=auth.uid());
create policy ett_company_schedule_owner_update on public.ett_company_schedule for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy ett_company_schedule_owner_delete on public.ett_company_schedule for delete to authenticated using(owner_id=auth.uid());
revoke all on public.ett_company_schedule from anon;
grant select,insert,update,delete on public.ett_company_schedule to authenticated;
