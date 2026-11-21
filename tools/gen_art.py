"""Generates the game's original SVG art into assets/sprites.

All shapes are authored here (no third-party art), so the output is the
project's own work. Re-run with:  python tools/gen_art.py
"""
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
OUT = "#141a2e"  # outline colour


def svg(name, w, h, body):
    path = os.path.join(ROOT, name + ".svg")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{body}\n</svg>\n')


HERO_BODIES = {}


def hero(name, suit, accent, cape, skin, emblem, extra):
    """Original caped guardian: mask, cape, chest emblem. Not based on any existing character."""
    HERO_BODIES[name] = body = f'''
<ellipse cx="48" cy="88" rx="24" ry="6" fill="#000" opacity="0.35"/>
<path d="M30 46 Q8 62 14 88 Q30 78 36 86 L60 86 Q66 78 82 88 Q88 62 66 46 Z" fill="{cape}" stroke="{OUT}" stroke-width="4" stroke-linejoin="round"/>
<path d="M32 86 Q28 52 48 50 Q68 52 64 86 Z" fill="{suit}" stroke="{OUT}" stroke-width="4" stroke-linejoin="round"/>
<path d="M33 74 H63" stroke="{accent}" stroke-width="6"/>
<rect x="43" y="71" width="10" height="9" rx="2" fill="#fff3c4" stroke="{OUT}" stroke-width="2"/>
{emblem}
<path d="M33 52 Q48 60 63 52" stroke="{accent}" stroke-width="5" fill="none" stroke-linecap="round"/>
<circle cx="48" cy="32" r="18" fill="{skin}" stroke="{OUT}" stroke-width="4"/>
<path d="M30 28 Q48 22 66 28 L66 37 Q57 42 48 37 Q39 42 30 37 Z" fill="{suit}" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>
<ellipse cx="40" cy="32" rx="4.5" ry="3" fill="#fff"/><ellipse cx="56" cy="32" rx="4.5" ry="3" fill="#fff"/>
<path d="M42 43 Q48 47 54 43" stroke="{OUT}" stroke-width="2.5" fill="none" stroke-linecap="round"/>
{extra}'''
    svg(name, 96, 96, body)


# Lampwarden: indigo suit, amber cape, lamp emblem, short hair, light-tipped staff.
hero("hero_muthu", "#2b3f7a", "#ffb347", "#c8552d", "#c98a5a",
     f'<path d="M48 56 L55 63 L48 70 L41 63 Z" fill="#ffd36b" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/>',
     f'<path d="M30 24 Q34 10 48 12 Q62 10 66 24 Q56 18 48 20 Q40 18 30 24 Z" fill="#2a1c14" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
     f'<path d="M80 90 V34" stroke="#7a5230" stroke-width="5" stroke-linecap="round"/>'
     f'<circle cx="80" cy="28" r="10" fill="#ffb347" opacity="0.35"/>'
     f'<circle cx="80" cy="28" r="6" fill="#ffd36b" stroke="{OUT}" stroke-width="3"/>')
# Kindlecrest: teal suit, gold cape, flame emblem and a flame crest on the head.
hero("hero_ammu", "#1f6f6b", "#ffd36b", "#e0902a", "#b9784c",
     f'<path d="M48 55 Q55 63 51 69 Q48 72 45 69 Q41 63 48 55 Z" fill="#ff8a2a" stroke="#fff3c4" stroke-width="2"/>',
     f'<path d="M32 26 Q30 12 48 12 Q66 12 64 26 Q56 18 48 20 Q40 18 32 26 Z" fill="#1c1420" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
     f'<path d="M48 0 Q58 8 52 16 Q48 19 44 16 Q38 8 48 0 Z" fill="#ffb347" stroke="#ff6a1a" stroke-width="2.5" stroke-linejoin="round"/>'
     f'<path d="M30 30 L22 26 L26 36 Z M66 30 L74 26 L70 36 Z" fill="#ffd36b" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/>')

# Galestride: sky-blue suit, pale cape, wind-swirl emblem, swept head fins and a trailing scarf.
hero("hero_gale", "#2f7fb8", "#e7fffb", "#bfe6ee", "#c98a5a",
     f'<path d="M41 60 Q48 54 54 60 Q57 66 50 67 Q45 66 47 62" fill="none" stroke="#e7fffb" stroke-width="3" stroke-linecap="round"/>',
     f'<path d="M30 26 Q32 12 48 12 Q64 12 66 26 Q56 18 48 20 Q40 18 30 26 Z" fill="#3a2a20" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
     f'<path d="M30 28 L12 16 L24 36 Z M66 28 L84 16 L72 36 Z" fill="#e7fffb" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/>'
     f'<path d="M62 52 Q78 50 90 40 Q84 54 70 58 Z" fill="#e7fffb" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/>')
# Banyanshield: moss suit, bark cape, leaf emblem, banded helm and a round shield.
hero("hero_banyan", "#4b6a2f", "#c7e88a", "#6b4a2b", "#a86f45",
     f'<path d="M48 55 Q57 60 48 71 Q39 60 48 55 Z" fill="#c7e88a" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/><path d="M48 58 V69" stroke="{OUT}" stroke-width="2"/>',
     f'<path d="M28 28 Q28 8 48 8 Q68 8 68 28 Q58 20 48 22 Q38 20 28 28 Z" fill="#6b4a2b" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
     f'<path d="M30 18 H66" stroke="#c7e88a" stroke-width="4" stroke-linecap="round"/>'
     f'<circle cx="20" cy="66" r="17" fill="#6b4a2b" stroke="{OUT}" stroke-width="4"/><circle cx="20" cy="66" r="10" fill="#4b6a2f" stroke="#c7e88a" stroke-width="3"/><circle cx="20" cy="66" r="3" fill="#c7e88a"/>')
# Voltmantle: violet suit, storm-grey cape, bolt emblem, jagged crest and crackling sparks.
hero("hero_volt", "#4a2b7a", "#ffe14d", "#39415e", "#b9784c",
     f'<path d="M51 54 L43 63 H48 L45 71 L54 61 H49 Z" fill="#ffe14d" stroke="{OUT}" stroke-width="2" stroke-linejoin="round"/>',
     f'<path d="M30 26 L34 8 L41 18 L48 4 L55 18 L62 8 L66 26 Q56 18 48 20 Q40 18 30 26 Z" fill="#ffe14d" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>'
     f'<path d="M10 44 L18 50 L12 56 L20 62 M86 44 L78 50 L84 56 L76 62" fill="none" stroke="#ffe14d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>')
