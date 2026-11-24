"""YouTube thumbnail (1280x720) for the store preview video.

Built from frames of the recorded trailer (run tools/make_trailer.ps1 first),
so it always matches the game's current look. Needs Pillow.

    python tools/make_thumbnail.py [build/trailer/kavaryn_trailer.avi]

Writes docs/store/graphics/youtube_thumbnail.jpg (16:9, regular videos) and
youtube_thumbnail_vertical.jpg (9:16, Shorts). YouTube limit: 2 MB each.
"""
import io
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
AVI = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build/trailer/kavaryn_trailer.avi"
OUT = ROOT / "docs/store/graphics/youtube_thumbnail.jpg"
OUT_VERTICAL = ROOT / "docs/store/graphics/youtube_thumbnail_vertical.jpg"
FONT = ROOT / "assets/fonts/Fredoka.ttf"
FPS = 30
SIZE = (1280, 720)
BG = (14, 19, 38)          # UiKit.BG
GOLD = (255, 211, 107)     # UiKit.GOLD
AMBER = (255, 179, 71)     # UiKit.AMBER
INK = (5, 8, 20)
# Trailer moments (seconds): see the timeline in tools/trailer_director.gd.
BOSS_AT = 20.4
STRIKES_AT = 38.5
END_CARD_AT = 43.5


def frames(path: Path) -> list[bytes]:
    """JPEG frames of a Godot Movie Maker AVI (MJPEG, one '00db' chunk per frame)."""
    data = path.read_bytes()
    out, i = [], 0
    while (i := data.find(b"00db", i)) >= 0:
        size = int.from_bytes(data[i + 4:i + 8], "little")
        chunk = data[i + 8:i + 8 + size]
        if chunk[:2] == b"\xff\xd8":
            out.append(chunk)
        i += 8 + size
    return out


def frame_at(all_frames: list[bytes], seconds: float) -> Image.Image:
    return Image.open(io.BytesIO(all_frames[int(seconds * FPS)])).convert("RGB")


def font(size: int, weight: int = 700) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([weight])
    except OSError:
        pass  # static font build: keep its own weight
    return f


def phone(shot: Image.Image, height: int, angle: float) -> Image.Image:
    """A gameplay shot as a rounded, gold-framed phone screen, slightly tilted."""
    shot = shot.resize((round(shot.width * height / shot.height), height), Image.LANCZOS)
    border, radius = 8, 34
    card = Image.new("RGBA", (shot.width + 2 * border, shot.height + 2 * border), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([0, 0, card.width - 1, card.height - 1], radius + border, fill=GOLD)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width - 1, shot.height - 1], radius, fill=255)
    card.paste(shot, (border, border), mask)
    return card.rotate(angle, resample=Image.BICUBIC, expand=True)


def shadowed(canvas: Image.Image, layer: Image.Image, pos: tuple[int, int]) -> None:
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    shadow.putalpha(layer.getchannel("A").point(lambda a: a * 0.6))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)), (pos[0] + 10, pos[1] + 14))
    canvas.alpha_composite(layer, pos)


def hero_cutout(end_card: Image.Image) -> Image.Image:
    """The hero from the end card. The card's background (with its soft
    vignette) is flood-filled away from the corners, so the hero's own dark
    outline and colours stay."""
    crop = end_card.crop((300, 400, 820, 960))
    key = (255, 0, 255)
    for corner in ((0, 0), (crop.width - 1, 0), (0, crop.height - 1), (crop.width - 1, crop.height - 1)):
        ImageDraw.floodfill(crop, corner, key, thresh=44)
    rgba = crop.convert("RGBA")
    magenta = Image.new("L", crop.size, 0)
    magenta.putdata([255 if px == key else 0 for px in crop.get_flattened_data()])
    rgba.putalpha(Image.eval(magenta, lambda m: 255 - m))
    return rgba.crop(rgba.getbbox())


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], s: str, f: ImageFont.FreeTypeFont, fill, stroke: int) -> None:
    draw.text(xy, s, font=f, fill=fill, stroke_width=stroke, stroke_fill=INK)


