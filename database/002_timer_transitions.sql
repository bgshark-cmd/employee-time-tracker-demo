-- Employee Time Tracker v0.4: atomic timer transitions.
-- Run once in Supabase SQL Editor. Compatible with PostgreSQL + Supabase Auth.
-- Each employee has at most one open interval (existing unique partial index).
-- SECURITY INVOKER keeps the owner-scoped RLS policies in force.

create or replace function public.ett_switch_interval(
  p_employee_id uuid,
  p_kind text
)
returns public.ett_intervals
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_owner uuid;
  v_now timestamptz := clock_timestamp();
  v_current public.ett_intervals%rowtype;
  v_new public.ett_intervals%rowtype;
begin
  v_owner := (select auth.uid());
  if v_owner is null then
    raise exception 'Sign in required';
  end if;
  if p_kind not in ('work','lunch','break','personal','business','unexplained') then
    raise exception 'Invalid interval kind';
  end if;

  -- Serialize transitions for the same employee across devices.
  perform 1 from public.ett_employees
    where id = p_employee_id and owner_id = v_owner and archived = false
    for update;
  if not found then
    raise exception 'Employee not found or archived';
  end if;

  select * into v_current from public.ett_intervals
    where employee_id = p_employee_id and owner_id = v_owner and ended_at is null
    for update;

  if found then
    if v_current.kind = p_kind then
      return v_current; -- retry/double click: don't reset running timer
    end if;
    update public.ett_intervals
      set ended_at = greatest(v_now, started_at + interval '1 microsecond')
      where id = v_current.id;
  end if;

  insert into public.ett_intervals(owner_id, employee_id, kind, started_at)
    values(v_owner, p_employee_id, p_kind, v_now)
    returning * into v_new;
  return v_new;
end;
$$;

create or replace function public.ett_stop_interval(
  p_employee_id uuid
)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_owner uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
begin
  if v_owner is null then raise exception 'Sign in required'; end if;
  perform 1 from public.ett_employees
    where id = p_employee_id and owner_id = v_owner for update;
  if not found then raise exception 'Employee not found'; end if;
  update public.ett_intervals
    set ended_at = greatest(v_now, started_at + interval '1 microsecond')
    where employee_id = p_employee_id and owner_id = v_owner and ended_at is null;
  return found;
end;
$$;

revoke all on function public.ett_switch_interval(uuid,text) from public, anon;
revoke all on function public.ett_stop_interval(uuid) from public, anon;
grant execute on function public.ett_switch_interval(uuid,text) to authenticated;
grant execute on function public.ett_stop_interval(uuid) to authenticated;
