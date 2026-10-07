alter table public.pets
add column if not exists care_notes text not null default '';