# Mornhelm: ivory suit, gold cape, sunrise emblem, rayed helm and a soft glow.
hero("hero_morn", "#d9cfae", "#ff8a2a", "#e3a52c", "#8f5a3a",
     f'<path d="M40 66 Q48 54 56 66 Z" fill="#ff8a2a" stroke="{OUT}" stroke-width="2.5" stroke-linejoin="round"/><path d="M38 68 H58" stroke="{OUT}" stroke-width="2.5" stroke-linecap="round"/>',
     f'<circle cx="48" cy="30" r="30" fill="#ffd36b" opacity="0.16"/>'
     f'<path d="M48 0 L52 10 L62 4 L62 14 L72 14 L66 24 Q56 16 48 18 Q40 16 30 24 L24 14 L34 14 L34 4 L44 10 Z" fill="#ffcf40" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>')

# Android adaptive launcher icon: night-and-dawn background, Lampwarden in the safe zone.
svg("icon_bg", 432, 432, '<rect width="432" height="432" fill="#101831"/><circle cx="216" cy="300" r="250" fill="#1b2a4f"/><circle cx="216" cy="250" r="150" fill="#ff8a2a" opacity="0.28"/><circle cx="216" cy="250" r="96" fill="#ffb347" opacity="0.22"/><path d="M0 432 Q30 300 100 330 Q130 280 170 330 L170 432 Z M432 432 Q402 300 332 330 Q302 280 262 330 L262 432 Z" fill="#0c312b"/>')
svg("icon_fg", 432, 432, f'<g transform="translate(100 104) scale(2.3)">{HERO_BODIES["hero_muthu"]}</g>')

svg("icons/heart", 48, 48, f'<path d="M24 43 L7 26 Q-1 15 9 8 Q18 3 24 13 Q30 3 39 8 Q49 15 41 26 Z" fill="#e2553d" stroke="{OUT}" stroke-width="3.5" stroke-linejoin="round"/><path d="M12 15 Q14 11 18 11" fill="none" stroke="#ffd0c4" stroke-width="3" stroke-linecap="round"/>')
svg("gift", 96, 96, f'<circle cx="48" cy="52" r="44" fill="#ffd36b" opacity="0.14"/><rect x="14" y="42" width="68" height="44" rx="6" fill="#c8552d" stroke="{OUT}" stroke-width="4"/><rect x="8" y="28" width="80" height="20" rx="6" fill="#e2553d" stroke="{OUT}" stroke-width="4"/><rect x="41" y="28" width="14" height="58" fill="#ffd36b" stroke="{OUT}" stroke-width="3"/><path d="M48 28 Q30 4 22 16 Q18 26 48 28 Q78 26 74 16 Q66 4 48 28 Z" fill="#ffd36b" stroke="{OUT}" stroke-width="3.5" stroke-linejoin="round"/>')

# --- regular enemies -------------------------------------------------------
svg("e_wisp", 64, 64, f'''
<path d="M32 6 Q54 22 50 42 Q46 60 32 58 Q18 60 14 42 Q10 22 32 6 Z" fill="#6c5bd6" stroke="#e7e2ff" stroke-width="3" stroke-linejoin="round"/>
<circle cx="25" cy="36" r="5" fill="#fff"/><circle cx="39" cy="36" r="5" fill="#fff"/>
<circle cx="25" cy="37" r="2" fill="{OUT}"/><circle cx="39" cy="37" r="2" fill="{OUT}"/>''')
svg("e_crawler", 80, 72, f'''
<path d="M8 50 L2 62 M20 56 L16 68 M60 56 L64 68 M72 50 L78 62" stroke="#c7e88a" stroke-width="5" stroke-linecap="round"/>
<ellipse cx="40" cy="42" rx="32" ry="22" fill="#3e7a3a" stroke="#c7e88a" stroke-width="3"/>
<path d="M18 26 L22 8 L30 24 M34 22 L40 4 L46 22 M50 24 L58 8 L62 26" fill="#8a5a2b" stroke="#c7e88a" stroke-width="3" stroke-linejoin="round"/>
<circle cx="30" cy="44" r="5" fill="#ffe14d"/><circle cx="50" cy="44" r="5" fill="#ffe14d"/>''')
svg("e_crow", 72, 56, f'''
<path d="M4 20 Q22 4 36 26 Q50 4 68 20 Q52 22 44 38 L36 52 L28 38 Q20 22 4 20 Z" fill="#232a3f" stroke="#9fb4ff" stroke-width="3" stroke-linejoin="round"/>
<circle cx="31" cy="30" r="3" fill="#ff5b5b"/><circle cx="41" cy="30" r="3" fill="#ff5b5b"/>
<path d="M33 40 L36 48 L39 40 Z" fill="#f2a53a"/>''')
svg("e_golem", 88, 88, f'''
<path d="M12 70 Q4 36 26 20 Q44 6 62 20 Q84 36 76 70 Q60 84 44 82 Q28 84 12 70 Z" fill="#7b5a3c" stroke="#e8c79a" stroke-width="3" stroke-linejoin="round"/>
<path d="M22 60 Q30 54 38 62 M52 64 Q60 56 68 62" stroke="#5a3f28" stroke-width="4" fill="none"/>
<rect x="26" y="34" width="12" height="10" rx="2" fill="#ffe9a8"/><rect x="50" y="34" width="12" height="10" rx="2" fill="#ffe9a8"/>
<path d="M32 56 H56" stroke="{OUT}" stroke-width="5" stroke-linecap="round"/>''')
svg("e_mud_pup", 48, 48, f'''
<path d="M6 38 Q2 16 24 8 Q46 16 42 38 Q24 46 6 38 Z" fill="#94704c" stroke="#e8c79a" stroke-width="3" stroke-linejoin="round"/>
<circle cx="17" cy="24" r="4" fill="#ffe9a8"/><circle cx="31" cy="24" r="4" fill="#ffe9a8"/>''')
svg("e_thief", 64, 72, f'''
<path d="M12 66 Q8 30 32 26 Q56 30 52 66 Z" fill="#2c3554" stroke="#ffd36b" stroke-width="3" stroke-linejoin="round"/>
<circle cx="32" cy="22" r="14" fill="#1c2238" stroke="#ffd36b" stroke-width="3"/>
<path d="M22 20 H42" stroke="#ffd36b" stroke-width="5" stroke-linecap="round"/>
<rect x="44" y="40" width="14" height="18" rx="3" fill="#ffb347" stroke="#fff3c4" stroke-width="2"/>
<path d="M51 40 V34" stroke="#fff3c4" stroke-width="3"/>''')

