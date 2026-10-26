create extension if not exists pgcrypto;
create table if not exists public.products(id uuid primary key default gen_random_uuid(),name text not null,category text not null,price integer not null check(price>0),image_url text default '',stock integer not null default 0 check(stock>=0),active boolean not null default false,created_at timestamptz not null default now());
create table if not exists public.addresses(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,full_name text not null,phone text not null,street text not null,city text not null,postal_code text not null,created_at timestamptz default now());
create table if not exists public.orders(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id),address_id uuid not null references public.addresses(id),subtotal integer not null,shipping integer not null,total integer not null,status text not null default 'PENDING' check(status in ('PENDING','PAID','EXPIRED','FAILED','CANCELLED')),external_id text unique not null,invoice_id text,invoice_url text,created_at timestamptz not null default now());
create table if not exists public.order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,product_id uuid not null references public.products(id),quantity integer not null check(quantity>0),unit_price integer not null);
alter table public.products enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
create policy "public active products" on public.products for select using (active=true);
create policy "own addresses select" on public.addresses for select to authenticated using (user_id=(select auth.uid()));
create policy "own addresses insert" on public.addresses for insert to authenticated with check(user_id=(select auth.uid()));
create policy "own addresses update" on public.addresses for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy "own orders select" on public.orders for select to authenticated using(user_id=(select auth.uid()));
create policy "own order items select" on public.order_items for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and o.user_id=(select auth.uid())));
-- Orders, order_items and payment status are written by server-only service role, never by mobile client.
