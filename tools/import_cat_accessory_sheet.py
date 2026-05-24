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
CANVAS_SIZE = (311, 466)


@dataclass(frozen=True)
class ItemSpec:
    item_id: str
    row: int
    col: int
    target_center: tuple[int, int]
    target_width: int


ITEMS = [
    ItemSpec("propeller_cap", 1, 1, (128, 62), 180),
    ItemSpec("gold_crown", 1, 2, (155, 63), 150),
    ItemSpec("cowboy_hat", 1, 3, (155, 70), 195),
    ItemSpec("dinosaur_hood", 1, 4, (155, 75), 220),
    ItemSpec("backwards_blue_cap", 1, 5, (155, 61), 190),
    ItemSpec("pixel_sunglasses", 2, 1, (155, 135), 210),
    ItemSpec("heart_sunglasses", 2, 2, (155, 140), 190),
    ItemSpec("round_glasses", 2, 3, (155, 137), 160),
    ItemSpec("black_aviator_sunglasses", 2, 4, (155, 137), 170),
    ItemSpec("yellow_star_sunglasses", 2, 5, (155, 139), 190),
    ItemSpec("red_headband_side_tie", 3, 1, (145, 92), 270),
    ItemSpec("black_eye_mask", 3, 2, (155, 138), 190),
    ItemSpec("red_headband_x", 3, 3, (155, 95), 170),
    ItemSpec("black_mustache", 3, 4, (155, 188), 120),
    ItemSpec("green_sleep_mask", 3, 5, (155, 139), 185),
    ItemSpec("garlic_hat", 4, 1, (155, 70), 160),
    ItemSpec("banana_hat", 4, 2, (155, 86), 170),
    ItemSpec("apple_hat", 4, 3, (155, 75), 170),
    ItemSpec("brown_mustache", 4, 4, (155, 188), 120),
    ItemSpec("chick_hat", 4, 5, (155, 78), 170),
    ItemSpec("headphones", 5, 1, (155, 112), 275),
    ItemSpec("pink_bow", 5, 2, (210, 72), 120),
    ItemSpec("party_hat", 5, 3, (155, 64), 95),
    ItemSpec("top_hat", 5, 4, (155, 54), 125),
    ItemSpec("blue_bucket_hat", 5, 5, (155, 70), 200),
]

ROW_CENTERS = [0.16, 0.32, 0.46, 0.64, 0.86]
COL_CENTERS = [0.10, 0.30, 0.50, 0.70, 0.90]


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
                        if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((ny, nx))
            components.append(comp)
    return components


