import { uiMaterial } from '@kit.ArkUI';
import { BRAND_COLOR } from '../BrandColor';

// 部分设备（如平板）运行时不提供 ImmersiveMaterial/ImmersiveStyle，渲染期直接 new 会抛
// "Cannot read property ULTRA_THIN of undefined"，统一在此 try/catch 兜底，
// 不支持时返回 undefined（systemMaterial 属性签名接受 undefined）。

export function createMenuImmersiveMaterial(): uiMaterial.ImmersiveMaterial | undefined {
  try {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      colorInvert: true,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: Color.White }
    });
  } catch (err) {
    return undefined;
  }
}

export function createBrandImmersiveMaterial(): uiMaterial.ImmersiveMaterial | undefined {
  try {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      materialColor: BRAND_COLOR,
      colorInvert: true,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: Color.White }
    });
  } catch (err) {
    return undefined;
  }
}

export function createUiMaterial(): uiMaterial.Material | undefined {
  try {
    return new uiMaterial.Material();
  } catch (err) {
    return undefined;
  }
}
