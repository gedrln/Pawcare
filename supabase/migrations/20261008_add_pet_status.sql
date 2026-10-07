alter table public.pets
add column if not exists pet_status text not null default 'Alive';

notify pgrst, 'reload schema';
