-- ═══════════════════════════════════════════════════════════
--  STOKKU — Skema Database Supabase
--  Jalankan seluruh isi file ini di Supabase → SQL Editor
--  Prinsip: stok TIDAK PERNAH disimpan sebagai angka yang diedit.
--  Stok = hasil akumulasi dari tabel transaksi (ledger system).
-- ═══════════════════════════════════════════════════════════

-- ─── 1. GUDANG ──────────────────────────────────────────────
create table if not exists warehouses (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  address     text,
  created_at  timestamptz not null default now()
);
create index if not exists idx_wh_owner on warehouses(owner_id);

-- ─── 2. BARANG ──────────────────────────────────────────────
create table if not exists products (
  id           uuid primary key default gen_random_uuid(),
  warehouse_id uuid not null references warehouses(id) on delete cascade,
  sku          text not null,
  name         text not null,
  unit         text not null default 'pcs',
  min_stock    numeric(14,2) not null default 0,
  price        numeric(14,2) not null default 0,
  cost         numeric(14,2) not null default 0,
  category     text,
  active       boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (warehouse_id, sku)          -- kode unik per gudang
);
create index if not exists idx_prod_wh   on products(warehouse_id);
create index if not exists idx_prod_sku  on products(warehouse_id, sku);
create index if not exists idx_prod_name on products using gin (to_tsvector('simple', name));

-- ─── 3. TRANSAKSI (header) ──────────────────────────────────
create table if not exists transactions (
  id           uuid primary key default gen_random_uuid(),
  warehouse_id uuid not null references warehouses(id) on delete cascade,
  user_id      uuid not null references auth.users(id),
  type         text not null check (type in ('in','out','adjust')),
  ref_no       text,
  note         text,
  occurred_at  timestamptz not null default now(),
  created_at   timestamptz not null default now()
);
create index if not exists idx_trx_wh   on transactions(warehouse_id, occurred_at desc);
create index if not exists idx_trx_type on transactions(warehouse_id, type);

-- ─── 4. DETAIL TRANSAKSI ────────────────────────────────────
create table if not exists transaction_items (
  id             uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references transactions(id) on delete cascade,
  product_id     uuid not null references products(id) on delete cascade,
  qty            numeric(14,2) not null check (qty >= 0),
  price          numeric(14,2) not null default 0
);
create index if not exists idx_ti_trx  on transaction_items(transaction_id);
create index if not exists idx_ti_prod on transaction_items(product_id);

-- ═══════════════════════════════════════════════════════════
--  VIEW: STOK SAAT INI
--  'in'     → tambah
--  'out'    → kurang
--  'adjust' → set absolut (stok opname / stok awal)
--  Cara hitung: ambil qty dari adjust TERAKHIR sebagai basis,
--  lalu tambah/kurangi semua in/out SETELAH tanggal itu.
-- ═══════════════════════════════════════════════════════════
create or replace view v_stock as
with last_adjust as (
  select distinct on (ti.product_id)
         ti.product_id, ti.qty as base_qty, t.occurred_at as base_at
  from   transaction_items ti
  join   transactions t on t.id = ti.transaction_id
  where  t.type = 'adjust'
  order  by ti.product_id, t.occurred_at desc, t.created_at desc
),
movement as (
  select ti.product_id,
         sum(case when t.type = 'in'  then ti.qty
                  when t.type = 'out' then -ti.qty
                  else 0 end) as delta
  from   transaction_items ti
  join   transactions t on t.id = ti.transaction_id
  left   join last_adjust la on la.product_id = ti.product_id
  where  t.type in ('in','out')
    and  (la.base_at is null or t.occurred_at > la.base_at)
  group  by ti.product_id
)
select p.id                                as product_id,
       p.warehouse_id,
       p.sku, p.name, p.unit, p.min_stock, p.price, p.cost, p.category, p.active,
       coalesce(la.base_qty,0) + coalesce(m.delta,0)              as stock,
       (coalesce(la.base_qty,0) + coalesce(m.delta,0)) * p.price  as stock_value,
       case
         when coalesce(la.base_qty,0) + coalesce(m.delta,0) <= 0 then 'habis'
         when coalesce(la.base_qty,0) + coalesce(m.delta,0) <= p.min_stock then 'menipis'
         else 'aman'
       end                                                        as status
from   products p
left   join last_adjust la on la.product_id = p.id
left   join movement    m  on m.product_id  = p.id
where  p.active;

