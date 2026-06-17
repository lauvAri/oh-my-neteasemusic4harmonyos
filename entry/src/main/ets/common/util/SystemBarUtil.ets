import { window } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';

const SYSTEM_BAR_OVERRIDE_KEY: string = 'systemBarOverride';

/**
 * 根据 AppStorage 中的 override 标志和系统 ColorMode,应用状态栏字色。
 * - override === 'light' → 强制白色(用于深色背景的全屏页)
 * - 否则 → 深色系统模式:白,浅色系统模式:黑
 */
export async function applySystemBarForCurrentMode(): Promise<void> {
  const context = getContext() as common.UIAbilityContext | undefined;
  if (context === undefined) {
    return;
  }
  try {
    const win = await window.getLastWindow(context);
    const override = AppStorage.get<string>(SYSTEM_BAR_OVERRIDE_KEY);
    const mode = AppStorage.get<number>('currentColorMode');
    const useWhite: boolean = override === 'light'
      || mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    await win.setWindowSystemBarProperties({
      statusBarContentColor: useWhite ? '#FFFFFF' : '#000000'
    });
  } catch (err) {
    console.error(`applySystemBarForCurrentMode failed: ${JSON.stringify(err)}`);
  }
}

/**
 * 设置状态栏图标是否被页面强制成浅色。
 * @param useLight true = 强制白色;false = 清除强制,恢复跟随系统模式
 */
export async function setStatusBarLightContent(useLight: boolean): Promise<void> {
  AppStorage.setOrCreate<string>(SYSTEM_BAR_OVERRIDE_KEY, useLight ? 'light' : '');
  await applySystemBarForCurrentMode();
}