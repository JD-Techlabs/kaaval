# Release checklist — Kavaryn: Guardians of Dawn

Everything the code can do is done. This list is what **you** must do by hand, in order, with the exact commands. Paths assume Windows PowerShell in the project root.

## 0. Decisions to make first

- [ ] **Final game name** and trademark / Play Store name check (spec §19).
- [x] **Package name:** `com.jdtechlabs.kavaryn` (set in both presets of `export_presets.cfg` on 2026-11-21, when the game was renamed from KAAVAL). It can never be changed after the first upload.
- [ ] Personal vs organisation Play account (personal accounts need the 12-tester closed test, step 9).
- [ ] Check your employment contract for moonlighting / IP clauses before publishing (spec §19).
- [x] Support email `jdtechlabs.support@gmail.com` and developer name **JD Techlabs** are set (`data/app_config.json`, privacy policy, store listing, credits).
- [x] Privacy policy hosted with GitHub Pages (repo `JD-Techlabs/kaaval`, `/docs`) at https://jd-techlabs.github.io/kaaval/store/privacy_policy.html and set in `data/app_config.json` → `privacy_policy_url` (2026-11-21). Use the same address in Play Console. Keep `docs/store/privacy_policy.html` on the Pages branch, or the link breaks.

## 1. Tools on your PC

