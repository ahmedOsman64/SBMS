-- SQL Schema Extension for Somali Smart Bus (SBMS) Enterprise Admin System
-- Execute this script in your Supabase SQL Editor.

-- 1. Create Companies Table
create table if not exists public.companies (
    id uuid default uuid_generate_v4() primary key,
    name text not null unique,
    legal_name text,
    registration_number text unique,
    contact_email text,
    contact_phone text,
    address text,
    status text not null default 'active', -- 'active', 'suspended', 'inactive'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Companies
alter table public.companies enable row level security;

create policy "Allow read access to companies for authenticated users" on public.companies
    for select using (auth.role() = 'authenticated');

create policy "Allow write access to companies for admins" on public.companies
    for all using (auth.role() = 'authenticated');

-- 2. Create Branches Table
create table if not exists public.branches (
    id uuid default uuid_generate_v4() primary key,
    company_id uuid references public.companies(id) on delete cascade not null,
    name text not null,
    code text unique not null,
    city text not null,
    address text,
    contact_phone text,
    manager_name text,
    status text not null default 'active', -- 'active', 'inactive'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Branches
alter table public.branches enable row level security;

create policy "Allow read access to branches for authenticated users" on public.branches
    for select using (auth.role() = 'authenticated');

create policy "Allow write access to branches for admins" on public.branches
    for all using (auth.role() = 'authenticated');

-- 3. Create Coupons / Promotions Table
create table if not exists public.coupons (
    id uuid default uuid_generate_v4() primary key,
    code text not null unique,
    discount_percent decimal(5, 2) not null check (discount_percent >= 0.00 and discount_percent <= 100.00),
    max_discount_usd decimal(8, 2),
    valid_from timestamp with time zone not null,
    valid_to timestamp with time zone not null,
    usage_limit integer,
    used_count integer default 0,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Coupons
alter table public.coupons enable row level security;

create policy "Allow read access to coupons for all authenticated users" on public.coupons
    for select using (auth.role() = 'authenticated');

create policy "Allow write access to coupons for admins" on public.coupons
    for all using (auth.role() = 'authenticated');

-- 4. Create Audit Logs Table
create table if not exists public.audit_logs (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete set null,
    user_email text,
    action text not null, -- 'CREATE_BOOKING', 'UPDATE_TRIP_STATUS', 'ASSIGN_STAFF', etc.
    table_name text,
    record_id text,
    ip_address text,
    details text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Audit Logs
alter table public.audit_logs enable row level security;

create policy "Allow read access to audit logs for admins only" on public.audit_logs
    for select using (auth.role() = 'authenticated');

create policy "Allow insert access to audit logs for authenticated users" on public.audit_logs
    for insert with check (auth.role() = 'authenticated');

-- 5. Create Support Tickets Table
create table if not exists public.support_tickets (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    subject text not null,
    description text not null,
    category text not null, -- 'booking', 'payment', 'app_bug', 'driver_behavior', 'other'
    priority text not null default 'medium', -- 'low', 'medium', 'high', 'critical'
    status text not null default 'open', -- 'open', 'in_progress', 'resolved', 'closed'
    assigned_to uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Support Tickets
alter table public.support_tickets enable row level security;

create policy "Allow users to read/write their own support tickets" on public.support_tickets
    for all using (auth.uid() = user_id or auth.role() = 'authenticated');

-- 6. Create AI Insights Table (Demand Predictions, Dynamic Pricing, Fraud)
create table if not exists public.ai_insights (
    id uuid default uuid_generate_v4() primary key,
    type text not null, -- 'DEMAND_PREDICTION', 'DYNAMIC_PRICING', 'FRAUD_ALERT', 'RECOMMENDATION'
    target_id text, -- references route_id, trip_id, user_id depending on type
    metric_name text not null, -- 'predicted_passenger_count', 'recommended_fare', 'fraud_risk_score', etc.
    metric_value decimal(12, 4) not null,
    confidence_score decimal(5, 2) check (confidence_score >= 0.00 and confidence_score <= 100.00),
    insight_details jsonb not null default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on AI Insights
alter table public.ai_insights enable row level security;

create policy "Allow read access to AI insights for admins" on public.ai_insights
    for select using (auth.role() = 'authenticated');

-- 7. Add columns to profiles for Admin Roles and Permissions
alter table public.profiles add column if not exists permissions text[] default '{}'::text[];

-- 8. Add table updates to Supabase Realtime publication
do $$
begin
    alter publication supabase_realtime add table public.companies;
exception when others then
end $$;

do $$
begin
    alter publication supabase_realtime add table public.support_tickets;
exception when others then
end $$;

do $$
begin
    alter publication supabase_realtime add table public.ai_insights;
exception when others then
end $$;

-- 9. Seed some test Companies and Branches
insert into public.companies (name, legal_name, registration_number, contact_email, contact_phone, address)
values 
    ('Soomaal Transit Corp', 'Soomaal Transit Corporation Ltd', 'STC-100293', 'info@soomaaltransit.so', '+252 61 2221122', 'Maka Al Mukarama Rd, Mogadishu'),
    ('Puntland Express', 'Puntland Bus Service Express', 'PEX-998811', 'contact@puntexpress.so', '+252 90 7773344', 'Garowe Bus Depot, Garowe')
on conflict (name) do nothing;

insert into public.branches (company_id, name, code, city, address, manager_name)
values 
    ((select id from public.companies where name = 'Soomaal Transit Corp' limit 1), 'Mogadishu Central Station', 'MOG-CEN', 'Mogadishu', 'Hodan District, Mogadishu', 'Dahir Gure'),
    ((select id from public.companies where name = 'Puntland Express' limit 1), 'Garowe Main Hub', 'GRW-HUB', 'Garowe', 'Garowe center, Garowe', 'Faduma Elmi')
on conflict (code) do nothing;
