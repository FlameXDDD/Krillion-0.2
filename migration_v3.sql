-- KRILLION 3.0 additive migration
-- Run once in Supabase SQL Editor AFTER migration_v2.sql.
-- Preserves existing profiles, answers, coins, points and inventory.

alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists avatar_bg text not null default '#293249',
  add column if not exists equipped_theme text not null default 'theme_default';

create table if not exists public.krillion_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint krillion_no_self_follow check (follower_id <> following_id)
);

alter table public.krillion_follows enable row level security;
drop policy if exists "follows readable by signed in" on public.krillion_follows;
create policy "follows readable by signed in" on public.krillion_follows
  for select to authenticated using (true);
drop policy if exists "follow as yourself" on public.krillion_follows;
create policy "follow as yourself" on public.krillion_follows
  for insert to authenticated with check (auth.uid() = follower_id);
drop policy if exists "unfollow as yourself" on public.krillion_follows;
create policy "unfollow as yourself" on public.krillion_follows
  for delete to authenticated using (auth.uid() = follower_id);

grant select, insert, delete on public.krillion_follows to authenticated;
grant update(username, avatar, avatar_url, avatar_bg, equipped_sku, equipped_theme) on public.profiles to authenticated;

-- Public avatar images; users may only upload/manage files inside their own UUID folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 2097152,
  allowed_mime_types = array['image/png','image/jpeg','image/webp'];

drop policy if exists "Avatar images are public" on storage.objects;
create policy "Avatar images are public" on storage.objects
  for select using (bucket_id = 'avatars');
drop policy if exists "Users upload own avatar" on storage.objects;
create policy "Users upload own avatar" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "Users update own avatar" on storage.objects;
create policy "Users update own avatar" on storage.objects
  for update to authenticated using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
drop policy if exists "Users delete own avatar" on storage.objects;
create policy "Users delete own avatar" on storage.objects
  for delete to authenticated using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Server-authoritative theme shop. Existing coins are retained.
create or replace function public.buy_krillion_theme(p_sku text)
returns void language plpgsql security definer set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_name text;
  v_emoji text := '🎨';
  v_price integer;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;
  select name, price into v_name, v_price from (values
    ('theme_crimson','Crimson Rush',350),
    ('theme_ocean','Deep Ocean',350),
    ('theme_void','Void Protocol',500),
    ('theme_nebula','Nebula Drift',650),
    ('theme_cursed','Cursed Pulse',650)
  ) as t(sku,name,price) where t.sku = p_sku;
  if v_name is null then raise exception 'Unknown theme'; end if;
  if exists(select 1 from public.inventory where user_id=v_uid and sku=p_sku) then
    raise exception 'Theme already owned';
  end if;
  update public.profiles set coins=coins-v_price
    where id=v_uid and coins>=v_price;
  if not found then raise exception 'Not enough coins'; end if;
  insert into public.inventory(user_id,sku,item_name,emoji,kind)
    values(v_uid,p_sku,v_name,v_emoji,'theme');
end;
$$;
grant execute on function public.buy_krillion_theme(text) to authenticated;

-- Improved transparent niche-specificity estimate.
-- It is NOT a live internet search. More descriptive, distinctive answers score higher.
-- Combined score: 70% niche score + 30% player rarity.
create or replace function public.submit_krillion_answer(
  p_game_day date, p_game_no integer, p_prompt_no integer, p_prompt text, p_answer text
) returns table(player_points integer,internet_points integer,total_points integer)
language plpgsql security definer set search_path=public
as $$
declare
  v_uid uuid := auth.uid();
  v_count integer;
  v_norm text := lower(regexp_replace(trim(p_answer),'\s+',' ','g'));
  v_words text[];
  v_word_count integer;
  v_unique_words integer;
  v_content_words integer;
  v_avg_word_len numeric;
  v_specificity integer;
  v_player integer;
  v_internet integer;
  v_total integer;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;
  if p_game_no not between 1 and 10 or p_prompt_no not between 1 and 12 then
    raise exception 'Invalid game or prompt';
  end if;
  if length(trim(p_answer)) < 1 or length(p_answer) > 100 then
    raise exception 'Answer must be 1–100 characters';
  end if;
  if p_game_day < current_date - 1 or p_game_day > current_date then
    raise exception 'Invalid game date';
  end if;

  select count(*) into v_count from public.answers
  where game_day=p_game_day and game_no=p_game_no and prompt_no=p_prompt_no
    and lower(regexp_replace(trim(answer),'\s+',' ','g'))=v_norm and user_id<>v_uid;

  v_player := greatest(40,100-least(60,v_count*8));
  v_words := regexp_split_to_array(v_norm,'\s+');
  v_word_count := cardinality(v_words);
  select count(distinct w), count(distinct w) filter (
    where length(w) >= 4 and w not in ('with','from','that','this','your','have','into','over','under','some','very','like','and','the','for')
  ), coalesce(avg(length(w)),0)
  into v_unique_words,v_content_words,v_avg_word_len
  from unnest(v_words) as tokens(w);

  v_specificity := least(100,greatest(10,
    18 + least(v_content_words,6)*9
       + greatest(0,v_unique_words-1)*4
       + greatest(0,round(v_avg_word_len-3)::integer)*3
       + case when v_norm ~ '[0-9]' then 4 else 0 end
  ));
  v_internet := v_specificity;
  v_total := round(v_internet*0.7 + v_player*0.3);

  insert into public.answers(user_id,game_day,game_no,prompt_no,prompt,answer,player_points,internet_points,total_points)
  values(v_uid,p_game_day,p_game_no,p_prompt_no,p_prompt,trim(p_answer),v_player,v_internet,v_total);

  update public.profiles as prof
    set coins=prof.coins+v_total,total_points=prof.total_points+v_total
    where prof.id=v_uid;

  return query select v_player,v_internet,v_total;
end;
$$;
grant execute on function public.submit_krillion_answer(date,integer,integer,text,text) to authenticated;

-- Public profile data is already readable to authenticated users under the 2.0 policy.
-- Existing rows and purchases are intentionally untouched.