svg("e_moth", 56, 48, f'''
<path d="M28 24 Q10 0 4 14 Q0 28 22 28 Z M28 24 Q46 0 52 14 Q56 28 34 28 Z" fill="#8d7ab8" stroke="#e7e2ff" stroke-width="2.5" stroke-linejoin="round"/>
<path d="M26 28 Q12 34 14 44 Q22 44 28 32 Q34 44 42 44 Q44 34 30 28 Z" fill="#6b5a94" stroke="#e7e2ff" stroke-width="2.5" stroke-linejoin="round"/>
<ellipse cx="28" cy="26" rx="6" ry="12" fill="#3a3052" stroke="#e7e2ff" stroke-width="2"/>
<circle cx="25" cy="20" r="2.5" fill="#ffe14d"/><circle cx="31" cy="20" r="2.5" fill="#ffe14d"/>''')
svg("e_beetle", 84, 76, f'''
<path d="M10 52 L2 64 M22 62 L18 74 M62 62 L66 74 M74 52 L82 64" stroke="#9fd0e8" stroke-width="5" stroke-linecap="round"/>
<path d="M8 46 Q8 12 42 12 Q76 12 76 46 Q76 64 42 64 Q8 64 8 46 Z" fill="#2f5d7a" stroke="#9fd0e8" stroke-width="3"/>
<path d="M42 12 V64 M16 30 Q42 40 68 30" stroke="#1d3d52" stroke-width="4" fill="none"/>
<path d="M28 14 Q24 2 18 4 M56 14 Q60 2 66 4" stroke="#9fd0e8" stroke-width="4" fill="none" stroke-linecap="round"/>
<circle cx="32" cy="22" r="4" fill="#ffe9a8"/><circle cx="52" cy="22" r="4" fill="#ffe9a8"/>''')
svg("e_shade", 64, 76, f'''
<path d="M10 72 Q4 30 32 8 Q60 30 54 72 Q46 62 40 72 Q32 62 24 72 Q18 62 10 72 Z" fill="#1c2238" stroke="#7fe0c8" stroke-width="3" stroke-linejoin="round"/>
<path d="M20 36 L30 40 L20 46 Z M44 36 L34 40 L44 46 Z" fill="#7fe0c8"/>
<path d="M24 56 Q32 50 40 56" stroke="#7fe0c8" stroke-width="3" fill="none" stroke-linecap="round"/>''')

# --- bosses ----------------------------------------------------------------
svg("b_crawler_queen", 192, 176, f'''
<path d="M20 120 L4 156 M48 136 L36 170 M144 136 L156 170 M172 120 L188 156" stroke="#f0ff9a" stroke-width="9" stroke-linecap="round"/>
<ellipse cx="96" cy="104" rx="78" ry="54" fill="#2f6b3a" stroke="#f0ff9a" stroke-width="5"/>
<path d="M40 64 L50 18 L70 58 M80 54 L96 6 L112 54 M122 58 L142 18 L152 64" fill="#a3542b" stroke="#f0ff9a" stroke-width="5" stroke-linejoin="round"/>
<path d="M70 30 L82 12 L96 26 L110 12 L122 30 Z" fill="#ffcf40" stroke="{OUT}" stroke-width="4" stroke-linejoin="round"/>
<circle cx="70" cy="104" r="12" fill="#ff5252"/><circle cx="122" cy="104" r="12" fill="#ff5252"/>
<path d="M72 132 Q96 148 120 132" stroke="{OUT}" stroke-width="7" fill="none" stroke-linecap="round"/>''')
svg("b_banyan_wraith", 208, 224, f'''
<path d="M60 216 Q52 150 70 120 L138 120 Q156 150 148 216 Q128 200 104 216 Q80 200 60 216 Z" fill="#4a3a2a" stroke="#9af0c4" stroke-width="5" stroke-linejoin="round"/>
<path d="M70 150 V206 M92 150 V200 M116 150 V200 M138 150 V206" stroke="#2c2118" stroke-width="5"/>
<path d="M104 8 Q190 20 188 86 Q180 132 104 128 Q28 132 20 86 Q18 20 104 8 Z" fill="#1f5f4a" stroke="#9af0c4" stroke-width="5"/>
<path d="M40 110 V160 M168 110 V160 M26 90 V132 M182 90 V132" stroke="#3b2c1f" stroke-width="6" stroke-linecap="round"/>
<path d="M70 70 L92 80 L70 90 Z" fill="#c8ffe6"/><path d="M138 70 L116 80 L138 90 Z" fill="#c8ffe6"/>
<path d="M84 104 Q104 96 124 104" stroke="#c8ffe6" stroke-width="5" fill="none"/>''')
svg("b_eclipse_beast", 240, 240, f'''
<circle cx="120" cy="120" r="104" fill="#ff8a2a" opacity="0.35"/>
<path d="M40 70 L16 20 L76 46 M200 70 L224 20 L164 46" fill="#11131f" stroke="#ffb347" stroke-width="6" stroke-linejoin="round"/>
<circle cx="120" cy="124" r="88" fill="#0b0d18" stroke="#ffb347" stroke-width="6"/>
<path d="M70 104 L106 118 L70 132 Z" fill="#ffe08a"/><path d="M170 104 L134 118 L170 132 Z" fill="#ffe08a"/>
<path d="M76 160 L92 176 L106 160 L120 176 L134 160 L148 176 L164 160" stroke="#ffe08a" stroke-width="6" fill="none" stroke-linejoin="round"/>''')

