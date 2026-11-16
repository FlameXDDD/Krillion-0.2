KRILLION 3.0 — INSTALLATION

WHAT'S INCLUDED
- index.html: KRILLION 3.0 game interface
- migration_v2.sql: original 2.0 database setup (only if starting fresh)
- migration_v3.sql: additive 3.0 upgrade for an existing 2.0 project
- README.txt: these instructions

UPGRADE AN EXISTING KRILLION 2.0 PROJECT
1. Open your Supabase project → SQL Editor.
2. Open migration_v3.sql from this repository.
3. Copy the entire file into a new SQL query and run it ONCE.
4. Do NOT delete your existing tables or run migration_v2.sql again.
5. The upgrade adds profile customisation, follows, theme purchases and the updated scoring function. Existing accounts, answers, points, coins and inventory are kept.

AVATAR UPLOADS
The migration creates a public "avatars" Storage bucket. Uploaded images are limited to PNG, JPG or WEBP and 2 MB. Signed-in users can upload only into their own user-ID folder. Images are public so they can appear on player profiles.

PUBLISH THE WEBSITE
1. Replace the index.html file in your GitHub repository with the new version from this KRILLION 3.0 branch.
2. Merge the KRILLION 3.0 pull request into main when you're ready.
3. GitHub Pages should publish the updated site automatically. Keep the same website URL.

SCORING
- 70% niche-specificity estimate + 30% player rarity.
- The niche score is a transparent text-specificity estimate using descriptive words, distinct words and answer detail. It is NOT live internet search or a measured web popularity score.
- Player rarity starts at 100 and drops by 8 for each matching earlier player answer, to a floor of 40.
- Combined score is rounded to the nearest whole point.
- Scores are snapshots when submitted; later answers do not recalculate earlier scores.

NEW FEATURES
- Follow and unfollow other players; search usernames and view public profiles.
- Use preset emoji avatars or upload your own image.
- Choose an avatar background colour.
- Buy and equip original colour themes: Crimson Rush, Deep Ocean, Void Protocol, Nebula Drift and Cursed Pulse.
- Themes are original designs inspired by broad space/anime colour moods, not official franchise art or branding.

IMPORTANT
- Run migration_v3.sql only once, after your existing 2.0 setup.
- Keep the Supabase publishable/anon key in the frontend; never put a service-role/secret key in index.html.
- Supabase Auth Site URL and Redirect URLs should continue to use your GitHub Pages URL.
- The first public release is still a prototype. Add stronger anti-cheat, moderation and server-side prompt validation before treating scores as high-stakes competition.
