-- SQL Schema Definition for Smart Bus Booking & Fleet Management System (SBMS)
-- Execute this script in your Supabase SQL Editor.

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Create User Profiles
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text,
    full_name text not null,
    phone_number text not null,
    role text not null default 'passenger',
    wallet_balance decimal(10, 2) not null default 0.00,
    favorite_routes jsonb not null default '[]'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Profiles
alter table public.profiles enable row level security;

create policy "Allow public read access to profiles" on public.profiles
    for select using (true);

create policy "Allow users to update their own profile" on public.profiles
    for update using (auth.uid() = id);

-- 2. Create Routes Table
create table public.routes (
    id uuid default uuid_generate_v4() primary key,
    departure_city text not null,
    arrival_city text not null,
    distance_km decimal(6, 2) not null,
    base_price decimal(8, 2) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Routes
alter table public.routes enable row level security;

create policy "Allow read access to routes" on public.routes
    for select using (true);

-- 3. Create Trips Table (Buses scheduled on Routes)
create table public.trips (
    id uuid default uuid_generate_v4() primary key,
    route_id uuid references public.routes(id) on delete cascade not null,
    departure_time timestamp with time zone not null,
    arrival_time timestamp with time zone not null,
    bus_number text not null,
    total_seats integer not null default 40,
    available_seats integer not null default 40,
    occupied_seats text[] not null default '{}'::text[], -- e.g., {'A1', 'A2'}
    price decimal(8, 2) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Trips
alter table public.trips enable row level security;

create policy "Allow read access to trips" on public.trips
    for select using (true);

-- 4. Create Bookings Table
create table public.bookings (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    trip_id uuid references public.trips(id) on delete cascade not null,
    seats text[] not null, -- Selected seats, e.g., {'B1', 'B2'}
    total_price decimal(8, 2) not null,
    payment_method text not null, -- 'wallet', 'evc_plus', 'zaad', 'sahal'
    payment_status text not null default 'pending', -- 'pending', 'completed', 'failed'
    ticket_qr_code text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Bookings
alter table public.bookings enable row level security;

create policy "Allow users to read their own bookings" on public.bookings
    for select using (auth.uid() = user_id);

create policy "Allow users to create their own bookings" on public.bookings
    for insert with check (auth.uid() = user_id);

-- 5. Create Wallet Transactions Table
create table public.wallet_transactions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    amount decimal(10, 2) not null,
    type text not null, -- 'deposit', 'booking_payment'
    status text not null default 'completed',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Wallet Transactions
alter table public.wallet_transactions enable row level security;

create policy "Allow users to view their own transactions" on public.wallet_transactions
    for select using (auth.uid() = user_id);

-- 6. Create Feedback Table
create table public.feedback (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    category text not null, -- 'app_experience', 'bus_quality', 'conductor_driver', 'delay'
    rating integer not null check (rating >= 1 and rating <= 5),
    comment text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Feedback
alter table public.feedback enable row level security;

create policy "Allow users to insert their own feedback" on public.feedback
    for insert with check (auth.uid() = user_id);

-- 7. Additional RLS Policies
-- Allow authenticated users to update occupied/available seats on trips during booking
create policy "Allow authenticated users to update trips" on public.trips
    for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 8. Automation Triggers for Profiles
-- Trigger to automatically create a profile record when a new auth user registers
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, full_name, phone_number, role, wallet_balance, favorite_routes)
    values (
        new.id,
        coalesce(new.email, ''),
        coalesce(new.raw_user_meta_data->>'full_name', 'Somali Commuter'),
        coalesce(new.raw_user_meta_data->>'phone_number', ''),
        coalesce(new.raw_user_meta_data->>'role', 'passenger'),
        100.00, -- Default welcome wallet balance (100 USD)
        '[]'::jsonb
    );
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Trigger to maintain updated_at column automatically
create or replace function public.handle_update_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists on_profile_updated on public.profiles;
create trigger on_profile_updated
    before update on public.profiles
    for each row execute procedure public.handle_update_timestamp();

-- 9. Realtime Publication Configurations
-- Safely add tables to Supabase's default realtime publication
do $$
begin
    alter publication supabase_realtime add table public.trips;
exception when others then
    -- Ignore error if table is already registered in the publication
end $$;

do $$
begin
    alter publication supabase_realtime add table public.bookings;
exception when others then
    -- Ignore error if table is already registered in the publication
end $$;

-- 10. Seed Data for Testing and Verification
-- Seed default routes
insert into public.routes (id, departure_city, arrival_city, distance_km, base_price)
values 
    ('e6c86a1b-6406-4dfc-a496-e1376f9d2d0a', 'Mogadishu', 'Garowe', 1000.00, 25.00),
    ('a7f6c3d8-1111-2222-3333-444455556666', 'Hargeisa', 'Burao', 180.00, 12.00),
    ('b9d8e7f6-7777-8888-9999-0000aaaabbbb', 'Mogadishu', 'Kismayo', 500.00, 18.00)
on conflict (id) do nothing;

-- Seed scheduled trips (associated with routes above)
insert into public.trips (id, route_id, departure_time, arrival_time, bus_number, total_seats, available_seats, occupied_seats, price)
values 
    ('d9b8a7c6-2222-3333-4444-555566667777', 'e6c86a1b-6406-4dfc-a496-e1376f9d2d0a', now() + interval '4 hours', now() + interval '12 hours', 'MOG-GRW-08', 40, 36, array['A1', 'A2', 'B3', 'B4'], 25.00),
    ('c8b7a6d5-4444-5555-6666-777788889999', 'a7f6c3d8-1111-2222-3333-444455556666', now() + interval '6 hours', now() + interval '10 hours', 'HAR-BUR-02', 40, 31, array['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'C1', 'C2', 'D1'], 12.00),
    ('b7a6d5c4-6666-7777-8888-99990000aaaa', 'b9d8e7f6-7777-8888-9999-0000aaaabbbb', now() + interval '26 hours', now() + interval '32 hours', 'MOG-KIS-05', 40, 39, array['A1'], 18.00)
on conflict (id) do nothing;
