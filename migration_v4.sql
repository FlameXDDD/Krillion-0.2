-- KRILLION 3.1 additive migration. Run once after migration_v3.sql.
alter table public.profiles
 add column if not exists equipped_overlay text,
 add column if not exists equipped_title_card text,
 add column if not exists equipped_name_effect text,
 add column if not exists equipped_profile_bg text,
 add column if not exists equipped_badge text;

create table if not exists public.krillion_redeem_codes(
 code text primary key,
 coin_reward integer not null check(coin_reward between 1 and 1000000),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.krillion_code_redemptions(
 code text not null references public.krillion_redeem_codes(code) on delete restrict,
 user_id uuid not null references public.profiles(id) on delete cascade,
 redeemed_at timestamptz not null default now(),
 primary key(code,user_id)
);
alter table public.krillion_redeem_codes enable row level security;
alter table public.krillion_code_redemptions enable row level security;
revoke all on public.krillion_redeem_codes from anon,authenticated;
revoke all on public.krillion_code_redemptions from anon,authenticated;
-- Add secret codes directly in Supabase SQL Editor after this migration.
-- Do not commit real redeem codes to this public repository.

create or replace function public.redeem_krillion_code(p_code text)
returns integer language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_reward integer; v_active boolean;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 if p_code is null or length(trim(p_code))<1 or length(p_code)>40 then raise exception 'Enter a valid code'; end if;
 select coin_reward,active into v_reward,v_active from public.krillion_redeem_codes where code=trim(p_code) for update;
 if not found or not v_active then raise exception 'Invalid or inactive code'; end if;
 if exists(select 1 from public.krillion_code_redemptions where code=trim(p_code) and user_id=v_uid) then raise exception 'You have already redeemed this code'; end if;
 insert into public.krillion_code_redemptions(code,user_id) values(trim(p_code),v_uid);
 update public.profiles set coins=coins+v_reward where id=v_uid;
 return v_reward;
end; $$;
revoke all on function public.redeem_krillion_code(text) from public,anon;
grant execute on function public.redeem_krillion_code(text) to authenticated;

drop function if exists public.buy_krillion_item(text,text,text,integer,text);
create or replace function public.buy_krillion_item(p_sku text)
returns void language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_name text; v_emoji text; v_kind text; v_price integer;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 select item_name,emoji,kind,price into v_name,v_emoji,v_kind,v_price from (values
 ('cap_star','Star Cap','🧢','hat',180),('crown','Tiny Crown','👑','hat',450),
 ('glasses','Pixel Shades','🕶️','accessory',250),('sparkles','Sparkle Effect','✨','profile effect',600),
 ('flame','Flame Nameplate','🔥','nameplate',700),('dance','Victory Bounce','💫','animation',900),
 ('halo','Neon Halo','😇','accessory',520),('orb','Mystery Orb','🔮','profile effect',800),
 ('overlay_neon','Neon PFP Frame','💠','PFP overlay',450),('overlay_holo','Holographic PFP Frame','🌈','PFP overlay',700),
 ('overlay_pixel','Pixel PFP Frame','🟩','PFP overlay',350),('overlay_gold','Gold PFP Frame','🏅','PFP overlay',850),
 ('card_cosmic','Cosmic Title Card','🌌','title card',650),('card_arcade','Arcade Title Card','🕹️','title card',550),
 ('card_matrix','Matrix Title Card','💻','title card',700),('name_glow','Electric Name Glow','⚡','name effect',500),
 ('name_gradient','Galaxy Name Gradient','🪐','name effect',750),('name_flame','Flame Name Effect','🔥','name effect',800),
 ('bg_stars','Starfield Profile','✨','profile background',600),('bg_grid','Cyber Grid Profile','🔷','profile background',600),
 ('badge_nerd','Certified Nerd','🤓','profile badge',300),('badge_founder','OG Player','🏆','profile badge',900),
 ('badge_arcade','Arcade Legend','👾','profile badge',500)
 ) as items(sku,item_name,emoji,kind,price) where items.sku=p_sku;
 if v_name is null then raise exception 'Unknown shop item'; end if;
 if exists(select 1 from public.inventory where user_id=v_uid and sku=p_sku) then raise exception 'Already owned'; end if;
 update public.profiles set coins=coins-v_price where id=v_uid and coins>=v_price;
 if not found then raise exception 'Not enough coins'; end if;
 insert into public.inventory(user_id,sku,item_name,emoji,kind) values(v_uid,p_sku,v_name,v_emoji,v_kind);
end; $$;
revoke all on function public.buy_krillion_item(text) from public,anon;
grant execute on function public.buy_krillion_item(text) to authenticated;

create or replace function public.equip_krillion_item(p_sku text)
returns void language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_kind text;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 select kind into v_kind from public.inventory where user_id=v_uid and sku=p_sku;
 if not found then raise exception 'You do not own this item'; end if;
 update public.profiles set
 equipped_sku=case when v_kind in('hat','accessory','nameplate','animation','profile effect') then p_sku else equipped_sku end,
 equipped_overlay=case when v_kind='PFP overlay' then p_sku else equipped_overlay end,
 equipped_title_card=case when v_kind='title card' then p_sku else equipped_title_card end,
 equipped_name_effect=case when v_kind='name effect' then p_sku else equipped_name_effect end,
 equipped_profile_bg=case when v_kind='profile background' then p_sku else equipped_profile_bg end,
 equipped_badge=case when v_kind='profile badge' then p_sku else equipped_badge end
 where id=v_uid;
end; $$;
revoke all on function public.equip_krillion_item(text) from public,anon;
grant execute on function public.equip_krillion_item(text) to authenticated;

create or replace function public.buy_krillion_theme(p_sku text)
returns void language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_name text; v_price integer;
begin
 if v_uid is null then raise exception 'Sign in required'; end if;
 select name,price into v_name,v_price from (values
 ('theme_crimson','Crimson Rush',350),('theme_ocean','Deep Ocean',350),('theme_void','Void Protocol',500),
 ('theme_nebula','Nebula Drift',650),('theme_cursed','Cursed Pulse',650),('theme_arcade','8-Bit Arcade',550),
 ('theme_lab','Mad Scientist',600),('theme_codex','Fantasy Codex',700),('theme_cyber','Cyber Hacker',700),
 ('theme_mecha','Mecha Core',750)
 ) as t(sku,name,price) where t.sku=p_sku;
 if v_name is null then raise exception 'Unknown theme'; end if;
 if exists(select 1 from public.inventory where user_id=v_uid and sku=p_sku) then raise exception 'Theme already owned'; end if;
 update public.profiles set coins=coins-v_price where id=v_uid and coins>=v_price;
 if not found then raise exception 'Not enough coins'; end if;
 insert into public.inventory(user_id,sku,item_name,emoji,kind) values(v_uid,p_sku,v_name,'🎨','theme');
end; $$;
revoke all on function public.buy_krillion_theme(text) from public,anon;
grant execute on function public.buy_krillion_theme(text) to authenticated;
grant select on public.profiles to authenticated;
