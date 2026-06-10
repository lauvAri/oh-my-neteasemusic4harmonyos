/**
 * 底部 Dock 高度配置
 *
 * MainTabs 中 GlassSurface + 12vp 外边距的实测占用：
 *   - Tab 栏 + Mini Player 模式：117vp（内容）+ 12vp（外边距）= 129vp
 *   - 仅 Tab 栏模式：36vp（内容）+ 20vp（内边距）+ 12vp（外边距）= 68vp
 *   - 子页 Mini Player 模式：53vp（内容）+ 16vp（内边距）+ 12vp（外边距）= 81vp
 *
 * 为保证最坏情况（Mini 始终可见）下页面内容不被遮挡，统一使用较大值并加少量
 * 安全余量。
 */

const DOCK_OUTER_PADDING_VP: number = 12;
const DOCK_SAFE_MARGIN_VP: number = 3;

const TAB_BAR_CONTENT_VP: number = 36;
const TAB_BAR_INNER_PADDING_VP: number = 20;
const TAB_BAR_TOTAL_VP: number = TAB_BAR_CONTENT_VP + TAB_BAR_INNER_PADDING_VP + DOCK_OUTER_PADDING_VP;

const MINI_PLAYER_CONTENT_VP: number = 53;
const MINI_PLAYER_INNER_PADDING_VP: number = 16;
const MINI_PLAYER_TOTAL_VP: number = MINI_PLAYER_CONTENT_VP + MINI_PLAYER_INNER_PADDING_VP + DOCK_OUTER_PADDING_VP;

const TAB_AND_MINI_SPACING_VP: number = 8;
const TAB_PAGE_TOTAL_VP: number =
  MINI_PLAYER_CONTENT_VP + TAB_AND_MINI_SPACING_VP + TAB_BAR_CONTENT_VP +
  TAB_BAR_INNER_PADDING_VP + DOCK_OUTER_PADDING_VP;

/** 主 Tab 页面（pathDepth === 0）底部需要的安全距离。 */
export const TAB_PAGE_BOTTOM_PADDING_VP: number = TAB_PAGE_TOTAL_VP + DOCK_SAFE_MARGIN_VP;

/** 详情子页（pathDepth > 0）底部需要的安全距离。 */
export const SUBPAGE_BOTTOM_PADDING_VP: number = MINI_PLAYER_TOTAL_VP + DOCK_SAFE_MARGIN_VP;

/** 仅 Tab 栏（无 Mini Player）模式下的 Dock 高度，供特殊场景使用。 */
export const TAB_ONLY_BOTTOM_PADDING_VP: number = TAB_BAR_TOTAL_VP + DOCK_SAFE_MARGIN_VP;

/**
 * 根据页面类型返回推荐的底部 padding 值。
 *
 * @param isRootTab 是否为主 Tab 根页（HomePage / MinePage 等）
 * @returns 底部 padding（vp）
 */
export function getPageBottomPaddingVp(isRootTab: boolean): number {
  return isRootTab ? TAB_PAGE_BOTTOM_PADDING_VP : SUBPAGE_BOTTOM_PADDING_VP;
}
