alter table public.pet_schedules
add column if not exists is_done boolean not null default false;

notify pgrst, 'reload schema';
