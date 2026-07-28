# GameLauncher 1.1.0 Public Preview

这是公开预览版。启动器、引擎、模型和打包壳已改为按需分发，不再把游戏、
Wine、KRKR、ONS、EasyRPG 或超分/插帧模型塞进启动器 APK。

## 主要变化

- 新增首次启动权限与引擎选择页；确认后立即进入主页，下载在应用内后台队列继续。
- 下载支持断点续传、超时重试、并发分块、持久 FIFO 队列、GitHub 直连与中国镜像分流。
- 新增右上角引擎任务列表、扫描结果确认、顶栏纯图标导航。
- EXE 导入和打包会自动提取应用图标；用户自定义封面优先。
- 启动器内部游戏启动改用与打包模板一致的已验证运行路径。
- 健康游戏提示固定为两行，每行两个条款。

## 发布内容

- Windows 安装版：内置官方 Android Emulator、WHPX 启动助手和 Android 35
  x86_64 壳镜像；不含 Wine、游戏、模型或可变模拟器状态。
- Windows 便携版：同一内容，`tar + zstd level 19`，738.6 MiB。
- Android ARM64：10.63 MiB 薄启动器，仅带通用宿主适配层。
- 公共引擎仓库已提供 Android ARM64 的 KRKR、ONS、Wine 11.11 文件和四个
  独立 release 签名打包壳；EasyRPG 仅提供懒加载壳，Android 引擎文件仍阻止发布。

## 验证

- 三个优先游戏的 Windows 启动器运行时与打包应用矩阵：6/6 通过。
- Android 薄启动器：仅 arm64-v8a，APK Signature Scheme v2/v3 通过，未发现引擎、
  模型、模板或游戏资源。
- KRKR、ONS、Wine Android 引擎文件已从公开 Release 完整回下载并通过 SHA-256。
- Windows 安装包完成完整性、篡改拒绝、事务回滚、安装与卸载 smoke test。

## 已知限制

- Windows 主库页面的真实鼠标点击启动尚未完成最终 UI 实机证据；兼容矩阵验证的是
  同一正式 runtime-overlay/打包执行链。
- 没有可用的 ARM64 Android 真机，因此 Wine 子进程、SDL Surface/输入和三游戏
  Android 真机兼容性不得视为已验证。
- EasyRPG 当前 Android 源码依赖缺少可复现 arm64 产物；没有使用旧 APK 二进制冒充。
- 超分与插帧组件在可重分发权重、原生 runner 和真实目标测试齐全前保持不可下载。
- Windows 安装包未使用受信任 Authenticode 证书，SmartScreen 可能显示未知发布者。

SHA-256 见 `checksums.txt`。
