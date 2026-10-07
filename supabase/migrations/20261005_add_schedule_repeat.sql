alter table public.pet_schedules
add column if not exists repeat text
not null
default 'Does not repeat';