# Night 2, Paddy Fields.
svg("b_mire_serpent", 200, 168, f'''
<path d="M18 128 Q10 92 46 92 Q82 92 80 124 Q78 152 112 152 Q150 152 150 118" fill="none" stroke="#4f7a3a" stroke-width="34" stroke-linecap="round"/>
<path d="M18 128 Q10 92 46 92 Q82 92 80 124 Q78 152 112 152 Q150 152 150 118" fill="none" stroke="#c9e88a" stroke-width="4" stroke-dasharray="10 12" stroke-linecap="round"/>
<path d="M126 112 Q118 40 158 30 Q196 26 192 66 Q190 98 150 110 Z" fill="#3d6630" stroke="#c9e88a" stroke-width="5" stroke-linejoin="round"/>
<circle cx="150" cy="56" r="9" fill="#ffe14d"/><circle cx="176" cy="54" r="9" fill="#ffe14d"/>
<path d="M146 86 Q164 98 184 84" stroke="{OUT}" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="M164 94 L160 112 M172 92 L176 110" stroke="#ff6b5a" stroke-width="4" stroke-linecap="round"/>''')
svg("b_straw_giant", 216, 232, f'''
<path d="M70 224 L84 150 M146 224 L132 150" stroke="#c99a3e" stroke-width="16" stroke-linecap="round"/>
<path d="M56 160 Q48 96 108 92 Q168 96 160 160 Q108 176 56 160 Z" fill="#d8b24a" stroke="#fff0b0" stroke-width="5" stroke-linejoin="round"/>
<path d="M70 110 L60 168 M90 102 L86 170 M126 102 L130 170 M146 110 L156 168" stroke="#a87e2c" stroke-width="4"/>
<path d="M56 112 L8 92 M160 112 L208 92" stroke="#d8b24a" stroke-width="18" stroke-linecap="round"/>
<path d="M2 82 L16 100 M10 76 L22 96 M214 82 L200 100 M206 76 L194 96" stroke="#fff0b0" stroke-width="4" stroke-linecap="round"/>
<circle cx="108" cy="62" r="40" fill="#e6c25a" stroke="#fff0b0" stroke-width="5"/>
<path d="M58 40 Q108 -6 158 40 Z" fill="#7a4e24" stroke="#fff0b0" stroke-width="4" stroke-linejoin="round"/>
<path d="M90 54 L102 64 L90 72 Z M126 54 L114 64 L126 72 Z" fill="#ff7a2a"/>
<path d="M92 84 L100 78 L108 84 L116 78 L124 84" stroke="{OUT}" stroke-width="4" fill="none" stroke-linejoin="round"/>''')
svg("b_storm_heron", 240, 232, f'''
<circle cx="120" cy="120" r="108" fill="#6fd6ff" opacity="0.22"/>
<path d="M120 112 Q40 40 6 92 Q40 104 70 128 Z M120 112 Q200 40 234 92 Q200 104 170 128 Z" fill="#3a5f8a" stroke="#cfefff" stroke-width="5" stroke-linejoin="round"/>
<path d="M30 90 L52 108 M58 72 L76 100 M210 90 L188 108 M182 72 L164 100" stroke="#cfefff" stroke-width="4" stroke-linecap="round"/>
<ellipse cx="120" cy="140" rx="44" ry="58" fill="#e8f4ff" stroke="#6fd6ff" stroke-width="5"/>
<path d="M104 196 L96 228 M136 196 L144 228" stroke="#ffcf40" stroke-width="7" stroke-linecap="round"/>
<circle cx="120" cy="70" r="26" fill="#e8f4ff" stroke="#6fd6ff" stroke-width="5"/>
<path d="M140 66 L196 78 L140 84 Z" fill="#ffcf40" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>
<circle cx="122" cy="64" r="6" fill="#1c6fd6"/>
<path d="M96 120 L112 104 L106 124 L124 110 M130 150 L148 134 L140 156" stroke="#ffe14d" stroke-width="5" fill="none" stroke-linejoin="round"/>''')

# Night 3, Old Fort.
svg("b_iron_tusk", 208, 176, f'''
<path d="M40 138 L32 170 M76 148 L72 174 M132 148 L136 174 M168 138 L176 170" stroke="#5a4a3e" stroke-width="12" stroke-linecap="round"/>
<ellipse cx="104" cy="104" rx="88" ry="56" fill="#6b5446" stroke="#d6dde8" stroke-width="5"/>
<path d="M40 64 L56 40 L74 58 L92 34 L110 54 L128 32 L144 56 L164 40 L172 66" fill="none" stroke="#2c2420" stroke-width="10" stroke-linejoin="round"/>
<rect x="128" y="74" width="70" height="56" rx="18" fill="#7d6556" stroke="#d6dde8" stroke-width="5"/>
<path d="M150 124 Q140 160 112 158 M184 124 Q196 160 206 150" stroke="#e8ecf2" stroke-width="10" fill="none" stroke-linecap="round"/>
<path d="M150 124 Q140 160 112 158 M184 124 Q196 160 206 150" stroke="{OUT}" stroke-width="2" fill="none" stroke-linecap="round"/>
<circle cx="152" cy="94" r="7" fill="#ff5252"/><circle cx="178" cy="94" r="7" fill="#ff5252"/>
<path d="M30 92 H64 M30 110 H58" stroke="#9aa6b8" stroke-width="6" stroke-linecap="round"/>''')
svg("b_hollow_captain", 208, 232, f'''
<path d="M44 224 Q34 140 104 112 Q174 140 164 224 Q144 206 124 224 Q104 206 84 224 Q64 206 44 224 Z" fill="#232a44" stroke="#7fe0c8" stroke-width="5" stroke-linejoin="round"/>
<path d="M62 150 H146 V176 H62 Z" fill="#4a556e" stroke="#d6dde8" stroke-width="4"/>
<path d="M76 150 V176 M104 150 V176 M132 150 V176" stroke="#2c3550" stroke-width="4"/>
<path d="M178 70 V214" stroke="#9aa6b8" stroke-width="8" stroke-linecap="round"/>
<path d="M178 70 L196 40 L188 76 Z" fill="#d6dde8" stroke="{OUT}" stroke-width="3" stroke-linejoin="round"/>
<circle cx="104" cy="80" r="40" fill="#1c2238" stroke="#7fe0c8" stroke-width="5"/>
<path d="M58 66 Q104 14 150 66 L142 72 Q104 40 66 72 Z" fill="#8a96ac" stroke="#d6dde8" stroke-width="4" stroke-linejoin="round"/>
<path d="M104 26 V8" stroke="#e2553d" stroke-width="8" stroke-linecap="round"/>
<path d="M82 78 L98 86 L82 94 Z M126 78 L110 86 L126 94 Z" fill="#7fe0c8"/>''')
svg("b_night_colossus", 248, 248, f'''
<circle cx="124" cy="124" r="112" fill="#9a6bff" opacity="0.25"/>
<path d="M44 236 L60 168 M204 236 L188 168" stroke="#2c2a3e" stroke-width="26" stroke-linecap="round"/>
<path d="M40 180 Q28 84 124 72 Q220 84 208 180 Q124 204 40 180 Z" fill="#3a3652" stroke="#c9b8ff" stroke-width="6" stroke-linejoin="round"/>
<path d="M64 110 H96 V140 H64 Z M152 110 H184 V140 H152 Z M108 150 H140 V176 H108 Z" fill="#2c2a3e" stroke="#6f62a0" stroke-width="3"/>
<path d="M40 110 L8 158 M208 110 L240 158" stroke="#3a3652" stroke-width="24" stroke-linecap="round"/>
<circle cx="124" cy="54" r="40" fill="#2c2a3e" stroke="#c9b8ff" stroke-width="6"/>
<path d="M98 50 L118 58 L98 66 Z M150 50 L130 58 L150 66 Z" fill="#ffe08a"/>
<path d="M84 22 L94 6 L104 20 M144 20 L154 6 L164 22" stroke="#c9b8ff" stroke-width="6" fill="none" stroke-linejoin="round"/>''')

