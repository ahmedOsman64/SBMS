-- SQL Schema Extension for Driver, Conductor, and Fleet Management modules
-- Execute this script in your Supabase SQL Editor.

-- 1. Create Buses Table
create table if not exists public.buses (
    id uuid default uuid_generate_v4() primary key,
    bus_number text not null unique,
    model text,
    capacity integer not null default 40,
    status text not null default 'active', -- 'active', 'maintenance', 'out_of_service'
    fuel_level decimal(5, 2) not null default 100.00, -- percentage
    latitude double precision default 2.0469, -- default Mogadishu coordinates
    longitude double precision default 45.3182,
    speed decimal(5, 2) default 0.00,
    passenger_count integer default 0,
    last_gps_update timestamp with time zone default timezone('utc'::text, now()),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Buses
alter table public.buses enable row level security;

create policy "Allow read access to buses for authenticated users" on public.buses
    for select using (auth.role() = 'authenticated');

create policy "Allow update access to buses for authenticated users" on public.buses
    for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 2. Create Attendance Table
create table if not exists public.attendance (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    date date not null default current_date,
    check_in timestamp with time zone default timezone('utc'::text, now()),
    check_out timestamp with time zone,
    status text not null default 'present', -- 'present', 'late', 'absent'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique (user_id, date)
);

-- Enable RLS on Attendance
alter table public.attendance enable row level security;

create policy "Allow users to read their own attendance" on public.attendance
    for select using (auth.uid() = user_id);

create policy "Allow users to record attendance" on public.attendance
    for insert with check (auth.uid() = user_id);

create policy "Allow users to update check-out attendance" on public.attendance
    for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 3. Create Luggage Table
create table if not exists public.luggage (
    id uuid default uuid_generate_v4() primary key,
    booking_id uuid references public.bookings(id) on delete cascade not null,
    trip_id uuid references public.trips(id) on delete cascade not null,
    tag_number text not null unique,
    weight_kg decimal(6, 2) not null,
    pieces integer not null default 1,
    status text not null default 'loaded', -- 'loaded', 'delivered', 'claimed', 'lost'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Luggage
alter table public.luggage enable row level security;

create policy "Allow read access to luggage" on public.luggage
    for select using (true);

create policy "Allow write access to luggage for conductors" on public.luggage
    for insert with check (auth.role() = 'authenticated');

create policy "Allow update access to luggage for conductors" on public.luggage
    for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 4. Create Fuel Reports Table
create table if not exists public.fuel_reports (
    id uuid default uuid_generate_v4() primary key,
    bus_number text not null,
    driver_id uuid references public.profiles(id) on delete cascade not null,
    amount_liters decimal(8, 2) not null,
    cost decimal(10, 2) not null,
    odometer_reading decimal(10, 2) not null,
    receipt_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Fuel Reports
alter table public.fuel_reports enable row level security;

create policy "Allow read access to fuel reports for staff" on public.fuel_reports
    for select using (auth.role() = 'authenticated');

create policy "Allow insert access to fuel reports for drivers" on public.fuel_reports
    for insert with check (auth.uid() = driver_id);

-- 5. Create Incident Reports Table
create table if not exists public.incident_reports (
    id uuid default uuid_generate_v4() primary key,
    trip_id uuid references public.trips(id) on delete cascade,
    driver_id uuid references public.profiles(id) on delete cascade not null,
    severity text not null, -- 'low', 'medium', 'high', 'critical'
    description text not null,
    latitude double precision,
    longitude double precision,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Incident Reports
alter table public.incident_reports enable row level security;

create policy "Allow read access to incidents" on public.incident_reports
    for select using (auth.role() = 'authenticated');

create policy "Allow drivers to insert incident reports" on public.incident_reports
    for insert with check (auth.uid() = driver_id);

-- 6. Create Maintenance Records Table
create table if not exists public.maintenance_records (
    id uuid default uuid_generate_v4() primary key,
    bus_number text not null,
    description text not null,
    cost decimal(10, 2) not null default 0.00,
    status text not null default 'pending', -- 'pending', 'in_progress', 'completed'
    scheduled_date date not null default current_date,
    completion_date date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Maintenance Records
alter table public.maintenance_records enable row level security;

create policy "Allow read access to maintenance records" on public.maintenance_records
    for select using (auth.role() = 'authenticated');

create policy "Allow write access to maintenance records for admins" on public.maintenance_records
    for insert with check (auth.role() = 'authenticated');

create policy "Allow update access to maintenance records for admins" on public.maintenance_records
    for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 7. Add columns to public.trips for Bus, Driver, and Conductor assignment
alter table public.trips add column if not exists driver_id uuid references public.profiles(id) on delete set null;
alter table public.trips add column if not exists conductor_id uuid references public.profiles(id) on delete set null;
alter table public.trips add column if not exists status text not null default 'scheduled'; -- 'scheduled', 'en_route', 'completed', 'delayed', 'cancelled'
alter table public.trips add column if not exists current_latitude double precision default 2.0469;
alter table public.trips add column if not exists current_longitude double precision default 45.3182;
alter table public.trips add column if not exists passenger_count integer default 0;

-- 8. Add table updates to Supabase Realtime publication
do $$
begin
    alter publication supabase_realtime add table public.buses;
exception when others then
end $$;

do $$
begin
    alter publication supabase_realtime add table public.luggage;
exception when others then
end $$;

do $$
begin
    alter publication supabase_realtime add table public.attendance;
exception when others then
end $$;

do $$
begin
    alter publication supabase_realtime add table public.incident_reports;
exception when others then
end $$;

-- 9. Seed some test buses
insert into public.buses (bus_number, model, capacity, status, fuel_level, latitude, longitude)
values 
    ('MOG-GRW-08', 'Toyota Coaster', 40, 'active', 85.00, 2.0469, 45.3182),
    ('HAR-BUR-02', 'Hyundai County', 40, 'active', 92.50, 9.5627, 44.0770),
    ('MOG-KIS-05', 'Toyota Coaster', 40, 'maintenance', 45.00, 2.0469, 45.3182)
on conflict (bus_number) do nothing;
