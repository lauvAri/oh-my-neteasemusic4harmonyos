/**
 * 通用防抖工具：在指定延迟内若再次调用，会取消上一次尚未触发的任务，
 * 仅保留最后一次调用。适用于搜索联想等高频输入场景。
 *
 * ArkTS 中全局 setTimeout/clearTimeout 可用，setTimeout 返回 number。
 */
export class Debouncer {
  private timerId: number = -1;
  private readonly delay: number;

  constructor(delay: number) {
    this.delay = delay;
  }

  schedule(task: () => void): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
    }
    this.timerId = setTimeout(() => {
      this.timerId = -1;
      task();
    }, this.delay);
  }

  cancel(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }
}