# --- projectiles, pickups, props -------------------------------------------
svg("stone", 32, 32, f'<circle cx="16" cy="16" r="12" fill="#cfd3dc" stroke="{OUT}" stroke-width="3"/><circle cx="12" cy="12" r="4" fill="#fff" opacity="0.7"/>')
svg("meteor", 40, 40, f'<circle cx="20" cy="20" r="16" fill="#ff8a2a" stroke="#fff3c4" stroke-width="3"/><circle cx="20" cy="20" r="8" fill="#ffe08a"/>')
svg("flame", 56, 56, '<circle cx="28" cy="28" r="26" fill="#ff8a2a" opacity="0.35"/><path d="M28 6 Q46 24 40 40 Q34 52 28 50 Q22 52 16 40 Q10 24 28 6 Z" fill="#ffb347" stroke="#fff3c4" stroke-width="3"/><path d="M28 24 Q36 34 32 42 Q28 46 24 42 Q20 34 28 24 Z" fill="#fff3c4"/>')
svg("spear", 96, 20, f'<rect x="4" y="7" width="70" height="6" rx="3" fill="#b9a15a" stroke="{OUT}" stroke-width="2"/><path d="M70 2 L94 10 L70 18 Z" fill="#e8ecf2" stroke="{OUT}" stroke-width="2" stroke-linejoin="round"/>')
svg("valari", 56, 56, f'<path d="M8 46 Q10 12 46 8 Q50 8 50 14 Q26 18 20 46 Q14 52 8 46 Z" fill="#c48a4a" stroke="#fff3c4" stroke-width="3" stroke-linejoin="round"/>')
svg("ember", 32, 32, '<circle cx="16" cy="16" r="15" fill="#ff8a2a" opacity="0.35"/><path d="M16 3 L27 16 L16 29 L5 16 Z" fill="#ffb347" stroke="#fff3c4" stroke-width="2" stroke-linejoin="round"/><path d="M16 10 L21 16 L16 22 L11 16 Z" fill="#fff3c4"/>')
svg("potion", 64, 76, f'<circle cx="32" cy="48" r="30" fill="#6fe08a" fill-opacity="0.18"/><rect x="24" y="6" width="16" height="10" rx="3" fill="#b5762f" stroke="{OUT}" stroke-width="3"/><path d="M26 16 H38 V28 Q56 36 56 52 Q56 70 32 70 Q8 70 8 52 Q8 36 26 28 Z" fill="#dff3ff" fill-opacity="0.55" stroke="{OUT}" stroke-width="4" stroke-linejoin="round"/><path d="M12 48 Q22 42 32 48 Q42 54 52 48 Q54 66 32 66 Q10 66 12 48 Z" fill="#e2553d"/><path d="M32 65 L24 57 Q20 52 24 49 Q29 46 32 52 Q35 46 40 49 Q44 52 40 57 Z" fill="#fff3c4"/><path d="M18 40 Q20 34 26 32" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/>')
svg("chest", 96, 88, f'<rect x="8" y="34" width="80" height="46" rx="6" fill="#8a5a2b" stroke="{OUT}" stroke-width="4"/><path d="M8 40 Q8 10 48 10 Q88 10 88 40 Z" fill="#b5762f" stroke="{OUT}" stroke-width="4" stroke-linejoin="round"/><rect x="8" y="36" width="80" height="8" fill="#ffcf40" stroke="{OUT}" stroke-width="3"/><rect x="40" y="32" width="16" height="22" rx="3" fill="#ffcf40" stroke="{OUT}" stroke-width="3"/>')
svg("tree", 160, 200, '<rect x="68" y="130" width="24" height="64" rx="6" fill="#3b2c1f"/><circle cx="80" cy="84" r="72" fill="#0f3b33"/><circle cx="52" cy="70" r="40" fill="#14493e"/><circle cx="106" cy="96" r="44" fill="#0c312b"/>')
svg("rock", 72, 52, '<path d="M6 46 Q2 20 26 10 Q52 2 66 28 Q72 46 60 48 Z" fill="#3a4560"/><path d="M20 20 Q34 12 46 18" stroke="#56648a" stroke-width="4" fill="none" stroke-linecap="round"/>')
svg("bush", 80, 56, '<circle cx="24" cy="34" r="20" fill="#17463a"/><circle cx="46" cy="26" r="24" fill="#1c5446"/><circle cx="62" cy="38" r="16" fill="#17463a"/>')
svg("lamp", 48, 96, '<circle cx="24" cy="22" r="22" fill="#ffb347" opacity="0.3"/><rect x="21" y="34" width="6" height="56" fill="#4a3a2a"/><rect x="14" y="10" width="20" height="26" rx="4" fill="#ffd36b" stroke="#7a5230" stroke-width="3"/>')
# Paddy Fields edge and props; Old Fort wall and props.
svg("reeds", 140, 180, '<path d="M20 178 Q16 90 30 20 M44 178 Q44 80 60 8 M70 178 Q66 100 84 30 M96 178 Q98 90 112 16 M120 178 Q118 110 132 44" stroke="#5f8a3a" stroke-width="9" fill="none" stroke-linecap="round"/><path d="M30 20 Q22 34 30 48 Q38 34 30 20 Z M60 8 Q52 22 60 36 Q68 22 60 8 Z M112 16 Q104 30 112 44 Q120 30 112 16 Z" fill="#a98a4a"/><path d="M8 178 Q70 150 132 178 Z" fill="#3f6a2c"/>')
svg("haystack", 96, 80, '<path d="M6 76 Q10 18 48 8 Q86 18 90 76 Z" fill="#c99a3e" stroke="#7a5a24" stroke-width="3" stroke-linejoin="round"/><path d="M22 70 Q26 36 40 22 M48 74 V18 M74 70 Q70 36 56 22" stroke="#e6c25a" stroke-width="3" fill="none"/>')
svg("fort_wall", 140, 170, '<rect x="6" y="40" width="128" height="128" fill="#4a4f60"/><path d="M6 40 V14 H34 V40 M52 40 V14 H88 V40 M106 40 V14 H134 V40" fill="#5a6074" stroke="#2c3040" stroke-width="3"/><path d="M6 78 H134 M6 118 H134 M40 40 V78 M94 40 V78 M66 78 V118 M24 118 V168 M110 118 V168" stroke="#2c3040" stroke-width="4"/>')
svg("rubble", 88, 56, '<path d="M4 52 L10 30 L30 26 L36 52 Z" fill="#5a6074" stroke="#2c3040" stroke-width="3" stroke-linejoin="round"/><path d="M32 52 L40 18 L64 14 L72 52 Z" fill="#4a4f60" stroke="#2c3040" stroke-width="3" stroke-linejoin="round"/><path d="M64 52 L70 36 L84 38 L86 52 Z" fill="#5a6074" stroke="#2c3040" stroke-width="3" stroke-linejoin="round"/>')
svg("joy_base", 256, 256, '<circle cx="128" cy="128" r="120" fill="#fff" opacity="0.10" stroke="#fff" stroke-opacity="0.35" stroke-width="6"/>')
svg("joy_knob", 128, 128, '<circle cx="64" cy="64" r="56" fill="#ffb347" opacity="0.75" stroke="#fff3c4" stroke-width="5"/>')


