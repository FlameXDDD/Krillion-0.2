KRILLION 2.0 — INSTALLATION

FILES
- index.html: new game interface
- migration_v2.sql: database migration
- README.txt: these instructions

IMPORTANT FIRST
This is an upgrade to your existing Supabase project. Run migration_v2.sql ONCE in the SQL Editor. It creates profiles, answer history, inventory, account setup trigger, scoring and shop purchase functions. Do not delete your old tables.

CONFIGURE THE WEBSITE
1. Open index.html in Notepad or a code editor.
2. Near the top of the script, replace:
   https://YOUR_PROJECT_ID.supabase.co
   with your Supabase Project URL (not the dashboard URL).
3. Replace YOUR_SUPABASE_PUBLISHABLE_KEY with your sb_publishable_... key.
4. Save index.html.
5. Host the folder on a static hosting service (GitHub Pages, Netlify, Cloudflare Pages) and share that hosted URL.

SUPABASE AUTH
In Supabase Dashboard → Authentication → URL Configuration:
- Set Site URL to your hosted website URL.
- Add that same URL to Redirect URLs.
For a quick test opened locally, email confirmation may require a hosted URL. Do not disable security settings casually.

GAME DESIGN NOTES
- 10 games/day, 12 prompts each (120 total).
- Everyone gets the same daily prompt sets. The current front-end rotates through a built-in 10x12 prompt bank deterministically by UTC date.
- Player rarity: first matching answer receives a higher score; duplicate answers lose 15 player-rarity points per earlier matching player, down to a minimum.
- “Internet rarity” is currently a transparent text-specificity estimate based on answer length and word count. It is NOT live internet search or a measured web popularity score. To make that genuine, connect a curated dataset or server-side popularity/search provider.
- Combined score = 70% player rarity + 30% estimated internet rarity.
- Coins are earned from points and spent on shop cosmetics.
- Usernames, avatars, game answers, scores and purchased items persist in Supabase.

PROTOTYPE LIMITATIONS / SECURITY
- This is a working starter, not a production-hardened competitive platform.
- The SQL RPC enforces authentication and server-side scoring, but the prompt bank is client-side and the browser can be modified. Add server-side prompt validation, rate limits, anti-cheat checks and moderation before public launch.
- Supabase email confirmation should be configured. Usernames are unique.
- The first matching answer gets more points based on current submissions. Scores are snapshots at submission time; later matching answers do not automatically recalculate earlier players' scores.
- All authenticated users can read answers for shared rarity. Avoid storing personal information in answers.
