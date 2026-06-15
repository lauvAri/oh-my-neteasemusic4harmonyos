/**
 * 底部 Dock 高度配置
 *
 * MainTabs 底部由两块独立玻璃组成，垂直堆叠在 12vp 外边距内：
 *   - Mini Player 独立玻璃壳（MiniPlayerGlassBar）：53vp（内容）+ 10vp（内边距）= 63vp
 *   - Tabs 行玻璃壳（GlassSurface）：36vp（内容）+ 20vp（内边距）= 56vp
 *   - 两块玻璃之间 0vp 间隔
 *
 * 整体实测占用：
 *   - 根 Tab 页：53 + 10 + 0 + 36 + 20 + 12 = 131vp（含外边距）
 *   - 子页（仅 Mini）：53 + 10 = 63vp
 *   - 仅 Tab 栏（无 Mini）：36 + 20 + 12 = 68vp
 *   - 额外遮挡修正：16vp
 *
 * 二级页根据 Mini Player 是否可见动态计算底部占位。Mini Player 可见时保留一段
 * 玻璃重叠区域，让滚动内容能从玻璃下方经过。
 */

const DOCK_OUTER_PADDING_VP: number = 12;
const DOCK_SAFE_MARGIN_VP: number = 3;
const BOTTOM_OCCLUSION_EXTRA_PADDING_VP: number = 32;

const TAB_BAR_CONTENT_VP: number = 36;
const TAB_BAR_INNER_PADDING_VP: number = 20;
const TAB_BAR_TOTAL_VP: number = TAB_BAR_CONTENT_VP + TAB_BAR_INNER_PADDING_VP + DOCK_OUTER_PADDING_VP;

const MINI_PLAYER_CONTENT_VP: number = 53;
const MINI_PLAYER_INNER_PADDING_VP: number = 10;
const MINI_PLAYER_TOTAL_VP: number = MINI_PLAYER_CONTENT_VP + MINI_PLAYER_INNER_PADDING_VP;

const TAB_AND_MINI_SPACING_VP: number = 0;
const TAB_PAGE_TOTAL_VP: number =
  MINI_PLAYER_CONTENT_VP + TAB_AND_MINI_SPACING_VP + TAB_BAR_CONTENT_VP +
  TAB_BAR_INNER_PADDING_VP + DOCK_OUTER_PADDING_VP;

/** 主 Tab 页面（pathDepth === 0）底部需要的安全距离。 */
export const TAB_PAGE_BOTTOM_PADDING_VP: number =
  TAB_PAGE_TOTAL_VP + DOCK_SAFE_MARGIN_VP + BOTTOM_OCCLUSION_EXTRA_PADDING_VP;

/** 详情子页（pathDepth > 0）底部需要的安全距离。 */
export const SUBPAGE_BOTTOM_PADDING_WITH_MINI_VP: number = MINI_PLAYER_TOTAL_VP + DOCK_SAFE_MARGIN_VP;

/** 详情子页无 Mini Player 时不需要额外底部占位。 */
export const SUBPAGE_BOTTOM_PADDING_WITHOUT_MINI_VP: number = 0;

/** Mini Player 玻璃允许覆盖的内容高度，用于形成内容从玻璃下方滑过的视觉。 */
export const SUBPAGE_GLASS_UNDERLAY_OVERLAP_VP: number = 28;

/** 兼容旧调用；新代码应使用 getSubpageBottomPaddingVp。 */
export const SUBPAGE_BOTTOM_PADDING_VP: number = SUBPAGE_BOTTOM_PADDING_WITH_MINI_VP;

/** 仅 Tab 栏（无 Mini Player）模式下的 Dock 高度，供特殊场景使用。 */
export const TAB_ONLY_BOTTOM_PADDING_VP: number = TAB_BAR_TOTAL_VP + DOCK_SAFE_MARGIN_VP;

/**
 * 根据页面类型返回推荐的底部 padding 值。
 *
 * @param isRootTab 是否为主 Tab 根页（HomePage / MinePage 等）
 * @returns 底部 padding（vp）
 */
export function getPageBottomPaddingVp(isRootTab: boolean): number {
  return isRootTab ? TAB_PAGE_BOTTOM_PADDING_VP : SUBPAGE_BOTTOM_PADDING_WITH_MINI_VP;
}

/**
 * 根据 Mini Player 可见性返回二级页底部占位。
 *
 * @param miniPlayerVisible Mini Player 是否可见
 * @returns 底部 padding（vp）
 */
export function getSubpageBottomPaddingVp(miniPlayerVisible: boolean): number {
  if (!miniPlayerVisible) {
    return SUBPAGE_BOTTOM_PADDING_WITHOUT_MINI_VP;
  }
  return SUBPAGE_BOTTOM_PADDING_WITH_MINI_VP - SUBPAGE_GLASS_UNDERLAY_OVERLAP_VP +
    BOTTOM_OCCLUSION_EXTRA_PADDING_VP;
}