-- ═══════════════════════════════════════════════════════════
--  RPC: SIMPAN TRANSAKSI SECARA ATOMIC
--  Header + semua detail masuk dalam SATU transaksi database.
--  Kalau ada satu item gagal, semuanya dibatalkan (rollback).
-- ═══════════════════════════════════════════════════════════
create or replace function commit_transaction(
  p_warehouse uuid,
  p_type      text,
  p_note      text,
  p_items     jsonb          -- [{"product_id":"...","qty":2,"price":5000}, ...]
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trx  uuid;
  v_item jsonb;
  v_wh   uuid;
  v_av   numeric;
begin
  -- pastikan gudang milik user yang sedang login
  select id into v_wh from warehouses
   where id = p_warehouse and owner_id = auth.uid();
  if v_wh is null then
    raise exception 'Gudang tidak ditemukan atau bukan milik Anda';
  end if;

  if p_type not in ('in','out','adjust') then
    raise exception 'Jenis transaksi tidak dikenal: %', p_type;
  end if;

  -- validasi stok cukup untuk barang keluar
  if p_type = 'out' then
    for v_item in select * from jsonb_array_elements(p_items) loop
      select stock into v_av from v_stock
       where product_id = (v_item->>'product_id')::uuid;
      if coalesce(v_av,0) < (v_item->>'qty')::numeric then
        raise exception 'Stok tidak cukup untuk salah satu barang (tersedia %)', coalesce(v_av,0);
      end if;
    end loop;
  end if;

  insert into transactions (warehouse_id, user_id, type, note)
  values (p_warehouse, auth.uid(), p_type, p_note)
  returning id into v_trx;

  insert into transaction_items (transaction_id, product_id, qty, price)
  select v_trx,
         (i->>'product_id')::uuid,
         (i->>'qty')::numeric,
         coalesce((i->>'price')::numeric, 0)
  from   jsonb_array_elements(p_items) i;

  return v_trx;
end;
$$;

-- ═══════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY
--  Tanpa ini, semua orang bisa baca data semua orang.
-- ═══════════════════════════════════════════════════════════
alter table warehouses        enable row level security;
alter table products          enable row level security;
alter table transactions      enable row level security;
alter table transaction_items enable row level security;

drop policy if exists wh_all on warehouses;
create policy wh_all on warehouses
  for all using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists prod_all on products;
create policy prod_all on products
  for all using (exists (
    select 1 from warehouses w
     where w.id = products.warehouse_id and w.owner_id = auth.uid()))
  with check (exists (
    select 1 from warehouses w
     where w.id = products.warehouse_id and w.owner_id = auth.uid()));

drop policy if exists trx_all on transactions;
create policy trx_all on transactions
  for all using (exists (
    select 1 from warehouses w
     where w.id = transactions.warehouse_id and w.owner_id = auth.uid()))
  with check (exists (
    select 1 from warehouses w
     where w.id = transactions.warehouse_id and w.owner_id = auth.uid()));

drop policy if exists ti_all on transaction_items;
create policy ti_all on transaction_items
  for all using (exists (
    select 1 from transactions t
    join warehouses w on w.id = t.warehouse_id
     where t.id = transaction_items.transaction_id and w.owner_id = auth.uid()))
  with check (exists (
    select 1 from transactions t
    join warehouses w on w.id = t.warehouse_id
     where t.id = transaction_items.transaction_id and w.owner_id = auth.uid()));

-- ═══════════════════════════════════════════════════════════
--  TRIGGER: buat gudang otomatis saat user baru mendaftar
-- ═══════════════════════════════════════════════════════════
create or replace function on_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into warehouses (owner_id, name) values (new.id, 'Gudang Utama');
  return new;
end;
$$;

drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user
  after insert on auth.users
  for each row execute function on_new_user();

-- ═══════════════════════════════════════════════════════════
--  VIEW LAPORAN: barang paling laku 30 hari terakhir
-- ═══════════════════════════════════════════════════════════
create or replace view v_top_moving as
select p.warehouse_id, p.id as product_id, p.sku, p.name, p.unit,
       sum(ti.qty)                as total_out,
       sum(ti.qty * ti.price)     as total_value
from   transaction_items ti
join   transactions t on t.id = ti.transaction_id
join   products p     on p.id = ti.product_id
where  t.type = 'out'
  and  t.occurred_at >= now() - interval '30 days'
group  by p.warehouse_id, p.id, p.sku, p.name, p.unit
order  by total_out desc;
