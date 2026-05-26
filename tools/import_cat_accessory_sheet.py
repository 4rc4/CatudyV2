from __future__ import annotations

import argparse
import math
from collections import deque
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "cat_accessories" / "wearables"
TRIMMED_DIR = OUT_ROOT / "trimmed"
ALIGNED_DIR = OUT_ROOT / "aligned"
PREVIEW_TRIMMED = OUT_ROOT / "wearables_preview.png"
PREVIEW_ON_CAT = OUT_ROOT / "wearables_on_purple_cat_preview.png"
MASCOT_PATH = ROOT / "assets" / "brand" / "catudy-mascot.png"
CAT_CANVAS_SIZE = (311, 466)
ACCESSORY_TOP_OVERFLOW = 180
GLOBAL_ACCESSORY_SCALE = 1.42
CANVAS_SIZE = (CAT_CANVAS_SIZE[0], CAT_CANVAS_SIZE[1] + ACCESSORY_TOP_OVERFLOW)
FACE_CENTER_X = 140
RIGHT_EYE_X = 205
LEFT_EAR_DECOR_X = 75
RIGHT_EAR_DECOR_X = 207
REMOVED_FROM_GAME = {
    "green_army_helmet",
    "aviator_helmet",
    "astronaut_helmet",
    "pink_earmuffs",
    "blue_headphones",
    "chef_hat",
    "star_wizard_hat",
}
DEFAULT_SOURCES = {
    "main": Path(r"C:\Users\arca\Desktop\Untitled - May 24, 2026 at 18.51.47.png"),
    "extra": Path(r"C:\Users\arca\Desktop\Aksesuars.png"),
}


@dataclass(frozen=True)
class ItemSpec:
    item_id: str
    source_key: str
    target_anchor: tuple[int, int]
    target_width: int
    source_anchor: tuple[float, float] = (0.5, 0.5)


