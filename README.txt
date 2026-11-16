KRILLION 3.1 — INSTALLATION (DRAFT)

FILES
- index.html: game interface
- migration_v2.sql: original KRILLION 2.0 database setup (already installed on the existing project)
- migration_v3.sql: additive KRILLION 3.0 database upgrade
- migration_v3_1.sql: additive KRILLION 3.1 database upgrade (run only when the 3.1 frontend is ready)
- README.txt: these instructions

UPGRADING AN EXISTING KRILLION 2.0 PROJECT
1. Keep the existing Supabase project and its data.
2. Run migration_v3.sql ONCE in the Supabase SQL Editor, after migration_v2.sql.
3. Do not delete or recreate profiles, answers, inventory, or auth users.
4. Publish the updated index.html from the krillion-3.0 branch after reviewing and merging the pull request.

CONFIGURATION
The index.html file contains the project's Supabase URL and public publishable key. A publishable key is intended for browser use; never put a Supabase secret/service-role key in frontend code.
In Supabase Dashboard → Authentication → URL Configuration, set the Site URL and Redirect URLs to the hosted website address.

KRILLION 3.0 FEATURES (existing release)

KRILLION 3.1 DRAFT FEATURES
- One-time-per-player promo code redemption (private codes are added in Supabase, not stored in this public repository).
- Expanded item shop: avatar frames, title cards, name effects, profile backgrounds and badges.
- New original themes: 8-Bit Arcade, Mad Scientist, Fantasy Codex, Cyber Hacker and Mecha Core.
- Player rank labels: Newbie, Rookie, Regular, Grinder, Veteran, Elite and Top Board (global top 10).
- 10 daily games with 12 prompts each.
- Player search, follow/unfollow, and public player profiles.
- Preset emoji avatars or uploaded PNG/JPG/WEBP avatars (maximum 2 MB), plus avatar background colours.
- Original game themes: Midnight Lime, Crimson Rush, Deep Ocean, Void Protocol, Nebula Drift, and Cursed Pulse.
- Existing profiles, answers, points, coins and inventory are preserved by the additive migration.

SCORING
- Combined score: 70% niche-specificity estimate + 30% player rarity.
- Player rarity starts at 100 and drops by 8 for each earlier matching answer, to a minimum of 40.
- The niche-specificity estimate looks at descriptive and distinctive wording. It is NOT a live internet search or a measured web-popularity score.
- Scores are saved when an answer is submitted; earlier scores are not recalculated when later players submit matching answers.

PROTOTYPE LIMITATIONS
- The prompt bank and answer submission interface run in the browser. This is a prototype, not a hardened competitive platform.
- Do not enter personal or sensitive information as answers.
- Before a large public launch, add server-side prompt validation, rate limits, moderation and stronger anti-cheat protections.