# --- icons -----------------------------------------------------------------
def icon(name, bg, glyph):
    svg("icons/" + name, 96, 96, f'<rect x="4" y="4" width="88" height="88" rx="18" fill="{bg}" stroke="#fff3c4" stroke-opacity="0.5" stroke-width="3"/>{glyph}')


W, P = "#27375e", "#3d2f55"
icon("w_sling", W, '<path d="M24 76 L48 40 L72 76" stroke="#c48a4a" stroke-width="7" fill="none" stroke-linecap="round"/><circle cx="48" cy="34" r="13" fill="#cfd3dc"/>')
icon("w_lamp_orbit", W, '<circle cx="48" cy="48" r="26" fill="none" stroke="#fff3c4" stroke-opacity="0.5" stroke-width="3" stroke-dasharray="6 6"/><circle cx="48" cy="22" r="10" fill="#ffb347"/><circle cx="26" cy="62" r="10" fill="#ffb347"/><circle cx="70" cy="62" r="10" fill="#ffb347"/>')
icon("w_bamboo_spear", W, '<path d="M20 76 L62 34" stroke="#b9a15a" stroke-width="8" stroke-linecap="round"/><path d="M56 22 L78 18 L74 40 Z" fill="#e8ecf2"/>')
icon("w_firecracker", W, '<path d="M48 14 L56 38 L80 30 L62 48 L80 66 L56 58 L48 82 L40 58 L16 66 L34 48 L16 30 L40 38 Z" fill="#ff5b5b" stroke="#ffe08a" stroke-width="3" stroke-linejoin="round"/>')
icon("w_thorn_whip", W, '<path d="M18 70 Q30 20 78 26" stroke="#5fbf6a" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M34 44 L26 34 M50 30 L46 18 M66 26 L68 14" stroke="#c7e88a" stroke-width="5" stroke-linecap="round"/>')
icon("w_chilli_smoke", W, '<circle cx="36" cy="54" r="20" fill="#e2553d" opacity="0.6"/><circle cx="58" cy="44" r="22" fill="#e2553d" opacity="0.6"/><path d="M40 62 Q52 30 66 36 Q58 56 40 62 Z" fill="#ff3b30" stroke="#fff3c4" stroke-width="2"/>')
icon("w_valari", W, '<path d="M22 74 Q24 26 72 22 Q78 22 78 30 Q44 34 36 74 Q30 82 22 74 Z" fill="#c48a4a" stroke="#fff3c4" stroke-width="3"/>')
icon("w_war_drum", W, '<ellipse cx="48" cy="34" rx="28" ry="12" fill="#f0dfc0" stroke="#7a5230" stroke-width="4"/><path d="M20 34 V62 Q48 78 76 62 V34" fill="#b5442e" stroke="#7a5230" stroke-width="4"/>')
icon("p_bangle", P, '<circle cx="48" cy="48" r="24" fill="none" stroke="#cfd3dc" stroke-width="11"/>')
icon("p_sandals", P, '<path d="M26 70 Q20 40 36 24 Q50 22 52 42 Q54 62 44 74 Q32 78 26 70 Z" fill="#c48a4a" stroke="#fff3c4" stroke-width="3"/><path d="M58 30 H80 M62 46 H84 M58 62 H78" stroke="#8fd0ff" stroke-width="5" stroke-linecap="round"/>')
icon("p_neem", P, '<path d="M48 14 Q82 40 48 84 Q14 40 48 14 Z" fill="#5fbf6a" stroke="#c7e88a" stroke-width="3"/><path d="M48 24 V76" stroke="#c7e88a" stroke-width="3"/>')
icon("p_magnet", P, '<path d="M24 26 V52 Q24 76 48 76 Q72 76 72 52 V26 H56 V52 Q56 60 48 60 Q40 60 40 52 V26 Z" fill="#ff5b5b" stroke="#fff3c4" stroke-width="3"/><rect x="24" y="22" width="16" height="12" fill="#e8ecf2"/><rect x="56" y="22" width="16" height="12" fill="#e8ecf2"/>')
icon("p_whetstone", P, '<path d="M16 60 L60 28 L82 40 L38 72 Z" fill="#9aa5b8" stroke="#fff3c4" stroke-width="3" stroke-linejoin="round"/><path d="M30 60 L62 38" stroke="#fff" stroke-width="3" opacity="0.7"/>')
icon("p_hourglass", P, '<path d="M28 18 H68 L52 48 L68 78 H28 L44 48 Z" fill="#ffd36b" stroke="#fff3c4" stroke-width="3" stroke-linejoin="round"/><path d="M24 18 H72 M24 78 H72" stroke="#7a5230" stroke-width="6" stroke-linecap="round"/>')
icon("coin", "#3b3320", '<circle cx="48" cy="48" r="28" fill="#ffcf40" stroke="#a8742a" stroke-width="5"/><circle cx="48" cy="48" r="14" fill="none" stroke="#a8742a" stroke-width="4"/>')
icon("timber", "#33291e", '<rect x="16" y="26" width="64" height="18" rx="9" fill="#b5762f" stroke="#5d3a17" stroke-width="4"/><rect x="16" y="52" width="64" height="18" rx="9" fill="#c48a4a" stroke="#5d3a17" stroke-width="4"/>')
icon("gem", "#1e2f3d", '<path d="M48 16 L76 40 L48 82 L20 40 Z" fill="#59d6c9" stroke="#e7fffb" stroke-width="4" stroke-linejoin="round"/><path d="M20 40 H76 M48 16 L38 40 L48 82 L58 40 Z" stroke="#e7fffb" stroke-width="2" fill="none"/>')
icon("food", "#3a2c1c", '<path d="M18 52 Q48 92 78 52 Z" fill="#c48a4a" stroke="#5d3a17" stroke-width="4" stroke-linejoin="round"/><circle cx="36" cy="44" r="9" fill="#f4e7c0"/><circle cx="50" cy="40" r="10" fill="#f4e7c0"/><circle cx="62" cy="46" r="8" fill="#f4e7c0"/><path d="M48 30 Q52 18 62 16" stroke="#5fbf6a" stroke-width="4" fill="none" stroke-linecap="round"/>')
icon("stone", "#2a2d36", '<path d="M14 70 L24 40 L46 30 L70 36 L82 62 L66 78 L28 80 Z" fill="#8a93a6" stroke="#3a3f4c" stroke-width="4" stroke-linejoin="round"/><path d="M30 52 L50 44 M52 62 L68 54" stroke="#c9d0dc" stroke-width="3" stroke-linecap="round"/>')
icon("knowledge", "#2b2440", '<path d="M14 28 Q30 22 48 30 V78 Q30 70 14 76 Z" fill="#b7a6d6" stroke="#fff3c4" stroke-width="3" stroke-linejoin="round"/><path d="M82 28 Q66 22 48 30 V78 Q66 70 82 76 Z" fill="#d8ccef" stroke="#fff3c4" stroke-width="3" stroke-linejoin="round"/><path d="M22 40 H40 M22 50 H40 M56 40 H74 M56 50 H74" stroke="#5a4a8a" stroke-width="3"/>')
icon("oil", "#1c2228", '<path d="M48 14 Q72 46 72 60 A24 24 0 0 1 24 60 Q24 46 48 14 Z" fill="#2c2c34" stroke="#ffd36b" stroke-width="4" stroke-linejoin="round"/><path d="M36 60 Q38 70 48 72" stroke="#8fd0ff" stroke-width="4" fill="none" stroke-linecap="round"/>')
icon("rare_metals", "#24283a", '<path d="M14 62 L32 40 H64 L82 62 L64 80 H32 Z" fill="#9fb6d8" stroke="#e7fffb" stroke-width="4" stroke-linejoin="round"/><path d="M32 40 L40 24 H56 L64 40" fill="#c8d8f0" stroke="#e7fffb" stroke-width="3" stroke-linejoin="round"/><path d="M14 62 H82" stroke="#e7fffb" stroke-width="2"/>')
icon("heal", "#2a3d2c", '<path d="M40 20 H56 V40 H76 V56 H56 V76 H40 V56 H20 V40 H40 Z" fill="#6fe08a" stroke="#e7fffb" stroke-width="3" stroke-linejoin="round"/>')

