-- ととのね(habit_flow) 同期用スキーマ。Supabase の SQL Editor で1回だけ実行してください。

create table if not exists public.tasks (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  icon_index int not null default 0,
  default_minutes int not null default 10,
  last_memo text not null default '',
  total_count int not null default 0,
  current_streak int not null default 0,
  best_streak int not null default 0,
  last_completed_date timestamptz,
  created_at timestamptz not null,
  cumulative_minutes int not null default 0,
  mode_index int not null default 0,
  track_fitness boolean not null default false,
  cumulative_distance_meters double precision not null default 0,
  cumulative_steps int not null default 0,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (user_id, id)
);

create table if not exists public.completion_logs (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  task_id text not null,
  task_name text not null,
  icon_index int not null default 0,
  memo text not null default '',
  minutes int not null default 0,
  completed_at timestamptz not null,
  distance_meters double precision,
  steps int,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  primary key (user_id, id)
);

alter table public.tasks enable row level security;
alter table public.completion_logs enable row level security;

drop policy if exists "own tasks" on public.tasks;
create policy "own tasks" on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own logs" on public.completion_logs;
create policy "own logs" on public.completion_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
