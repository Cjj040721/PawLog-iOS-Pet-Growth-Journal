# LEDGER — PawLog

## NOW
- (空)

## NEXT
- T11 战略待定:v1.1 是否上轻订阅(已拍板:不上,推迟至 v1.2)

## DONE
- 2026-11-18 | 仓库命名规范化 | 由 `pawlog` 更名为 `PawLog-iOS-Pet-Growth-Journal`，补充 iOS 平台与宠物成长记录用途；同步更新 remote、README 克隆地址与目录名（见本次提交）
- 2026-11-18 | GitHub 作品集展示改造 | 修复新版编译器下视频进度可选 State 未解包导致的构建失败；新增英文主页、中文入口、四个 Tab 的真实模拟器截图与组合首图；未改产品范围、未上架 | `893ed30` `76daa6d` | iPhone 17 Simulator build 零警告 + generic iOS archive 零警告；README 本地链接检查通过
- 2026-07-31 | CAO-15 | 最小版 landing page 发布上线:本人拍板发布,Cloudflare 静态托管,留资邮箱 caojunjia040721@163.com | — | https://wandering-queen-f8fa.caojunjia040721.workers.dev
- 2026-07-31 | CAO-29(T9) | 真机回归验证完成:相机对比模式流畅度、存相册、补记流程(T4/T5/T6 修复后)、成长视频导出 + 存相册 + 分享(CAO-13 AVAssetWriter 重构后)全部走通 | — | 本人真机目检(issue CAO-29 状态记录)
- 2026-07-31 | CAO-28 | 修复编译报错(PawLogApp.swift:pawPrimary 无法推断 + Debug 系列视图不在作用域):根因是本地 xcodeproj 生成早于 7fd01f3(该提交新增 DesignTokens.swift / DebugWalkthroughView.swift),新文件未进 target——坑清单 #6 复现;重跑 xcodegen 重新索引即恢复,源码零改动 | — | build + archive 零警告
- 2026-07-31 | CAO-22 | 分支整合进 main:视频重构(CAO-13)+ 视觉落地(CAO-14)经 df57acc5 快进合并,design-language 首版(2dd3cbf5)与定稿 + landing(cc5b81ab)合并;design-language.md 冲突取 CAO-14 全量版并追加 §10 Web 令牌,LEDGER DONE 保留全部条目 | `e82e3a4` | main 上 xcodegen + build + archive 零警告
- 2026-07-31 | CAO-14 | 视觉规范 v1.0 落地:design/design-language.md 入库,DesignTokens 基础设施(15 colorset 深浅双值 + 常量/主按钮/空状态组件),P1(里程碑星金/对比图奶油卡/表单胶囊主按钮/暖调占位),P2(圆角归一/空状态三件套/小组件品牌色/第 N 天大数字) | `7fd01f3` | build+archive 零警告;模拟器四 Tab+对比图+小组件深浅两版截图走查(issue 评论附件)
- 2026-07-30 | CAO-13 | 成长视频导出重构为 AVAssetWriter 逐帧写入(字幕按 design-language §6.2,接进度条);渲染路径 autoreleasepool 控内存;构建恢复零警告 | `80c8ba3` `7f1146f` | build+archive 零警告;模拟器实测 8 帧 15.8s/120 帧 241.6s,峰值内存 736MB 恒定,存相册走通;导出+存相册+分享需真机验证(入 T9)
- 2026-07-30 | T12 | [美术] 建立 design/design-language.md 视觉规范(色彩 OKLCH/字体/圆角/组件状态/产出物模板)+ 视觉问题清单(CAO-11) | `9e0eacf` | design/preview/design-tokens.png 示意稿
- 2026-07-30 | T12 | 设计语言 v1 定稿(design/design-language.md)+ 最小版 landing page(landing/index.html,留资用 mailto 免后端方案) | `3392f91` | Playwright 截图走查(桌面 1280 + 移动 390)
- 2026-07-30 | T8 | 补三件套(README/LEDGER/AGENTS.md) | — | 已目检
- 2026-07-30 | T7 | git init + 首次提交,代码资产入库 | `2e5252a` | git log 确认
- 2026-07-28 | T6 | 补记:记录日期可选过去,已有记录预填+覆盖提示 | — | xcodebuild 通过
- 2026-07-28 | T5 | 修复存相册闪退(performChanges 闭包需 nonisolated);对比图改模糊底+完整显示+留白 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T4 | 修复相机闪退(startRunning 在 commit 之前);拍照页加相册入口;多宠物;app 图标 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T3 | 真机调试打通:bundle id 冲突改 com.junjia.pawlog,Team ID 固化 project.yml | — | 真机跑通
- 2026-07-28 | T2 | [L2] v1 功能代码整体铺开(约 2400 行/30+ 文件) | — | build + archive 通过零警告;模拟器四 Tab 截图走查
- 2026-07-27 | T1 | [L1] product-spec 定稿:v1 全免费,「在一起第 N 天」计数基准用户自选 | — | 人评审拍板
