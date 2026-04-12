create extension if not exists pgcrypto;

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  student text not null,
  wa text not null,
  level text not null,
  matiere text not null,
  enseignant text not null,
  montant integer not null check (montant >= 0),
  type text not null check (type in ('avance', 'total')),
  date date null,
  duplicate_key text,
  created_at timestamptz not null default now()
);

alter table public.payments add column if not exists duplicate_key text;

update public.payments
set duplicate_key = lower(trim(student)) || '|' ||
  lower(trim(wa)) || '|' ||
  lower(trim(level)) || '|' ||
  lower(trim(matiere)) || '|' ||
  lower(trim(enseignant)) || '|' ||
  montant::text || '|' ||
  lower(trim(type)) || '|' ||
  coalesce(date::text, 'no-date')
where duplicate_key is null;

delete from public.payments p
using (
  select id
  from (
    select id,
      row_number() over (partition by duplicate_key order by created_at asc, id asc) as rn
    from public.payments
  ) ranked
  where ranked.rn > 1
) d
where p.id = d.id;

create unique index if not exists payments_duplicate_key_idx
on public.payments (duplicate_key);

alter table public.payments enable row level security;

drop policy if exists "public can insert payments" on public.payments;
create policy "public can insert payments"
on public.payments
for insert
to anon, authenticated
with check (true);

drop policy if exists "admin can read payments" on public.payments;
create policy "admin can read payments"
on public.payments
for select
to authenticated
using (auth.jwt() ->> 'email' = 'nkilitech@gmail.com');

drop policy if exists "admin can delete payments" on public.payments;
create policy "admin can delete payments"
on public.payments
for delete
to authenticated
using (auth.jwt() ->> 'email' = 'nkilitech@gmail.com');