Already on this machine: Godot 4.7.2 (`.tools\`), Android SDK, Godot export templates 4.7.2, Gradle build template (`android\build\`).

- [ ] Install **JDK 17** (Temurin 17 is fine) and point Godot at it: Godot → Editor Settings → Export → Android → *Java SDK Path*. The debug build here was made with JDK 20, which worked, but JDK 17 is what Godot documents.
- [ ] If Gradle cannot download on your network ("Connect timed out"), run this first: `$env:JAVA_TOOL_OPTIONS = "-Djava.net.preferIPv4Stack=true"`

## 2. Test on a real phone (debug build)

```powershell
.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build\kavaryn-debug.apk
adb install -r build\kavaryn-debug.apk
```

- [ ] Plays at 60 FPS in the last five minutes of a night on a mid-range phone (the debug overlay bottom-left shows FPS and entity counts).
- [ ] Pause/resume, backgrounding the app mid-run, and the Android back button all behave.
- [ ] Rewarded ads show Google **test** ads (labelled "Test Ad").

## 3. Upload keystore (once, keep it forever)

```powershell
keytool -genkeypair -v -keystore C:\secure\kavaryn-upload.keystore -alias kavaryn-upload -keyalg RSA -keysize 2048 -validity 10000
```

- [ ] Back the keystore and its password up somewhere safe that is **not** this repository. `.gitignore` already blocks `*.keystore` and `*.jks`.
- [ ] In Play Console keep **Play App Signing** enabled (default), so a lost upload key can be reset.

## Order that works

The release build refuses to run without real AdMob ids, and Play only lets you create in-app products after an AAB is uploaded. So: **keystore (3) → AdMob app and ad unit (5, first two items) → build the AAB (8) → Play Console and internal testing (4) → products and licence testing (4) → closed test (9)**. You can add the app to AdMob before it is on Play ("not published yet") and link the store listing later.

## 4. Play Console

- [ ] Create the developer account (one-time USD 25) and create the app. Free, Game, contains ads: yes.
- [ ] Upload a first AAB to **Internal testing** (step 8) — in-app products can only be created after an AAB with the billing permission exists.
- [ ] **Monetise → Products → In-app products**: create these twelve with exactly these IDs, then activate each.

| Product ID | Type in the game | Price (INR) |
|---|---|---|
| `gems_80` | consumable | 89 |
| `gems_500` | consumable | 449 |
| `gems_1200` | consumable | 899 |
| `gems_2800` | consumable | 1,799 |
| `starter_pack` | one-time | 149 |
| `ad_free_pass` | one-time | 249 |
| `hero_ammu` | one-time | 199 |
| `hero_gale` | one-time | 249 |
| `hero_banyan` | one-time | 399 |
| `hero_volt` | one-time | 599 |
| `hero_morn` | one-time | 799 |
| `builder_2` | one-time | 299 |

Play has no consumable/non-consumable switch: all are "in-app products". The game decides which to consume (`data/products.json`).

- [ ] **Settings → Licence testing**: add your testers' Google accounts, so purchases are free test purchases.
- [ ] Test every product with a licence tester: buy, cancel, a "slow test card" (pending), and **reinstall then Shop → Restore purchases**.
- [ ] Store listing: paste from `docs/store/listing.md`. Upload the graphics from `docs/store/graphics/`: `icon_512.png`, `feature_graphic.png` and the six screenshots (regenerate with `tools\store_graphics.ps1`).
- [ ] Privacy policy URL (step 6), Data safety form and content rating (guidance in `docs/store/listing.md`), target audience 13+, ads declaration: yes.

## 5. AdMob

- [x] Create an AdMob account, **add the app** (Android), and create one **Rewarded** ad unit (done 2026-11-21).
- [x] Copy `release_config.example\ads_release.json` to `release_config\ads_release.json` and put in your real **App ID** (`ca-app-pub-…~…`) and **rewarded unit ID** (`ca-app-pub-…/…`). That folder is git-ignored. Debug builds never read it and always use Google's test IDs; the debug export preset also leaves the folder out of the APK. (Done 2026-11-21.)
- [ ] **Privacy & messaging → GDPR**: create and publish a consent message for the app. Without it no consent form appears for EEA/UK users.
- [ ] Put `app-ads.txt` at the **root** of your developer website (AdMob shows the exact line), and set that website as the developer website in Play Console. It must be at `https://<domain>/app-ads.txt`, so the game's Pages site (`jd-techlabs.github.io/kaaval/...`) cannot hold it. With GitHub, create a public repo named exactly `JD-Techlabs.github.io`, put `app-ads.txt` (and optionally a small `index.html`) in it, enable Pages, and use `https://jd-techlabs.github.io` as the developer website. AdMob can take up to 24 hours to find it.
- [ ] Add your own phone as a **test device** in AdMob before tapping real ads. Never click your own live ads.

## 6. Hosting (GitHub Pages) — privacy policy and remote config

1. Create a public GitHub repository, e.g. `kavaryn-site`.
2. Copy in `docs/store/privacy_policy.html` (developer name, support email and effective date are already filled in; change the date if you publish later) and `docs/remote_config/remote_config.json`.
3. Repository → Settings → Pages → Deploy from branch `main`, folder `/`.
4. Your URLs become `https://<user>.github.io/kavaryn-site/privacy_policy.html` and `https://<user>.github.io/kavaryn-site/remote_config.json`.
5. Put them in `data/app_config.json` (`privacy_policy_url`, `remote_config_url`).

Changing the hosted JSON changes difficulty and rewards without a new build: the game fetches it at launch (3 s timeout), caches it, and falls back to the bundled defaults. Only the keys already in that file are accepted. GitHub Pages can take a few minutes to serve an edit.

## 7. Version numbers

Before every upload raise `version/code` (must increase each time) and `version/name` in **both** presets in `export_presets.cfg`, and `config/version` in `project.godot`.

## 8. Build the signed AAB

```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH     = "C:\secure\kavaryn-upload.keystore"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER     = "kavaryn-upload"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<your password>"
powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
```

The script runs the tests, checks that the package name and ad IDs are real, writes your AdMob App ID into the manifest for this build only, and produces `build\kavaryn-release.aab`. Check the AAB is under 80 MB.

- [x] Target API level: Godot 4.7.2's template targets API 36 (`android/build/config.gradle`), which meets Play's current rule. Play Console warns on upload if that changes; then set `gradle_build/target_sdk` in the release preset.

## 9. Closed test, then production

- [ ] Upload the AAB to **Closed testing**, add at least **12 testers** (a Google Group as the tester list is easiest: testers join the group, then open the opt-in link), and send them the opt-in link. New personal accounts need 12 testers opted in for **14 continuous days** before production access can be requested. Ask them to actually play.
- [ ] Read the **Pre-launch report** and fix any crash it finds.
- [ ] Apply for production access, then roll out (start at 20%).

## Screenshots

Screenshot mode hides the debug overlay. On desktop:

```powershell
.tools\Godot_v4.7.2-stable_win64_console.exe --path . -- --screenshot-mode
```

Press **F12** at any time; PNGs go to `%APPDATA%\Godot\app_userdata\Kavaryn_ Guardians of Dawn\screenshots`. For Play's phone-screenshot size, set the window to 1080×1920 first (Project Settings → Display → Window → *Window Width/Height Override*), or take them on the phone.

Scripted captures: `-- --screenshot-mode --goto=run --skip=400 --shot=C:\shots\run.png` (skips 400 s into a night, saves, quits). `--goto` accepts `home`, `run`, `heroes`, `shop`, `missions`, `settings`. Add `--demo-profile` to capture with a mid-game profile (every building stage, gifts, pieces) without touching your own save.
