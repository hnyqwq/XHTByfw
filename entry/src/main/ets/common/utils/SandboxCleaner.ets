import { fileIo as fs } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';

const TAG: string = 'SandboxCleaner';
const DOMAIN: number = 0x0000;

// 分享/工具产物保留天数,超期即删
const RETENTION_DAYS: number = 7;

// filesDir 下按前缀识别的一次性文件(分享接收/跨设备/缩略图/图片工具产物)
const ONE_OFF_PREFIXES: string[] = [
  'share_image_', 'share_video_', 'share_file_', 'share_thumbnail_',
  'ext_share_img_', 'ext_share_vid_',
  'converted_', 'compressed_'
];

// 选图/选视频/选文件的沙箱复制件统一存放目录,整个目录按保留天数清理
const SHARE_TMP_DIR: string = 'share_tmp';

function cleanDir(dir: string, prefixes: string[], retentionDays: number): void {
  let names: string[] = [];
  try {
    names = fs.listFileSync(dir);
  } catch (e) {
    return; // 目录不存在视为无历史文件
  }
  // Stat.mtime 单位为秒
  const expireBefore = Date.now() / 1000 - retentionDays * 86400;
  for (const name of names) {
    const path = dir + '/' + name;
    try {
      const stat = fs.statSync(path);
      if (stat.isDirectory()) {
        cleanDir(path, prefixes, retentionDays);
        continue;
      }
      if (prefixes.length > 0 && !prefixes.some(p => name.startsWith(p))) {
        continue;
      }
      if (stat.mtime < expireBefore) {
        fs.unlinkSync(path);
        hilog.info(DOMAIN, TAG, 'cleaned expired file: %{public}s', path);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'skip %{public}s: %{public}s', path, JSON.stringify(e));
    }
  }
}

function removePath(path: string): void {
  if (fs.statSync(path).isDirectory()) {
    const names = fs.listFileSync(path);
    for (const name of names) {
      removePath(path + '/' + name);
    }
    fs.rmdirSync(path);
  } else {
    fs.unlinkSync(path);
  }
}

export function clearDirSync(dir: string): void {
  let names: string[] = [];
  try {
    names = fs.listFileSync(dir);
  } catch (e) {
    return;
  }
  for (const name of names) {
    try {
      removePath(dir + '/' + name);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'clear skip %{public}s: %{public}s', dir + '/' + name, JSON.stringify(e));
    }
  }
}

export function clearDirExceptSync(dir: string, keepFileName: string): void {
  let names: string[] = [];
  try {
    names = fs.listFileSync(dir);
  } catch (e) {
    return;
  }
  for (const name of names) {
    if (name === keepFileName) {
      continue;
    }
    try {
      removePath(dir + '/' + name);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'clear skip %{public}s: %{public}s', dir + '/' + name, JSON.stringify(e));
    }
  }
}

export function cleanExpiredFilesSync(dir: string, prefixes: string[], retentionDays: number): void {
  cleanDir(dir, prefixes, retentionDays);
}

// 应用启动时调用:清空下载分享缓存,按保留期清理一次性沙箱文件
export function cleanOnLaunch(context: Context): void {
  try {
    clearDirSync(context.cacheDir + '/down_export');
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'clean down_export failed: %{public}s', JSON.stringify(e));
  }
  try {
    cleanExpiredFilesSync(context.filesDir, ONE_OFF_PREFIXES, RETENTION_DAYS);
    cleanExpiredFilesSync(context.filesDir + '/' + SHARE_TMP_DIR, [], RETENTION_DAYS);
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'clean filesDir failed: %{public}s', JSON.stringify(e));
  }
}
