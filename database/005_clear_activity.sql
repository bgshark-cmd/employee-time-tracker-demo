-- Install after 001_initial_schema.sql and 002_timer_transitions.sql.
-- Installing this function does not run it.
begin;

create or replace function public.ett_clear_activity(
  p_confirmation text,
  p_expected_count bigint,
  p_confirmed_owner uuid
)
returns bigint
language plpgsql
security invoker
set search_path = ''
set row_security = on
as $$
declare
  v_owner uuid := auth.uid();
  v_deleted bigint;
begin
  if v_owner is null or v_owner is distinct from p_confirmed_owner then
    raise exception 'The authenticated account changed' using errcode = '42501';
  end if;
  if not pg_catalog.row_security_active('public.ett_intervals'::pg_catalog.regclass) then
    raise exception 'Interval RLS is required' using errcode = '42501';
  end if;
  if p_confirmation is distinct from 'ОЧИСТИТЬ'
     or p_expected_count is null or p_expected_count < 1 then
    raise exception 'Invalid activity cleanup confirmation' using errcode = '22023';
  end if;

  -- Timer transitions acquire the same employee row lock.
  perform 1 from public.ett_employees
    where owner_id = v_owner
    order by id
    for update;

  delete from public.ett_intervals where owner_id = v_owner;
  get diagnostics v_deleted = row_count;

  if v_deleted <> p_expected_count then
    -- Raising here rolls back the whole delete.
    raise exception 'Activity count changed' using errcode = 'PT409';
  end if;
  return v_deleted;
end;
$$;

revoke all on function public.ett_clear_activity(text, bigint, uuid) from public, anon;
grant execute on function public.ett_clear_activity(text, bigint, uuid) to authenticated;

commit;