# --- weapon lines (ages): projectiles, vehicles, tier icons ---------------
svg("arrow", 64, 16, '<path d="M4 8 H50" stroke="#c48a4a" stroke-width="4" stroke-linecap="round"/><path d="M48 2 L62 8 L48 14 Z" fill="#cfd3dc"/><path d="M4 8 L12 2 M4 8 L12 14" stroke="#e8ecf2" stroke-width="3"/>')
svg("bullet", 32, 16, '<path d="M2 3 H20 Q30 8 20 13 H2 Z" fill="#ffd36b" stroke="#a8742a" stroke-width="2"/><path d="M0 8 H-0" stroke="#fff"/>')
svg("shell", 40, 22, '<path d="M2 4 H24 Q38 11 24 18 H2 Z" fill="#8c93a6" stroke="#3a3f4c" stroke-width="2.5"/><rect x="2" y="4" width="6" height="14" fill="#c48a4a"/>')
svg("missile", 64, 24, '<path d="M8 6 H46 Q60 12 46 18 H8 Z" fill="#e8ecf2" stroke="#3a3f4c" stroke-width="2.5"/><path d="M8 6 L2 0 V24 L8 18 Z" fill="#e2553d"/><path d="M0 9 H-10" stroke="#ffb347" stroke-width="6"/><circle cx="4" cy="12" r="4" fill="#ffb347"/>')
svg("spark", 48, 48, '<circle cx="24" cy="24" r="20" fill="#ffd36b" opacity="0.35"/><path d="M24 4 L29 19 L44 24 L29 29 L24 44 L19 29 L4 24 L19 19 Z" fill="#fff3c4" stroke="#ffb347" stroke-width="2"/>')
svg("plasma", 52, 52, '<circle cx="26" cy="26" r="24" fill="#59d6c9" opacity="0.3"/><circle cx="26" cy="26" r="15" fill="#8ff0e6" stroke="#e7fffb" stroke-width="3"/><circle cx="21" cy="21" r="5" fill="#ffffff"/>')
svg("disc", 48, 48, '<circle cx="24" cy="24" r="20" fill="#9aa5b8" stroke="#e8ecf2" stroke-width="3"/><circle cx="24" cy="24" r="7" fill="#3a3f4c"/><path d="M24 4 L28 12 M44 24 L36 28 M24 44 L20 36 M4 24 L12 20" stroke="#fff" stroke-width="3"/>')
svg("pike", 96, 20, '<path d="M2 10 H70" stroke="#6b4a2b" stroke-width="6" stroke-linecap="round"/><path d="M66 2 L94 10 L66 18 Z" fill="#cfd3dc" stroke="#3a3f4c" stroke-width="2"/>')
svg("tank", 150, 90, '<ellipse cx="75" cy="84" rx="70" ry="6" fill="#000" opacity="0.3"/><rect x="10" y="56" width="130" height="26" rx="13" fill="#2f3326" stroke="#141a2e" stroke-width="3"/><circle cx="30" cy="69" r="8" fill="#6b705a"/><circle cx="56" cy="69" r="8" fill="#6b705a"/><circle cx="82" cy="69" r="8" fill="#6b705a"/><circle cx="108" cy="69" r="8" fill="#6b705a"/><circle cx="130" cy="69" r="7" fill="#6b705a"/><path d="M20 56 L30 34 H120 L132 56 Z" fill="#5a6a3a" stroke="#141a2e" stroke-width="3" stroke-linejoin="round"/><rect x="52" y="16" width="46" height="22" rx="6" fill="#6b7d45" stroke="#141a2e" stroke-width="3"/><rect x="96" y="22" width="52" height="9" rx="3" fill="#4a5a30" stroke="#141a2e" stroke-width="2.5"/><circle cx="66" cy="27" r="4" fill="#ffd36b"/>')
svg("jet", 160, 70, '<path d="M8 36 L120 28 Q154 34 156 36 Q154 38 120 44 Z" fill="#b8c2d6" stroke="#141a2e" stroke-width="3" stroke-linejoin="round"/><path d="M60 32 L96 4 H108 L88 34 Z" fill="#8c98b0" stroke="#141a2e" stroke-width="3" stroke-linejoin="round"/><path d="M60 40 L96 66 H108 L88 38 Z" fill="#8c98b0" stroke="#141a2e" stroke-width="3" stroke-linejoin="round"/><path d="M10 34 L2 18 H16 L28 34 Z" fill="#8c98b0" stroke="#141a2e" stroke-width="3"/><path d="M118 30 Q132 32 136 36 L118 38 Z" fill="#59d6c9"/><path d="M8 36 H-20" stroke="#ffb347" stroke-width="8" opacity="0.7"/>')

