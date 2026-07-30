# AGENTS.md — PawLog 工程规则

> iOS app(SwiftUI + SwiftData)。改代码前读 `product-spec.md` 的验收标准;
> 收工标准 = 构建零警告 + 本文件的坑清单没有新增违反。

## 构建与验证(按顺序)

```bash
xcodegen                                    # 加/删/移动文件后必跑;*.xcodeproj 是生成物,不入库
xcodebuild -scheme PawLog -destination 'platform=iOS Simulator,name=iPhone 17' build
# 收工前再跑 archive(-O 优化能抓到 debug 漏掉的 strict concurrency 错误):
xcodebuild -scheme PawLog -destination 'generic/platform=iOS' archive \
  -archivePath /tmp/PawLog.xcarchive CODE_SIGNING_ALLOWED=NO
```

- 收工标准:build 和 archive 都通过、**零 warning**
- 规范:Swift 6 strict concurrency(`SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`)、
  @Observable(禁用 ObservableObject)、@Model 不跨 async 边界(先提取标量/URL)

## 模拟器调试

- 模拟器无相机,拍照流程自动降级为「相册选图 + 叠加预览」——相机代码在模拟器测不到
- 启动参数:`-seedDemoData` 灌演示数据(豆豆 + 8 天记录);`-initialTab N` 指定启动 Tab

## 真机

- bundle id `com.junjia.pawlog` / `com.junjia.pawlog.widget`,App Group `group.com.junjia.pawlog.shared`
- Team ID `6HRM8RJ78G`(Personal Team)已固化在 project.yml;免费账号签名 7 天过期,需重装
- 所有工程级配置必须写进 `project.yml`——Xcode 界面里改的设置会被 xcodegen 覆盖

## 坑清单(都闪退过或踩过,别再犯)

1. **AVCaptureSession 必须先 `commitConfiguration()` 再 `startRunning()`**——顺序反了抛
   NSException 直接闪退,Swift 捕获不到,且只有真机能触发(2026-07-28 真机崩溃报告定位)
2. **PHPhotoLibrary.performChanges 的闭包在 Photos 后台队列执行**,所在函数必须标
   `nonisolated`——否则默认 MainActor 隔离下 Swift 6 运行时检查 dispatch_assert_queue_fail
   闪退(同日崩溃报告定位)
3. **默认 MainActor 隔离的坑**:工具类的静态常量/计算属性给 @Model init 或后台队列用时,
   要显式标 `nonisolated`(Date+PawLog、GrowthVideoExporter 都中过)
4. **App Groups 在 Personal Team 下不完整**:真机会刷 CFPrefsPlistSource 报错,
   `SharedModelContainer.make()` 已做降级(group 容器失败回退本地存储),不要改回 fatalError;
   小组件数据共享要正常需付费开发者账号
5. **bundle id 全局唯一**:`com.pawlog` 被别人注册过,签名报 Failed Registering Bundle
   Identifier 就是撞名,换独特前缀
6. **新文件不进工程**:sources 是目录索引,但加文件后必须重跑 `xcodegen`,否则编译找不到符号
