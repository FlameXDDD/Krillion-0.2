-- KRILLION 2.0 migration
-- Run once in Supabase SQL Editor. Uses the existing Supabase Auth users table.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 18),
  avatar text not null default '🦊',
  coins integer not null default 0 check (coins >= 0),
  total_points bigint not null default 0,
  equipped_sku text,
  created_at timestamptz not null default now()
);

create table if not exists public.answers (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  game_day date not null,
  game_no integer not null check (game_no between 1 and 10),
  prompt_no integer not null check (prompt_no between 1 and 12),
  prompt text not null,
  answer text not null,
  player_points integer not null,
  internet_points integer not null,
  total_points integer not null,
  submitted_at timestamptz not null default now(),
  unique(user_id, game_day, game_no, prompt_no)
);

create table if not exists public.inventory (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  sku text not null,
  item_name text not null,
  emoji text not null,
  kind text not null,
  purchased_at timestamptz not null default now(),
  unique(user_id, sku)
);

alter table public.profiles enable row level security;
alter table public.answers enable row level security;
alter table public.inventory enable row level security;

drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles for select to authenticated using (true);
drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
drop policy if exists "read answers" on public.answers;
create policy "read answers" on public.answers for select to authenticated using (true);
drop policy if exists "read own inventory" on public.inventory;
create policy "read own inventory" on public.inventory for select to authenticated using (auth.uid()=user_id);
drop policy if exists "equip own profile" on public.profiles;

create or replace function public.krillion_new_profile()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 insert into public.profiles(id,username,avatar)
 values(new.id,
   coalesce(nullif(new.raw_user_meta_data->>'username',''),'Player_'||substr(new.id::text,1,6)),
   coalesce(nullif(new.raw_user_meta_data->>'avatar',''),'🦊'))
 on conflict(id) do nothing;
 return new;
end; $$;

drop trigger if exists on_auth_user_created_krillion on auth.users;
create trigger on_auth_user_created_krillion after insert on auth.users
for each row execute procedure public.krillion_new_profile();

-- Heuristic estimate of broad internet/commonness (not a live web popularity lookup).
-- Score combines 70% player uniqueness and 30% niche wording estimate.

create or replace function public.submit_krillion_answer(
 p_game_day date, p_game_no integer, p_prompt_no integer, p_prompt text, p_answer text
) returns table(player_points integer,internet_points integer,total_points integer)
language plpgsql security definer set search_path=public
as $$
declare
 v_uid uuid := auth.uid();
 v_count integer;
 v_norm text := lower(regexp_replace(trim(p_answer),'\s+',' ','g'));
 v_words integer;
 v_chars integer;
 v_player integer;
 v_internet integer;
 v_total integer;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 if p_game_no not between 1 and 10 or p_prompt_no not between 1 and 12 then raise exception 'Invalid game or prompt'; end if;
 if length(trim(p_answer)) < 1 or length(p_answer)>100 then raise exception 'Answer must be 1–100 characters'; end if;

 select count(*) into v_count from public.answers
 where game_day=p_game_day and game_no=p_game_no and prompt_no=p_prompt_no
 and lower(regexp_replace(trim(answer),'\s+',' ','g'))=v_norm and user_id<>v_uid;

 v_player := greatest(5,100-(v_count*15));
 v_words := array_length(regexp_split_to_array(trim(p_answer),'\s+'),1);
 v_chars := length(trim(p_answer));
 v_internet := least(100,greatest(10,25 + least(v_chars,45) + greatest(0,v_words-1)*8));
 v_total := round(v_player*0.7 + v_internet*0.3);

 insert into public.answers(user_id,game_day,game_no,prompt_no,prompt,answer,player_points,internet_points,total_points)
 values(v_uid,p_game_day,p_game_no,p_prompt_no,p_prompt,trim(p_answer),v_player,v_internet,v_total);

 update public.profiles as prof
 set coins = prof.coins + v_total,
     total_points = prof.total_points + v_total
 where prof.id = v_uid;

 return query select v_player,v_internet,v_total;
end;
$$;

create or replace function public.buy_krillion_item(
 p_sku text,p_name text,p_emoji text,p_price integer,p_kind text
) returns void language plpgsql security definer set search_path=public
as $$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 if p_price<1 or p_price>10000 then raise exception 'Invalid item price'; end if;
 if exists(select 1 from public.inventory where user_id=v_uid and sku=p_sku) then raise exception 'Already owned'; end if;
 update public.profiles set coins=coins-p_price where id=v_uid and coins>=p_price;
 if not found then raise exception 'Not enough coins'; end if;
 insert into public.inventory(user_id,sku,item_name,emoji,kind) values(v_uid,p_sku,p_name,p_emoji,p_kind);
end; $$;

create or replace view public.daily_leaderboard as
select a.game_day,p.username,sum(a.total_points)::bigint as points
from public.answers a join public.profiles p on p.id=a.user_id
group by a.game_day,p.username;

grant select on public.profiles,public.answers,public.inventory,public.daily_leaderboard to authenticated;
grant update(username,avatar,equipped_sku) on public.profiles to authenticated;
grant execute on function public.submit_krillion_answer(date,integer,integer,text,text) to authenticated;
grant execute on function public.buy_krillion_item(text,text,text,integer,text) to authenticated;

-- Note: for production, restrict public profile fields, add rate limits/moderation,
-- and move the internet rarity estimate to a trusted server-side dataset/service.
