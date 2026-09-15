-- ===========================================================
-- Rotation — database setup
-- Paste this whole file into Supabase > SQL Editor and press Run.
-- You only ever need to do this once.
-- ===========================================================

-- Each person who signs up gets one row here.
create table profiles (
  id         uuid primary key references auth.users on delete cascade,
  username   text unique not null,
  created_at timestamptz default now()
);

-- One row per shared playlist.
create table posts (
  id          bigserial primary key,
  user_id     uuid not null references profiles(id) on delete cascade,
  playlist_id text not null,
  caption     text,
  created_at  timestamptz default now()
);

-- One row per like. The two-column key means you can't like twice.
create table likes (
  post_id bigint not null references posts(id) on delete cascade,
  user_id uuid   not null references profiles(id) on delete cascade,
  primary key (post_id, user_id)
);

-- One row per rating. Same trick: one rating per person per post.
create table ratings (
  post_id bigint not null references posts(id) on delete cascade,
  user_id uuid   not null references profiles(id) on delete cascade,
  score   int    not null check (score between 1 and 5),
  primary key (post_id, user_id)
);

create table comments (
  id         bigserial primary key,
  post_id    bigint not null references posts(id) on delete cascade,
  user_id    uuid   not null references profiles(id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 500),
  created_at timestamptz default now()
);

-- ===========================================================
-- Security. Without this, anyone with your public key could
-- delete everything. Do not skip it.
-- ===========================================================

alter table profiles enable row level security;
alter table posts    enable row level security;
alter table likes    enable row level security;
alter table ratings  enable row level security;
alter table comments enable row level security;

-- Signed-in people can read everything.
create policy "read profiles" on profiles for select to authenticated using (true);
create policy "read posts"    on posts    for select to authenticated using (true);
create policy "read likes"    on likes    for select to authenticated using (true);
create policy "read ratings"  on ratings  for select to authenticated using (true);
create policy "read comments" on comments for select to authenticated using (true);

-- But you can only write rows that belong to you.
create policy "claim profile"  on profiles for insert to authenticated with check (auth.uid() = id);
create policy "edit profile"   on profiles for update to authenticated using (auth.uid() = id);

create policy "write posts"    on posts    for insert to authenticated with check (auth.uid() = user_id);
create policy "delete posts"   on posts    for delete to authenticated using (auth.uid() = user_id);

create policy "write likes"    on likes    for insert to authenticated with check (auth.uid() = user_id);
create policy "delete likes"   on likes    for delete to authenticated using (auth.uid() = user_id);

create policy "write ratings"  on ratings  for insert to authenticated with check (auth.uid() = user_id);
create policy "update ratings" on ratings  for update to authenticated using (auth.uid() = user_id);

create policy "write comments"  on comments for insert to authenticated with check (auth.uid() = user_id);
create policy "delete comments" on comments for delete to authenticated using (auth.uid() = user_id);
