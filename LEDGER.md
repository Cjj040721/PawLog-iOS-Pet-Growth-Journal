# LEDGER — PawLog

## NOW
- (空)

## NEXT
- T9 真机回归验证:相机对比模式流畅度、存相册、补记流程(T4/T5/T6 修复后未回归)
- T10 spec 风险项实测:>100 张照片的成长视频合成耗时与内存(必要时分段渲染)
- T11 战略待定:v1.1 是否上轻订阅;上线前是否先做 landing page 验证需求

## DONE
- 2026-07-30 | T12 | 设计语言 v1 定稿(design/design-language.md)+ 最小版 landing page(landing/index.html,留资用 mailto 免后端方案) | `3392f91` | Playwright 截图走查(桌面 1280 + 移动 390)
- 2026-07-30 | T8 | 补三件套(README/LEDGER/AGENTS.md) | — | 已目检
- 2026-07-30 | T7 | git init + 首次提交,代码资产入库 | `2e5252a` | git log 确认
- 2026-07-28 | T6 | 补记:记录日期可选过去,已有记录预填+覆盖提示 | — | xcodebuild 通过
- 2026-07-28 | T5 | 修复存相册闪退(performChanges 闭包需 nonisolated);对比图改模糊底+完整显示+留白 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T4 | 修复相机闪退(startRunning 在 commit 之前);拍照页加相册入口;多宠物;app 图标 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T3 | 真机调试打通:bundle id 冲突改 com.junjia.pawlog,Team ID 固化 project.yml | — | 真机跑通
- 2026-07-28 | T2 | [L2] v1 功能代码整体铺开(约 2400 行/30+ 文件) | — | build + archive 通过零警告;模拟器四 Tab 截图走查
- 2026-07-27 | T1 | [L1] product-spec 定稿:v1 全免费,「在一起第 N 天」计数基准用户自选 | — | 人评审拍板
