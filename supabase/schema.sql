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
  created_at timestamptz not null default now()
);

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