ITEMS = [
    ItemSpec("purple_witch_hat", "main", (FACE_CENTER_X, 88), 245, (0.5, 0.93)),
    ItemSpec("pink_flower_clip", "main", (RIGHT_EAR_DECOR_X + 4, 74), 82),
    ItemSpec("gold_halo", "main", (FACE_CENTER_X, 2), 146, (0.5, 0.82)),
    ItemSpec(
        "silver_viking_helmet", "main", (FACE_CENTER_X, 60), 218, (0.5, 0.82)
    ),
    ItemSpec("blue_backwards_cap", "main", (FACE_CENTER_X, 101), 182, (0.5, 0.82)),
    ItemSpec("gold_monocle", "main", (RIGHT_EYE_X, 156), 92),
    ItemSpec("green_bow_tie", "main", (FACE_CENTER_X, 222), 105),
    ItemSpec("black_top_hat", "main", (FACE_CENTER_X, 75), 160, (0.5, 0.88)),
    ItemSpec("purple_eye_mask", "main", (FACE_CENTER_X, 145), 160),
    ItemSpec("pineapple_hat", "main", (FACE_CENTER_X, 70), 132, (0.5, 0.92)),
    ItemSpec("black_sunglasses", "main", (FACE_CENTER_X, 145), 180),
    ItemSpec("yellow_sun_hat", "main", (FACE_CENTER_X, 102), 208, (0.5, 0.82)),
    ItemSpec("red_white_headband", "main", (FACE_CENTER_X, 95), 158),
    ItemSpec("brown_aviator_cap", "main", (FACE_CENTER_X, 188), 178, (0.5, 0.94)),
    ItemSpec("pink_bow", "main", (104, 80), 168),
    ItemSpec("detective_cap", "main", (FACE_CENTER_X, 76), 165, (0.5, 0.86)),
    ItemSpec("red_cat_eye_glasses", "main", (FACE_CENTER_X, 145), 155),
    ItemSpec("sailor_hat", "main", (FACE_CENTER_X, 145), 145),
    ItemSpec("gold_tiara", "main", (FACE_CENTER_X, 95), 140, (0.5, 0.86)),
    ItemSpec("blue_party_hat", "main", (FACE_CENTER_X, 100), 110, (0.5, 0.95)),
    ItemSpec("black_ninja_headband", "main", (FACE_CENTER_X, 145), 170),
    ItemSpec("green_shutter_glasses", "main", (FACE_CENTER_X, 145), 158),
    ItemSpec("cowboy_hat", "main", (FACE_CENTER_X, 70), 182, (0.5, 0.86)),
    ItemSpec("graduation_cap", "main", (FACE_CENTER_X, 81), 162, (0.5, 0.82)),
    ItemSpec("gold_monocle_chain", "extra", (RIGHT_EYE_X - 7, 168), 92),
    ItemSpec("black_mustache", "extra", (FACE_CENTER_X, 177), 135, (0.5, 0.25)),
    ItemSpec("brown_mustache", "extra", (FACE_CENTER_X, 177), 135, (0.5, 0.25)),
    ItemSpec("gray_mustache", "extra", (FACE_CENTER_X, 177), 140, (0.5, 0.25)),
    ItemSpec("white_beard", "extra", (FACE_CENTER_X, 183), 140, (0.5, 0.12)),
    ItemSpec("black_beard", "extra", (FACE_CENTER_X, 184), 142, (0.5, 0.12)),
    ItemSpec("red_clown_nose", "extra", (FACE_CENTER_X, 171), 52),
    ItemSpec("groucho_glasses", "extra", (FACE_CENTER_X, 165), 168),
    ItemSpec("pixel_sunglasses", "extra", (FACE_CENTER_X, 160), 190),
    ItemSpec("red_shutter_glasses", "extra", (FACE_CENTER_X, 144), 174),
    ItemSpec("heart_sunglasses", "extra", (FACE_CENTER_X, 146), 172),
    ItemSpec("yellow_star_sunglasses", "extra", (FACE_CENTER_X, 145), 166),
    ItemSpec("pink_round_glasses", "extra", (FACE_CENTER_X, 145), 152),
    ItemSpec("rainbow_ski_goggles", "extra", (FACE_CENTER_X, 145), 170),
    ItemSpec("pink_tiara", "extra", (FACE_CENTER_X, 95), 142, (0.5, 0.86)),
    ItemSpec("knight_helmet", "extra", (FACE_CENTER_X, 166), 190, (0.5, 0.86)),
    ItemSpec("fur_viking_helmet", "extra", (FACE_CENTER_X, 119), 200, (0.5, 0.82)),
    ItemSpec("green_army_helmet", "extra", (FACE_CENTER_X, 122), 160, (0.5, 0.88)),
    ItemSpec("aviator_helmet", "extra", (FACE_CENTER_X, 188), 188, (0.5, 0.94)),
    ItemSpec("astronaut_helmet", "extra", (FACE_CENTER_X, 214), 198, (0.5, 0.86)),
    ItemSpec("pink_earmuffs", "extra", (FACE_CENTER_X, 112), 198),
    ItemSpec("blue_headphones", "extra", (FACE_CENTER_X, 114), 200),
    ItemSpec("chef_hat", "extra", (FACE_CENTER_X, 100), 150, (0.5, 0.88)),
    ItemSpec("star_wizard_hat", "extra", (FACE_CENTER_X, 74), 170, (0.5, 0.91)),
    ItemSpec("classic_top_hat", "extra", (FACE_CENTER_X, 75), 160, (0.5, 0.88)),
    ItemSpec("flower_crown", "extra", (FACE_CENTER_X, 62), 210, (0.5, 0.86)),
    ItemSpec("hibiscus_flower", "extra", (RIGHT_EAR_DECOR_X + 5, 64), 92),
    ItemSpec("left_leaf_clip", "extra", (FACE_CENTER_X - 61, 72), 80),
    ItemSpec("right_leaf_clip", "extra", (FACE_CENTER_X + 61, 72), 80),
    ItemSpec("thin_gold_halo", "extra", (FACE_CENTER_X, 2), 146, (0.5, 0.82)),
    ItemSpec("rainbow_party_hat", "extra", (FACE_CENTER_X, 100), 110, (0.5, 0.95)),
]


def connected_components(mask: np.ndarray) -> list[np.ndarray]:
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    components: list[np.ndarray] = []
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
                continue
            comp = np.zeros_like(mask, dtype=bool)
            queue: deque[tuple[int, int]] = deque([(y, x)])
            seen[y, x] = True
            while queue:
                cy, cx = queue.popleft()
                comp[cy, cx] = True
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dy == 0 and dx == 0:
                            continue
                        ny = cy + dy
                        nx = cx + dx
                        if (
                            0 <= ny < h
                            and 0 <= nx < w
                            and mask[ny, nx]
                            and not seen[ny, nx]
                        ):
                            seen[ny, nx] = True
                            queue.append((ny, nx))
            components.append(comp)
    return components


