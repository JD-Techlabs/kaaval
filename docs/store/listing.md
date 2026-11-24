# Google Play store listing

Developer name: **JD Techlabs**. Package: `com.jdtechlabs.kavaryn`. Support email: jdtechlabs.support@gmail.com.

Privacy policy: https://jd-techlabs.github.io/kaaval/store/privacy_policy.html · Terms of Service: https://jd-techlabs.github.io/kaaval/store/terms.html (source in `docs/store/`).

Check the game name and the hero names for trademark and Play availability before publishing (spec §19).

## App name (max 30 characters)

Kavaryn: Guardians of Dawn

## Short description (max 80 characters)

Survive the night, protect your village, and light the lamps before dawn.

## Full description (max 4,000 characters)

Night is falling on the village, and something is moving in the forest.

You are the village guardian. Move with one thumb — your weapons fire on their own. Hold out for fifteen minutes against swarms of forest creatures, and the dawn will do the rest.

EASY TO START, HARD TO PUT DOWN
• One-thumb controls: touch anywhere and move.
• Every night lasts 15 minutes. Every 30 seconds brings a new choice.
• Sling stones, orbiting lamp flames, bamboo spears, firecrackers, thorn whips, chilli smoke, valaris and war drums: mix up to four weapons and four passives each run.
• Max out a weapon with the right passive, defeat a boss, and it evolves into something far stronger.
• Life potions drop in the dark when you need them most.

SIX GUARDIANS
• Start as Lampwarden, the Night Watch, and unlock Kindlecrest, Galestride, Banyanshield, Voltmantle and Mornhelm.
• Reach level 10, 20 and 30 in a night to earn Hero Gifts. Collect hero pieces from gifts to unlock new guardians.

EVERY NIGHT BUILDS SOMETHING
• Win or lose, you bring coins, timber, food and more home.
• Rebuild the Blacksmith, Healer's Hut, Watchtower, Granary, Training Ground, Library and Lamp Tower. You can see each one grow.
• Buy new land and raise farms, quarries, mills, oil wells and workshops that keep producing while you are away.
• A stronger village makes a stronger guardian. More lamps light up as it grows.

LEAD YOUR VILLAGE THROUGH SEVEN AGES
• From the Founders' Age to the Age of Keeps, the Blackpowder Age, the Age of Learning, the Age of Steam, the Age of Steel and the Age of Circuits.
• Each age opens new resources, new buildings and higher building levels.
• Your guardian's weapon grows with the village: from a sling to bows, muskets, rifles and heavy guns, with tanks, jets and missiles called in at the end.
• Every guardian has their own weapon line, their own look in each age, and a bonus to one resource.

FACE WHAT HIDES IN THE DARK
• Shadow Wisps, Thorn Crawlers, Gloom Moths, Shell Beetles, Hollow Shades, Mud Golems and ember-stealing Lantern Thieves.
• Every level you gain brings a new creature, and the forest grows stronger as you do.
• Three bosses: the Thorn Queen, the Banyan Wraith, and the Eclipse Beast that swallows the light.

FAIR TO PLAY
• Plays fully offline.
• No forced ads. Ads are optional and only ever give you a reward you asked for.
• The village, every weapon and four of the six guardians can be earned by playing. Two elite guardians and some skins are available only by purchase.
• Chest and gift drop odds are shown in the game.

Daily missions, a 7-day login calendar, free chests and achievements give you something new each day.

Light the lamps. Hold the line. See the dawn.

---
This game contains optional in-app purchases and optional rewarded ads. It includes randomised items (chests and Hero Gifts); the odds are displayed in the game before you open them.
Support: jdtechlabs.support@gmail.com

## Release notes (first release)

Welcome, guardian. The first night begins.

## Category and tags

- Category: Action (alternative: Role Playing)
- Tags: Roguelike, Casual, Single player, Offline, Stylized

## Content rating answers (IARC) — guidance

- Violence: fantasy violence against fantasy creatures, no blood or gore, no harm to people. From the later ages the hero uses guns, and called-in tanks, jets and missiles attack the creatures, so answer **yes** to weapons and to violence against non-human characters. Expect a rating around PEGI 7–12 / Teen; accept what the questionnaire gives.
- No sexual content, profanity, drugs, gambling with real money, or user-to-user communication.
- Contains in-app purchases: yes. Contains randomised purchasable items: yes (Guardian Chest, bought with gems that can be bought with money), with odds disclosed. Hero Gifts are random too but are only earned by playing.
- Contains ads: yes.

