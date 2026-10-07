alter table public.pets
  add column if not exists fun_fact text not null default '',
  add column if not exists health_note text not null default '';

-- Preserve existing notes as health notes when introducing the separate fields.
update public.pets
set health_note = care_notes
where health_note = ''
  and care_notes is not null
  and care_notes <> '';

notify pgrst, 'reload schema';