def flood_background(dark: np.ndarray) -> np.ndarray:
    h, w = dark.shape
    bg = np.zeros_like(dark, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if dark[y, x] and not bg[y, x]:
                bg[y, x] = True
                queue.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if dark[y, x] and not bg[y, x]:
                bg[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny = y + dy
            nx = x + dx
            if 0 <= ny < h and 0 <= nx < w and dark[ny, nx] and not bg[ny, nx]:
                bg[ny, nx] = True
                queue.append((ny, nx))
    return bg


def content_mask(rgba: np.ndarray) -> np.ndarray:
    alpha = rgba[:, :, 3]
    if int(alpha.min()) < 245:
        return alpha > 12

    rgb = rgba[:, :, :3]
    dark = rgb.max(axis=2) < 18
    bg = flood_background(dark)
    return ~bg


def nearest_cell(cx: float, cy: float, width: int, height: int) -> tuple[int, int]:
    col = min(range(5), key=lambda i: abs(cx / width - COL_CENTERS[i])) + 1
    row = min(range(5), key=lambda i: abs(cy / height - ROW_CENTERS[i])) + 1
    return row, col


def build_item_masks(mask: np.ndarray) -> dict[str, np.ndarray]:
    h, w = mask.shape
    item_by_cell = {(item.row, item.col): item for item in ITEMS}
    result = {item.item_id: np.zeros_like(mask, dtype=bool) for item in ITEMS}
    for comp in connected_components(mask):
        area = int(comp.sum())
        if area < 45:
            continue
        ys, xs = np.where(comp)
        if len(xs) == 0:
            continue
        if xs.max() - xs.min() < 3 or ys.max() - ys.min() < 3:
            continue
        row, col = nearest_cell(float(xs.mean()), float(ys.mean()), w, h)
        item = item_by_cell.get((row, col))
        if item is not None:
            result[item.item_id] |= comp
    return result


def trim_to_mask(source: Image.Image, mask: np.ndarray, pad: int = 6) -> Image.Image:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    left = max(0, int(xs.min()) - pad)
    top = max(0, int(ys.min()) - pad)
    right = min(source.width, int(xs.max()) + pad + 1)
    bottom = min(source.height, int(ys.max()) + pad + 1)
    crop = np.array(source.crop((left, top, right, bottom)).convert("RGBA"))
    crop_mask = mask[top:bottom, left:right]
    crop[:, :, 3] = np.where(crop_mask, crop[:, :, 3], 0).astype(np.uint8)
    return Image.fromarray(crop, "RGBA")


def align_asset(trimmed: Image.Image, spec: ItemSpec) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    if trimmed.width <= 1 or trimmed.height <= 1:
        return canvas
    scale = spec.target_width / trimmed.width
    target_size = (
        max(1, int(round(trimmed.width * scale))),
        max(1, int(round(trimmed.height * scale))),
    )
    resized = trimmed.resize(target_size, Image.Resampling.LANCZOS)
    x = int(round(spec.target_center[0] - resized.width / 2))
    y = int(round(spec.target_center[1] - resized.height / 2))
    canvas.alpha_composite(resized, (x, y))
    return canvas


def checker(size: tuple[int, int], cell: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (255, 255, 255, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(220, 220, 220, 255))
    return image


def make_preview(paths: list[Path], output: Path) -> None:
    tile = 176
    label_h = 30
    cols = 5
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (cols * tile, rows * tile), (245, 245, 245, 255))
    for index, path in enumerate(paths):
        asset = Image.open(path).convert("RGBA")
        scale = min((tile - 22) / asset.width, (tile - label_h - 18) / asset.height, 1)
        asset = asset.resize(
            (max(1, round(asset.width * scale)), max(1, round(asset.height * scale))),
            Image.Resampling.LANCZOS,
        )
        tile_img = checker((tile, tile))
        tile_img.alpha_composite(asset, ((tile - asset.width) // 2, (tile - label_h - asset.height) // 2))
        draw = ImageDraw.Draw(tile_img)
        draw.rectangle((0, tile - label_h, tile, tile), fill=(28, 28, 32, 255))
        draw.text((7, tile - label_h + 8), path.stem.replace("_", " ")[:25], fill=(255, 255, 255, 255))
        sheet.alpha_composite(tile_img, ((index % cols) * tile, (index // cols) * tile))
    sheet.save(output)


def make_on_cat_preview(paths: list[Path]) -> None:
    mascot = Image.open(MASCOT_PATH).convert("RGBA").resize(CANVAS_SIZE, Image.Resampling.LANCZOS)
    tile = 164
    cols = 5
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (cols * tile, rows * tile), (255, 255, 255, 255))
    for index, path in enumerate(paths):
        cat = mascot.copy()
        cat.alpha_composite(Image.open(path).convert("RGBA"))
        cat = cat.resize((round(CANVAS_SIZE[0] * 0.32), round(CANVAS_SIZE[1] * 0.32)), Image.Resampling.LANCZOS)
        tile_img = Image.new("RGBA", (tile, tile), (255, 255, 255, 255))
        tile_img.alpha_composite(cat, ((tile - cat.width) // 2, 5))
        sheet.alpha_composite(tile_img, ((index % cols) * tile, (index // cols) * tile))
    sheet.save(PREVIEW_ON_CAT)


def import_sheet(source_path: Path) -> None:
    TRIMMED_DIR.mkdir(parents=True, exist_ok=True)
    ALIGNED_DIR.mkdir(parents=True, exist_ok=True)

    source = Image.open(source_path).convert("RGBA")
    rgba = np.array(source)
    masks = build_item_masks(content_mask(rgba))
    trimmed_paths: list[Path] = []
    aligned_paths: list[Path] = []
    for spec in ITEMS:
        trimmed = trim_to_mask(source, masks[spec.item_id])
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


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Catudy pet accessory sheet.")
    parser.add_argument("source", type=Path, help="Path to the accessory sheet PNG.")
    args = parser.parse_args()
    import_sheet(args.source)


if __name__ == "__main__":
    main()