def component_bounds(component: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.where(component)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def component_center(component: np.ndarray) -> tuple[float, float]:
    ys, xs = np.where(component)
    return float(xs.mean()), float(ys.mean())


def ordered_components(source: Image.Image) -> list[np.ndarray]:
    alpha = np.array(source.convert("RGBA"))[:, :, 3]
    components = [
        comp
        for comp in connected_components(alpha > 8)
        if int(comp.sum()) >= 400
    ]
    components = [
        comp
        for comp in components
        if (component_bounds(comp)[2] - component_bounds(comp)[0]) >= 16
        and (component_bounds(comp)[3] - component_bounds(comp)[1]) >= 16
    ]

    rows: list[list[np.ndarray]] = []
    for comp in sorted(components, key=lambda item: component_center(item)[1]):
        _, cy = component_center(comp)
        row = next(
            (
                current
                for current in rows
                if abs(cy - row_center(current)) < 90
            ),
            None,
        )
        if row is None:
            rows.append([comp])
        else:
            row.append(comp)

    rows.sort(key=row_center)
    ordered: list[np.ndarray] = []
    for row in rows:
        ordered.extend(sorted(row, key=lambda item: component_center(item)[0]))
    return ordered


def row_center(row: list[np.ndarray]) -> float:
    return sum(component_center(comp)[1] for comp in row) / len(row)


def trim_to_mask(source: Image.Image, mask: np.ndarray, pad: int = 8) -> Image.Image:
    left, top, right, bottom = component_bounds(mask)
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(source.width, right + pad)
    bottom = min(source.height, bottom + pad)
    crop = np.array(source.crop((left, top, right, bottom)).convert("RGBA"))
    crop_mask = mask[top:bottom, left:right]
    crop[:, :, 3] = np.where(crop_mask, crop[:, :, 3], 0).astype(np.uint8)
    return Image.fromarray(crop, "RGBA")


def alpha_composite_clipped(
    canvas: Image.Image,
    overlay: Image.Image,
    position: tuple[int, int],
) -> None:
    x, y = position
    left = max(0, x)
    top = max(0, y)
    right = min(canvas.width, x + overlay.width)
    bottom = min(canvas.height, y + overlay.height)
    if right <= left or bottom <= top:
        return
    crop = overlay.crop((left - x, top - y, right - x, bottom - y))
    canvas.alpha_composite(crop, (left, top))


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.convert("RGBA").getbbox()


def trim_alpha(image: Image.Image, pad: int = 0) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = alpha_bbox(rgba)
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    left, top, right, bottom = bbox
    return rgba.crop(
        (
            max(0, left - pad),
            max(0, top - pad),
            min(rgba.width, right + pad),
            min(rgba.height, bottom + pad),
        ),
    )


def soften_astronaut_visor(image: Image.Image) -> Image.Image:
    rgba = np.array(image.convert("RGBA"))
    h, w = rgba.shape[:2]
    yy, xx = np.ogrid[:h, :w]
    cx = w * 0.5
    cy = h * 0.45
    rx = w * 0.39
    ry = h * 0.32
    inner_visor = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 < 0.9
    alpha = rgba[:, :, 3]
    luminance = (
        rgba[:, :, 0].astype(np.float32) * 0.299
        + rgba[:, :, 1].astype(np.float32) * 0.587
        + rgba[:, :, 2].astype(np.float32) * 0.114
    )
    visor_pixels = inner_visor & (alpha > 20) & (luminance < 245)
    softened_alpha = np.clip(34 + luminance * 0.18, 34, 82).astype(np.uint8)
    alpha[visor_pixels] = np.minimum(alpha[visor_pixels], softened_alpha[visor_pixels])
    return Image.fromarray(rgba, "RGBA")


def draw_scaled_polyline(
    canvas: Image.Image,
    points: list[tuple[int, int]],
    *,
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    scale = 3
    overlay = Image.new("RGBA", (canvas.width * scale, canvas.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    scaled = [(x * scale, y * scale) for x, y in points]
    draw.line(scaled, fill=fill, width=width * scale, joint="curve")
    overlay = overlay.resize(canvas.size, Image.Resampling.LANCZOS)
    canvas.alpha_composite(overlay)


def place_scaled(
    canvas: Image.Image,
    image: Image.Image,
    *,
    target_width: int,
    target_anchor: tuple[int, int],
    source_anchor: tuple[float, float] = (0.5, 0.5),
) -> None:
    if image.width <= 1 or image.height <= 1:
        return
    scale = (target_width * GLOBAL_ACCESSORY_SCALE) / image.width
    resized = image.resize(
        (
            max(1, int(round(image.width * scale))),
            max(1, int(round(image.height * scale))),
        ),
        Image.Resampling.LANCZOS,
    )
    x = int(round(target_anchor[0] - resized.width * source_anchor[0]))
    y = int(round(target_anchor[1] - resized.height * source_anchor[1]))
    alpha_composite_clipped(canvas, resized, (x, y))


def align_sailor_asset(trimmed: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    hat = trim_alpha(trimmed.crop((0, 0, trimmed.width, 112)))
    scarf = trim_alpha(trimmed.crop((0, 94, trimmed.width, trimmed.height)))
    place_scaled(
        canvas,
        hat,
        target_width=160,
        target_anchor=(FACE_CENTER_X, 114 + ACCESSORY_TOP_OVERFLOW),
        source_anchor=(0.5, 0.86),
    )
    place_scaled(
        canvas,
        scarf,
        target_width=110,
        target_anchor=(FACE_CENTER_X, 252 + ACCESSORY_TOP_OVERFLOW),
    )
    return canvas


def align_pink_bow_asset(trimmed: Image.Image, spec: ItemSpec) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    y_offset = ACCESSORY_TOP_OVERFLOW
    draw_scaled_polyline(
        canvas,
        [
            (42, y_offset + 128),
            (55, y_offset + 114),
            (75, y_offset + 99),
            (101, y_offset + 89),
            (130, y_offset + 85),
        ],
        fill=(183, 66, 109, 210),
        width=16,
    )
    draw_scaled_polyline(
        canvas,
        [
            (43, y_offset + 126),
            (57, y_offset + 112),
            (78, y_offset + 99),
            (103, y_offset + 91),
            (130, y_offset + 88),
        ],
        fill=(245, 115, 160, 245),
        width=10,
    )
    place_scaled(
        canvas,
        trimmed,
        target_width=spec.target_width,
        target_anchor=(
            spec.target_anchor[0],
            spec.target_anchor[1] + ACCESSORY_TOP_OVERFLOW,
        ),
        source_anchor=spec.source_anchor,
    )
    return canvas


def align_asset(trimmed: Image.Image, spec: ItemSpec) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    if spec.item_id == "sailor_hat":
        return align_sailor_asset(trimmed)
    if spec.item_id == "pink_bow":
        return align_pink_bow_asset(trimmed, spec)
    if trimmed.width <= 1 or trimmed.height <= 1:
        return canvas
    source = soften_astronaut_visor(trimmed) if spec.item_id == "astronaut_helmet" else trimmed
    place_scaled(
        canvas,
        source,
        target_width=spec.target_width,
        target_anchor=(
            spec.target_anchor[0],
            spec.target_anchor[1] + ACCESSORY_TOP_OVERFLOW,
        ),
        source_anchor=spec.source_anchor,
    )
    return canvas


def checker(size: tuple[int, int], cell: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (255, 255, 255, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle(
                    (x, y, x + cell - 1, y + cell - 1),
                    fill=(222, 222, 222, 255),
                )
    return image


def make_preview(paths: list[Path], output: Path) -> None:
    tile = 176
    label_h = 30
    cols = 5
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (cols * tile, rows * tile), (245, 245, 245, 255))
    for index, path in enumerate(paths):
        asset = Image.open(path).convert("RGBA")
        scale = min(
            (tile - 22) / asset.width,
            (tile - label_h - 18) / asset.height,
            1,
        )
        asset = asset.resize(
            (max(1, round(asset.width * scale)), max(1, round(asset.height * scale))),
            Image.Resampling.LANCZOS,
        )
        tile_img = checker((tile, tile))
        tile_img.alpha_composite(
            asset,
            ((tile - asset.width) // 2, (tile - label_h - asset.height) // 2),
        )
        draw = ImageDraw.Draw(tile_img)
        draw.rectangle((0, tile - label_h, tile, tile), fill=(28, 28, 32, 255))
        draw.text(
            (7, tile - label_h + 8),
            path.stem.replace("_", " ")[:25],
            fill=(255, 255, 255, 255),
        )
        sheet.alpha_composite(
            tile_img,
            ((index % cols) * tile, (index // cols) * tile),
        )
    sheet.save(output)


def make_on_cat_preview(paths: list[Path]) -> None:
    mascot = Image.open(MASCOT_PATH).convert("RGBA").resize(
        CAT_CANVAS_SIZE,
        Image.Resampling.LANCZOS,
    )
    tile = 190
    cols = 5
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (cols * tile, rows * tile), (255, 255, 255, 255))
    for index, path in enumerate(paths):
        cat = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        cat.alpha_composite(mascot, (0, ACCESSORY_TOP_OVERFLOW))
        cat.alpha_composite(Image.open(path).convert("RGBA"))
        cat = cat.resize(
            (round(CANVAS_SIZE[0] * 0.28), round(CANVAS_SIZE[1] * 0.28)),
            Image.Resampling.LANCZOS,
        )
        tile_img = Image.new("RGBA", (tile, tile), (255, 255, 255, 255))
        tile_img.alpha_composite(cat, ((tile - cat.width) // 2, 5))
        sheet.alpha_composite(
            tile_img,
            ((index % cols) * tile, (index // cols) * tile),
        )
    sheet.save(PREVIEW_ON_CAT)


def clean_outputs() -> None:
    TRIMMED_DIR.mkdir(parents=True, exist_ok=True)
    ALIGNED_DIR.mkdir(parents=True, exist_ok=True)
    for directory in (TRIMMED_DIR, ALIGNED_DIR):
        for path in directory.glob("*.png"):
            path.unlink()
    for path in (PREVIEW_TRIMMED, PREVIEW_ON_CAT):
        if path.exists():
            path.unlink()


def import_sources(sources: dict[str, Path]) -> None:
    clean_outputs()
    grouped = {key: [item for item in ITEMS if item.source_key == key] for key in sources}
    trimmed_paths: list[Path] = []
    aligned_paths: list[Path] = []

    for source_key, source_path in sources.items():
        source = Image.open(source_path).convert("RGBA")
        components = ordered_components(source)
        specs = grouped[source_key]
        if len(components) != len(specs):
            raise ValueError(
                f"{source_path} produced {len(components)} components, "
                f"but {len(specs)} item specs were expected."
            )
        for spec, component in zip(specs, components):
            if spec.item_id in REMOVED_FROM_GAME:
                continue
            trimmed = trim_to_mask(source, component)
            aligned = align_asset(trimmed, spec)
            trimmed_path = TRIMMED_DIR / f"{spec.item_id}.png"
            aligned_path = ALIGNED_DIR / f"{spec.item_id}.png"
            trimmed.save(trimmed_path)
            aligned.save(aligned_path)
            trimmed_paths.append(trimmed_path)
            aligned_paths.append(aligned_path)

    make_preview(trimmed_paths, PREVIEW_TRIMMED)
    make_on_cat_preview(aligned_paths)
    print(f"Wrote {len(trimmed_paths)} trimmed assets to {TRIMMED_DIR}")
    print(f"Wrote {len(aligned_paths)} aligned assets to {ALIGNED_DIR}")
    print(f"Wrote previews to {PREVIEW_TRIMMED} and {PREVIEW_ON_CAT}")


def parse_sources(values: list[str]) -> dict[str, Path]:
    if not values:
        return DEFAULT_SOURCES
    if len(values) != 2:
        raise ValueError("Pass exactly two sources: main and extra.")
    return {
        "main": Path(values[0]),
        "extra": Path(values[1]),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Catudy pet accessories.")
    parser.add_argument(
        "sources",
        nargs="*",
        help="Optional source PNGs in order: main extra.",
    )
    args = parser.parse_args()
    import_sources(parse_sources(args.sources))


if __name__ == "__main__":
    main()
