# 星河工具盒 Xinghe Tool Box（元服务）

一款即点即用的 HarmonyOS 元服务工具箱，无需下载安装，打开即用。

## 下载体验

- **正式版**：[华为服务卡片](https://hoas.drcn.agconnect.link/64123a730cb7096cf75db24172be02da2aa5062c792c3007ecf62e9219bd55d1)
- **邀测版**：[AppTest 邀请测试](https://appgallery.huawei.com/apptest/2jZdmurLRvv)

更多应用请前往 [hnyqwq 应用下载中心](https://download.hnyqwq.cn)。

## 功能特性

### 文本处理
- **朗读文字**：输入文本即可语音朗读（基于 Core Speech Kit，内容由 AI 生成）
- **生成二维码**：将文本或链接生成二维码图片
- **字数统计**：总字数、字符数（不含空格）、中文字数、英文单词数、行数与段落数
- **文本加密/解密**：使用密钥对文本进行加密与解密
- **JSON格式化**：一键美化或压缩，自动修正全角符号等常见输入问题

### 图像处理
- **图片压缩**：调节质量参数，减小图片体积
- **格式转换**：在常见图片格式之间转换
- **图片信息**：查看尺寸、文件大小、格式与宽高比

### 实用工具
- **密码生成器**：按长度与字符类型组合生成随机密码
- **颜色选择器**：选取图片中的颜色并获取 RGB 数值
- **倒计时秒表**：支持正计时、倒计时与分段计时

### 分享预览
- 支持链接、文本、图片、视频、文件等多种类型的内容分享
- 可自定义分享标题与背景图片

## 桌面服务卡片

| 卡片 | 说明 | 尺寸 |
|------|------|------|
| 星河工具盒（默认卡） | 点击直达工具箱 | 2×2 / 4×4 |
| 快捷入口 | 一键打开工具箱或分享预览 | 2×2 / 4×4 |

卡片采用星河紫渐变风格，2×2 与 4×4 自动切换布局密度，文案支持多语言。

## 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/zh/deveco-studio/) 26.0.0.851 及以上版本
- SDK / API 26，hvigor 26.0.0
- HarmonyOS 7.0.0 及以上真机或模拟器（元服务）

## 构建运行

```bash
git clone https://gitee.com/hnyqwq/XHTByfw.git
cd XHTByfw
```

推荐使用 DevEco Studio 打开项目，等待依赖同步后在真机/模拟器上运行；或使用命令行构建 HAP：

```bash
cp build-profile.json5.example build-profile.json5
hvigorw --mode module -p product=default assembleHap
```

> 签名配置文件 `build-profile.json5` 不入库（含证书敏感信息），首次构建请从 `build-profile.json5.example` 复制一份，并在 DevEco Studio 的 Project Structure → Signing Configs 中配置自己的证书。

## 项目结构

```
├── AppScope/                  # 应用级配置与图标
├── entry/src/main/ets/
│   ├── entryability/          # UIAbility 入口（含卡片跳转页签分发）
│   ├── entryformability/      # 服务卡片 FormExtensionAbility（尺寸透传）
│   ├── Cards/pages/           # 桌面卡片页面（默认卡 / 快捷入口卡）
│   ├── pages/                 # 主页面（HomePage / SecondPage / MinePage）
│   ├── view/                  # 沉浸式页签视图
│   ├── XHTB/                  # 工具页（文本 / 图像 / 实用工具）
│   ├── components/            # 通用组件（ToolNavTitleBar 等）
│   ├── common/                # 全局信息、断点系统、键盘避让
│   └── viewmodel/             # 页签数据模型
├── EntryCard/                 # 卡片快照资源
└── build-profile.json5        # 构建与签名配置
```

## 技术要点

- **元服务适配**：严格遵循元服务 API 集，使用 `http.request`、`packToData`、`NavDestination` 等合法替代方案规避受限能力
- **三语言资源**：zh_CN / base / en_US 全量对齐
- **深浅色模式**：全量颜色资源适配
- **卡片尺寸自适应**：`FormExtensionAbility` 透传卡片规格，2×2 / 4×4 差异化布局

## License

本项目基于 [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.txt) 协议开源——你可以自由地学习、使用、修改和分发，但任何基于本项目的衍生作品都必须同样以 GPL-3.0 协议完整开源（禁止闭源换皮）。详见 [LICENSE](./LICENSE)。
