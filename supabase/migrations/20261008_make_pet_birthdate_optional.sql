alter table public.pets
alter column birthdate drop not null;

notify pgrst, 'reload schema';
