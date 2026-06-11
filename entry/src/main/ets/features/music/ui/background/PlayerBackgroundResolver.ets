export interface PlayerBackgroundPalette {
  topColor: string;
  middleColor: string;
  bottomColor: string;
  glowColor: string;
}

interface RgbColor {
  r: number;
  g: number;
  b: number;
}

const FALLBACK_PALETTE: PlayerBackgroundPalette = {
  topColor: '#1f2937',
  middleColor: '#141f33',
  bottomColor: '#0b1220',
  glowColor: '#1b2f4d'
};

const DARK_BASE_PALETTES: PlayerBackgroundPalette[] = [
  { topColor: '#1e293b', middleColor: '#17233a', bottomColor: '#0b1220', glowColor: '#27466b' },
  { topColor: '#2a1f3d', middleColor: '#1c1730', bottomColor: '#0f1222', glowColor: '#40306a' },
  { topColor: '#1b2e3a', middleColor: '#162433', bottomColor: '#0a121f', glowColor: '#24506a' },
  { topColor: '#2e2430', middleColor: '#221b2a', bottomColor: '#100f1b', glowColor: '#503255' },
  { topColor: '#253226', middleColor: '#1b281f', bottomColor: '#101915', glowColor: '#31543d' },
  { topColor: '#252b39', middleColor: '#1b2231', bottomColor: '#0f1422', glowColor: '#35517a' },
  { topColor: '#2f2a20', middleColor: '#242016', bottomColor: '#14120d', glowColor: '#5d4729' },
  { topColor: '#1f2831', middleColor: '#19212b', bottomColor: '#0d131b', glowColor: '#2f4f68' }
];

function hashString(value: string): number {
  let hash: number = 2166136261;
  for (let index = 0; index < value.length; index++) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function clampChannel(value: number): number {
  if (value < 0) {
    return 0;
  }
  if (value > 255) {
    return 255;
  }
  return Math.round(value);
}

function parseHexColor(color: string): RgbColor {
  const text = color.startsWith('#') ? color.substring(1) : color;
  const normalized = text.length === 3
    ? `${text[0]}${text[0]}${text[1]}${text[1]}${text[2]}${text[2]}`
    : text;
  return {
    r: Number.parseInt(normalized.substring(0, 2), 16),
    g: Number.parseInt(normalized.substring(2, 4), 16),
    b: Number.parseInt(normalized.substring(4, 6), 16)
  };
}

function toHexColor(rgb: RgbColor): string {
  const r = clampChannel(rgb.r).toString(16).padStart(2, '0');
  const g = clampChannel(rgb.g).toString(16).padStart(2, '0');
  const b = clampChannel(rgb.b).toString(16).padStart(2, '0');
  return `#${r}${g}${b}`;
}

function scaleBrightness(rgb: RgbColor, factor: number): RgbColor {
  return {
    r: rgb.r * factor,
    g: rgb.g * factor,
    b: rgb.b * factor
  };
}

function mixWithBlack(rgb: RgbColor, blackMix: number): RgbColor {
  const keep = 1 - blackMix;
  return {
    r: rgb.r * keep,
    g: rgb.g * keep,
    b: rgb.b * keep
  };
}

function applyCoolTint(rgb: RgbColor): RgbColor {
  // Keep visual richness while steering to a calmer cool palette for lyric readability.
  return {
    r: clampChannel(rgb.r * 0.90),
    g: clampChannel(rgb.g * 0.95),
    b: clampChannel(rgb.b * 1.08)
  };
}

function darkenHexColor(hexColor: string, brightnessFactor: number, blackMix: number): string {
  const rgb = parseHexColor(hexColor);
  const dimmed = scaleBrightness(rgb, brightnessFactor);
  const darkened = mixWithBlack(dimmed, blackMix);
  const tinted = applyCoolTint(darkened);
  return toHexColor(tinted);
}

export class PlayerBackgroundResolver {
  static defaultPalette(): PlayerBackgroundPalette {
    return FALLBACK_PALETTE;
  }

  static resolveFromCover(coverUrl: string): PlayerBackgroundPalette {
    if (coverUrl.length === 0) {
      return FALLBACK_PALETTE;
    }
    const hash = hashString(coverUrl);
    const paletteIndex = hash % DARK_BASE_PALETTES.length;
    const base = DARK_BASE_PALETTES[paletteIndex];

    // Introduce subtle song-specific variance while preserving a consistently dark tone.
    const variation = ((hash >>> 8) % 9) / 100; // 0.00 - 0.08
    const top = darkenHexColor(base.topColor, 0.94 - variation, 0.10 + variation);
    const middle = darkenHexColor(base.middleColor, 0.90 - variation, 0.13 + variation);
    const bottom = darkenHexColor(base.bottomColor, 0.84 - variation, 0.19 + variation);
    const glow = darkenHexColor(base.glowColor, 0.86 - variation, 0.16 + variation);

    return {
      topColor: top,
      middleColor: middle,
      bottomColor: bottom,
      glowColor: glow
    };
  }
}
