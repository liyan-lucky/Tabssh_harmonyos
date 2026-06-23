import drawing from '@ohos.graphics.drawing';

function toArgbColor(color: string): number {
  const normalized: string = color.trim().startsWith('#') ? color.trim().substring(1) : color.trim();
  if (normalized.length === 8) {
    return parseInt(normalized, 16);
  }
  return 0xFF000000 + parseInt(normalized, 16);
}

export function createIconColorFilter(color: string): drawing.ColorFilter {
  return drawing.ColorFilter.createBlendModeColorFilter(toArgbColor(color), drawing.BlendMode.SRC_IN);
}
