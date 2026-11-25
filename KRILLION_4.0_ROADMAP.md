# KRILLION 4.0 — Development Roadmap

KRILLION 4.0 is being developed on the `krillion-4.0` branch. The live `main` branch remains on 3.1 until the release is reviewed and merged.

## Release principles
- Preserve existing Supabase Auth accounts, profiles, answers, points, coins, inventory, themes, follows and progress.
- Make database changes additive and reversible where practical.
- Keep scoring, rewards, matchmaking and anti-abuse checks server-authoritative.
- Test features with multiple accounts before merging.
- Treat accessibility as a core requirement, not a cosmetic extra.

## Foundation work started
- [x] Create `krillion-4.0` from `main`.
- [x] Explicitly sort the daily leaderboard by points descending, then username for deterministic ties.
- [x] Refresh the daily leaderboard automatically every 30 seconds while signed in.
- [x] Improve mobile touch targets, spacing, responsive wrapping and input sizing.
- [ ] Verify leaderboard aggregation and point totals against actual multi-account test data; sorting alone does not correct an incorrect underlying score total.

## Bug fixes and core improvements
- [x] Harden the sign-up/sign-in UI: prevent duplicate clicks while requests are running, normalize email input, check username availability before signup, and show clearer messages for common auth errors and email-confirmation flow. (Committed; actual Supabase signup/confirmation testing still required.)
- [ ] Audit daily leaderboard aggregation, duplicate submissions, scoring and ranking. Highest valid daily total must rank first.
- [ ] Improve profile-view navigation and prevent users getting stuck on a public profile.
- [ ] Add automated and manual regression tests around existing 3.1 features.
- [x] Add a one-question-at-a-time daily answer flow: save each answer before advancing, show question progress, and resume at the first unanswered prompt after refresh. (Committed; browser/database testing still required.)
- [x] Add a top-left countdown to the next UTC daily reset, using the same UTC date boundary as daily questions and scores; reload on day rollover. (Committed; reset-boundary testing still required.)
- [x] Add a deterministic day-seeded shuffle of the existing prompt bank so all players get the same varied set for a given UTC day and refreshes do not reshuffle it. (Committed; question-bank quality and duplicate audit still required.)

## Quick Play
- [ ] Add a Quick Play option at the bottom of the login screen.
- [ ] Allow one daily guest attempt without an account.
- [ ] Allow eligible guest results/rewards to be claimed after sign-in or account creation.
- [ ] Enforce one attempt and one reward claim per person/day server-side; do not rely only on browser storage, which can be cleared or bypassed.
- [ ] Define fair guest identity and recovery rules before launch to reduce duplicate claims without collecting unnecessary personal data.

## Player profiles and customization
- [ ] Redesign public profiles to avoid blank/empty presentation.
- [ ] Display join date, username, lifetime points, rank, stats, avatar, equipped overlays, title cards, name effects, profile background and badges.
- [ ] Add optional bio.
- [ ] Add optional contact/social handle fields with private-by-default visibility controls. Do not encourage sharing phone numbers, home addresses, school details or personal email addresses publicly; prefer platform usernames and in-app friend requests.
- [ ] Add username colour customization and nameplates.
- [ ] Add a profile editor and preview.
- [ ] Add clear back/close navigation from public profiles.

## Friends, parties and lobby
- [ ] Define friendship as a mutual follow (both players follow each other), displayed as Friends.
- [ ] Add party creation, invitations, join/leave, member list and ready state.
- [ ] Add a party leader who selects the game mode and starts a match.
- [ ] Build the lobby as a reusable multiplayer foundation for future modes.
- [ ] Add privacy controls for invitations and party availability; do not expose private presence by default.

## Battle Bash
- [ ] Build a 1–5 player match flow, aiming for at least two real players.
- [ ] Add a 60-second matchmaking window.
- [ ] Fill remaining slots with clearly identified bots when appropriate.
- [ ] Add direct 1v1 challenges.
- [ ] Run about seven sequential flashcard-style questions; no skip/pass.
- [ ] Compare submitted answers promptly and rank by niche-specificity, with duplicate answers last and response time as a tie-break when answers are similarly niche.
- [ ] Keep answer validation, match state and scoring on the server; avoid trusting client-side results.
- [ ] Design and test bot behavior so bots do not distort real-player leaderboards.
- [ ] Add CURSE power-up eligibility after poor performance across three consecutive matches; allow use against an opponent to send a similar but harder question, including 1v1.
- [ ] Add rate limits, reconnect handling, disconnect rules and match completion safeguards.

## Accessibility and mobile
- [ ] Ensure responsive support for phones, tablets and desktop.
- [ ] Use large touch targets, readable text, clear labels and consistent navigation.
- [ ] Provide optional reduced motion and adjustable visual density where practical.
- [ ] Use clear status messages and avoid relying on colour alone.
- [ ] Test with a range of users and preferences; do not assume one accessibility setting suits everyone.

## Release and testing
- [ ] Test sign-up, email confirmation, sign-in and account recovery.
- [ ] Test daily scoring/ranking with multiple accounts and known score fixtures.
- [ ] Test one-by-one answer flow, autosave/reconnect recovery and daily countdown at the reset boundary.
- [ ] Test randomized daily question sets for variety, consistency across players and no within-day duplicates.
- [ ] Test guest attempt limits and reward claiming across devices/sessions.
- [ ] Test mutual follows, party invitations and lobby membership.
- [ ] Test Battle Bash 1–5 players, bot fill, 1v1, ties, duplicate answers and disconnects.
- [ ] Test mobile layouts and accessibility options on real devices.
- [ ] Confirm existing 3.1 accounts, balances, inventory and history remain intact.
- [ ] Review all SQL migrations before running them in the existing Supabase project.
- [ ] Merge to `main` only after review and user approval.

## Important status
The first foundation changes have been committed to the development branch. This roadmap is a plan, not a claim that all listed features are implemented. The live game remains on `main` until the finished update is approved and merged.