T = "#2e2a3e"
icon("t_bow", T, '<path d="M30 14 Q74 48 30 82" stroke="#c48a4a" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M30 14 V82" stroke="#e8ecf2" stroke-width="2"/><path d="M22 48 H82" stroke="#cfd3dc" stroke-width="4"/><path d="M76 42 L86 48 L76 54 Z" fill="#cfd3dc"/>')
icon("t_musket", T, '<path d="M12 62 L30 56 L84 30" stroke="#6b4a2b" stroke-width="10" stroke-linecap="round"/><path d="M40 51 L86 29" stroke="#8c93a6" stroke-width="5" stroke-linecap="round"/><circle cx="34" cy="60" r="4" fill="#ffd36b"/>')
icon("t_rifle", T, '<path d="M10 64 L32 58 L88 34" stroke="#4a3a2a" stroke-width="9" stroke-linecap="round"/><path d="M40 52 L90 30" stroke="#5b6478" stroke-width="5" stroke-linecap="round"/><rect x="44" y="40" width="18" height="6" fill="#2c3040" transform="rotate(-24 53 43)"/>')
icon("t_heavy_gun", T, '<rect x="20" y="40" width="52" height="18" rx="5" fill="#5b6478" stroke="#2c3040" stroke-width="3"/><path d="M70 44 H88 M70 49 H88 M70 54 H88" stroke="#8c93a6" stroke-width="3"/><path d="M30 58 L22 80 M52 58 L60 80" stroke="#3f2b1a" stroke-width="5" stroke-linecap="round"/><path d="M28 40 V30 H44" stroke="#ffd36b" stroke-width="4" fill="none"/>')
icon("t_tank", T, '<rect x="12" y="56" width="72" height="18" rx="9" fill="#2f3326"/><path d="M18 56 L26 42 H72 L80 56 Z" fill="#5a6a3a"/><rect x="36" y="30" width="26" height="14" rx="4" fill="#6b7d45"/><rect x="60" y="34" width="28" height="6" fill="#4a5a30"/>')
icon("t_jet", T, '<path d="M10 50 L70 44 Q90 48 90 50 Q90 52 70 56 Z" fill="#b8c2d6"/><path d="M40 46 L60 22 H68 L56 48 Z M40 54 L60 78 H68 L56 52 Z" fill="#8c98b0"/><path d="M12 48 L6 36 H14 L22 48 Z" fill="#8c98b0"/>')
icon("t_missiles", T, '<path d="M16 66 L66 30" stroke="#e8ecf2" stroke-width="9" stroke-linecap="round"/><path d="M62 26 L76 22 L72 36 Z" fill="#e2553d"/><path d="M30 78 L80 42" stroke="#e8ecf2" stroke-width="9" stroke-linecap="round"/><path d="M76 38 L90 34 L86 48 Z" fill="#e2553d"/><circle cx="14" cy="68" r="6" fill="#ffb347"/><circle cx="28" cy="80" r="6" fill="#ffb347"/>')
icon("t_cannon", T, '<path d="M18 62 L74 34" stroke="#3a3f4c" stroke-width="18" stroke-linecap="round"/><circle cx="34" cy="68" r="12" fill="#6b4a2b" stroke="#3f2b1a" stroke-width="3"/><circle cx="80" cy="30" r="5" fill="#ffb347"/>')
icon("t_torch", T, '<path d="M48 82 L42 44 H54 Z" fill="#6b4a2b"/><path d="M48 16 Q64 30 56 44 H40 Q32 30 48 16 Z" fill="#ffb347" stroke="#fff3c4" stroke-width="3"/>')
icon("t_lantern", T, '<path d="M36 26 H60 L66 70 H30 Z" fill="#fff3c4" opacity="0.85" stroke="#7a5230" stroke-width="4"/><circle cx="48" cy="50" r="9" fill="#ffb347"/><path d="M40 26 Q48 12 56 26" stroke="#7a5230" stroke-width="4" fill="none"/>')
icon("t_plasma", T, '<circle cx="48" cy="48" r="30" fill="none" stroke="#59d6c9" stroke-width="5" stroke-dasharray="10 6"/><circle cx="48" cy="48" r="14" fill="#8ff0e6" stroke="#e7fffb" stroke-width="3"/>')
icon("t_flail", T, '<path d="M18 78 L40 50" stroke="#6b4a2b" stroke-width="7" stroke-linecap="round"/><path d="M40 50 Q52 40 58 34" stroke="#cfd3dc" stroke-width="3" stroke-dasharray="4 3" fill="none"/><circle cx="64" cy="28" r="12" fill="#8c93a6"/><path d="M64 12 V18 M80 28 H74 M64 44 V38 M48 28 H54" stroke="#cfd3dc" stroke-width="4"/>')
icon("t_sabre", T, '<path d="M22 76 Q40 30 80 16" stroke="#e8ecf2" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M16 70 L32 82" stroke="#c48a4a" stroke-width="6" stroke-linecap="round"/>')
icon("t_hammer", T, '<path d="M30 80 L58 40" stroke="#6b4a2b" stroke-width="8" stroke-linecap="round"/><rect x="46" y="16" width="38" height="24" rx="4" fill="#5b6478" stroke="#2c3040" stroke-width="3" transform="rotate(34 65 28)"/><circle cx="70" cy="22" r="5" fill="#ffd36b"/>')
icon("t_disc", T, '<circle cx="48" cy="48" r="26" fill="#9aa5b8" stroke="#e8ecf2" stroke-width="4"/><circle cx="48" cy="48" r="9" fill="#2e2a3e"/>')
icon("t_pike", T, '<path d="M16 80 L70 26" stroke="#6b4a2b" stroke-width="7" stroke-linecap="round"/><path d="M64 20 L84 12 L76 32 Z" fill="#cfd3dc" stroke="#3a3f4c" stroke-width="2"/>')


# --- app icon --------------------------------------------------------------
with open(os.path.join(ROOT, "..", "..", "icon.svg"), "w", encoding="utf-8", newline="\n") as f:
    f.write('''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<rect width="512" height="512" fill="#101831"/>
<circle cx="256" cy="330" r="230" fill="#1b2a4f"/>
<circle cx="256" cy="250" r="150" fill="#ff8a2a" opacity="0.25"/>
<path d="M60 512 Q80 330 150 360 Q170 300 230 330 L230 512 Z" fill="#0c312b"/>
<path d="M452 512 Q432 330 362 360 Q342 300 282 330 L282 512 Z" fill="#0c312b"/>
<rect x="240" y="300" width="32" height="212" fill="#4a3a2a"/>
<rect x="196" y="170" width="120" height="140" rx="22" fill="#ffd36b" stroke="#7a5230" stroke-width="14"/>
<path d="M256 196 Q292 236 276 268 Q264 290 256 286 Q248 290 236 268 Q220 236 256 196 Z" fill="#ff8a2a"/>
<path d="M186 172 L256 110 L326 172 Z" fill="#7a5230"/>
</svg>
''')
print("art written")
