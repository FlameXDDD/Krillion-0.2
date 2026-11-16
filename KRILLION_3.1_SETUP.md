# KRILLION 3.1 setup

## Supabase

1. Open the project's Supabase SQL Editor.
2. Open `migration_v4.sql` from this repository and run the complete file once. It is additive and preserves existing profiles, answers, coins, points, follows, inventory and themes.
3. Add your private redeem codes directly in the Supabase SQL Editor. Do not put real codes in this public GitHub repository.

Example for adding a private 1,000-coin code:

```sql
insert into public.krillion_redeem_codes(code, coin_reward, active)
values ('YOUR_PRIVATE_CODE', 1000, true)
on conflict (code) do update
set coin_reward = excluded.coin_reward, active = true;
```

The code table has no client read/write permissions. Players redeem through the `redeem_krillion_code` function, which credits coins on the server and records one redemption per player per code.

## KRILLION 3.1 changes

- One-time-per-player redeem codes.
- Expanded original theme collection.
- Shop items for PFP overlays, title cards, name effects, profile backgrounds and badges.
- Server-side item catalogue and fixed purchase prices.
- Server-side cosmetic equip checks.
- Rank titles based on lifetime points, with Top Board for the top ten players.
- Existing game data and player progress are retained.

The niche-specificity score remains an estimate, not a live internet popularity lookup.
