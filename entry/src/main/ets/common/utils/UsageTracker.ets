import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class UsageTracker {
  private static INSTANCE: UsageTracker | undefined = undefined;
  private store: preferences.Preferences | undefined = undefined;

  private constructor() {}

  static getInstance(): UsageTracker {
    if (!UsageTracker.INSTANCE) {
      UsageTracker.INSTANCE = new UsageTracker();
    }
    return UsageTracker.INSTANCE;
  }

  init(context: common.UIAbilityContext): void {
    this.store = preferences.getPreferencesSync(context, { name: 'tool_usage' });
  }

  recordUsage(pageUrl: string): void {
    if (!this.store) {
      return;
    }
    let count: number = this.store.getSync(pageUrl, 0) as number;
    this.store.putSync(pageUrl, count + 1);
    // 记录最近一次使用时间戳:常用功能按"最近使用的排最前"展示
    this.store.putSync(`${pageUrl}_ts`, Date.now());
    this.store.putSync('has_usage_data', true);
    this.store.flush();
    let version: number = AppStorage.get<number>('usageVersion') ?? 0;
    AppStorage.setOrCreate<number>('usageVersion', version + 1);
  }

  getUsageCount(pageUrl: string): number {
    if (!this.store) {
      return 0;
    }
    return this.store.getSync(pageUrl, 0) as number;
  }

  // 最近一次使用的时间戳(毫秒);无记录返回 0,旧版本数据没有时间戳也会自然排到后面
  getLastUsedTime(pageUrl: string): number {
    if (!this.store) {
      return 0;
    }
    return this.store.getSync(`${pageUrl}_ts`, 0) as number;
  }

  hasAnyUsage(): boolean {
    if (!this.store) {
      return false;
    }
    return this.store.hasSync('has_usage_data');
  }

  markUsageExists(): void {
    if (!this.store) {
      return;
    }
    this.store.putSync('has_usage_data', true);
    this.store.flush();
  }
}