def glow_at(canvas: Image.Image, box: list[int]) -> None:
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(box, fill=(255, 190, 90, 90))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))


def centered(draw: ImageDraw.ImageDraw, width: int, y: int, s: str, f: ImageFont.FreeTypeFont, fill, stroke: int) -> None:
    w = draw.textlength(s, font=f)
    text(draw, (round((width - w) / 2), y), s, f, fill, stroke)


def landscape(boss: Image.Image, strikes: Image.Image, hero: Image.Image) -> Image.Image:
    """16:9 for regular videos."""
    # Background: the swarm, blurred and darkened so the title reads.
    bg = strikes.crop((0, 380, 1080, 988)).resize(SIZE, Image.LANCZOS).filter(ImageFilter.GaussianBlur(7))
    canvas = Image.blend(bg, Image.new("RGB", SIZE, BG), 0.55).convert("RGBA")
    glow_at(canvas, [60, 330, 520, 760])
    # Two phones on the right: a boss fight and a late-age air strike (captions cropped off).
    shadowed(canvas, phone(boss.crop((0, 0, 1080, 1500)), 590, 5), (640, 95))
    shadowed(canvas, phone(strikes.crop((0, 0, 1080, 1500)), 640, -6), (930, 30))
    shadowed(canvas, hero.resize((round(hero.width * 330 / hero.height), 330), Image.LANCZOS), (150, 370))
    draw = ImageDraw.Draw(canvas)
    text(draw, (44, 22), "Kavaryn", font(132, 700), GOLD, 9)
    text(draw, (50, 184), "Guardians of Dawn", font(54, 600), AMBER, 6)
    text(draw, (52, 262), "Survive the night!", font(44, 600), (240, 242, 255), 6)
    return canvas


def portrait(boss: Image.Image, strikes: Image.Image, hero: Image.Image) -> Image.Image:
    """9:16 for Shorts: YouTube files a vertical video under 3 minutes as a
    Short and crops a 16:9 thumbnail down to its middle strip."""
    size = (SIZE[1] * 3 // 2, SIZE[0] * 3 // 2)  # 1080x1920
    # Background from above the trailer's caption box, so no blurred caption shows through.
    bg = strikes.crop((0, 0, 1080, 1500)).resize(size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(9))
    canvas = Image.blend(bg, Image.new("RGB", size, BG), 0.55).convert("RGBA")
    glow_at(canvas, [190, 1380, 890, 1940])
    shadowed(canvas, phone(boss.crop((0, 0, 1080, 1500)), 860, 6), (20, 560))
    shadowed(canvas, phone(strikes.crop((0, 0, 1080, 1500)), 900, -6), (440, 500))
    hero = hero.resize((round(hero.width * 470 / hero.height), 470), Image.LANCZOS)
    shadowed(canvas, hero, ((size[0] - hero.width) // 2, 1420))
    draw = ImageDraw.Draw(canvas)
    centered(draw, size[0], 70, "Kavaryn", font(220, 700), GOLD, 12)
    centered(draw, size[0], 330, "Guardians of Dawn", font(88, 600), AMBER, 8)
    centered(draw, size[0], 445, "Survive the night!", font(64, 600), (240, 242, 255), 7)
    return canvas


def save(canvas: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(path, "JPEG", quality=92, optimize=True)
    print(f"{path} ({path.stat().st_size // 1024} KB)")


def main() -> None:
    all_frames = frames(AVI)
    boss, strikes, end_card = (frame_at(all_frames, t) for t in (BOSS_AT, STRIKES_AT, END_CARD_AT))
    hero = hero_cutout(end_card)
    save(landscape(boss, strikes, hero), OUT)
    save(portrait(boss, strikes, hero), OUT_VERTICAL)


if __name__ == "__main__":
    main()