## Target audience

13 and over. Do not select any age group under 13.

## Data safety form — guidance

| Data type | Collected | Shared | Purpose | Notes |
|---|---|---|---|---|
| Device or other IDs (advertising ID) | Yes | Yes | Advertising, fraud prevention | By the Google Mobile Ads SDK |
| App interactions / diagnostics | Yes | Yes | Advertising, analytics | By the Google Mobile Ads SDK |
| Approximate location (from IP) | Yes | Yes | Advertising | By the Google Mobile Ads SDK |
| Purchase history | Yes | No | App functionality | By Google Play Billing |

- Data is encrypted in transit: yes.
- Users can request deletion: game data is on-device only; clearing app data deletes it.
- Confirm these answers against Google's current guidance for the Mobile Ads SDK when you fill in the form.

## Graphics

All in `docs/store/graphics/`, produced by `tools/store_graphics.ps1`:

- `icon_512.png` — store icon, 512×512.
- `feature_graphic.png` — 1024×500.
- `screenshot_1_village.png` … `screenshot_6_ages.png` — phone screenshots, 9:16.

Re-run the script after any visual change so the store matches the game.

## Preview video

`tools\make_trailer.ps1` records a 44-second portrait trailer (1080×1920, 30 fps, game music and sound) to `build\trailer\kavaryn_trailer.avi` with Godot's Movie Maker. Scenes, captions and timing are in `tools/trailer_director.gd`: title card → a night (survive, level-up cards, swarm, Thorn Queen) → village and the ages panel → Age of Circuits jets and missiles → end card. Play accepts portrait preview videos as long as there are no black side bars.

Upload it to YouTube as **Public or Unlisted**, audience "No, it's not made for kids", no ads (no monetisation), no age restriction. Paste the link into Play Console → Main store listing → Video as `https://www.youtube.com/watch?v=<id>`. If YouTube files it as a Short (`youtube.com/shorts/<id>`), use the same id in the `watch?v=` form.

### YouTube details

- **Thumbnail:** YouTube files this vertical, under-3-minute video as a **Short**, so upload the portrait `docs/store/graphics/youtube_thumbnail_vertical.jpg` (1080×1920); a 16:9 image gets cropped to its middle strip. `youtube_thumbnail.jpg` (1280×720) is for a regular landscape video. Rebuild it from the latest trailer with `python tools/make_thumbnail.py` (needs Pillow). Custom thumbnails need a phone-verified YouTube channel.
- **Title (max 100):** Kavaryn: Guardians of Dawn – Official Trailer | Roguelite Survivor for Android
- **Description:**

  > Night is falling on the village. Hold out against swarms of forest creatures with one thumb — your weapons fire on their own — and rebuild your village between nights. Lead it through seven ages, from slings to jets and missiles.
  >
  > • One-thumb roguelite action, 15-minute nights
  > • Six guardians, evolving weapons, three bosses
  > • Village building and seven ages
  > • Plays offline · optional rewarded ads · odds shown in game
  >
  > Get it on Google Play: https://play.google.com/store/apps/details?id=com.jdtechlabs.kavaryn
  >
  > #Kavaryn #roguelite #androidgames

  (The Play link works once the app is published.)
- **Tags (386 of 500 characters):** Kavaryn, Kavaryn Guardians of Dawn, Guardians of Dawn, JD Techlabs, roguelite, roguelike, survivor game, horde survival, bullet heaven, auto shooter, one thumb game, action roguelite, village builder, base building, hero collection, boss fight, mobile game, android game, offline game, free mobile game, portrait game, indie game, casual action game, new android game 2026, game trailer
- Do not tag other games' names: YouTube treats that as misleading metadata, and the project rules forbid borrowing other games' names.
- Settings: audience "No, it's not made for kids", category Gaming, monetisation off (Play needs an ad-free video), and under "Altered or synthetic content" answer **No** (that question is about realistic footage of real people, places or events; the trailer is real gameplay of a cartoon game).
