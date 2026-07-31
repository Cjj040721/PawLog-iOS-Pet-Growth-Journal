# LEDGER — PawLog

## NOW
- (空)

## NEXT
- T9 真机回归验证:相机对比模式流畅度、存相册、补记流程(T4/T5/T6 修复后未回归);新增:成长视频导出 + 存相册 + 分享(CAO-13 重构后,需真机验证)
- T11 战略待定:v1.1 是否上轻订阅;上线前是否先做 landing page 验证需求

## DONE
- 2026-07-30 | CAO-13 | 成长视频导出重构为 AVAssetWriter 逐帧写入(字幕按 design-language §6.2,接进度条);渲染路径 autoreleasepool 控内存;构建恢复零警告 | `80c8ba3` `7f1146f` | build+archive 零警告;模拟器实测 8 帧 15.8s/120 帧 241.6s,峰值内存 736MB 恒定,存相册走通;导出+存相册+分享需真机验证(入 T9)
- 2026-07-30 | T8 | 补三件套(README/LEDGER/AGENTS.md) | — | 已目检
- 2026-07-30 | T7 | git init + 首次提交,代码资产入库 | `2e5252a` | git log 确认
- 2026-07-28 | T6 | 补记:记录日期可选过去,已有记录预填+覆盖提示 | — | xcodebuild 通过
- 2026-07-28 | T5 | 修复存相册闪退(performChanges 闭包需 nonisolated);对比图改模糊底+完整显示+留白 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T4 | 修复相机闪退(startRunning 在 commit 之前);拍照页加相册入口;多宠物;app 图标 | — | 崩溃报告定位 + 真机目检
- 2026-07-28 | T3 | 真机调试打通:bundle id 冲突改 com.junjia.pawlog,Team ID 固化 project.yml | — | 真机跑通
- 2026-07-28 | T2 | [L2] v1 功能代码整体铺开(约 2400 行/30+ 文件) | — | build + archive 通过零警告;模拟器四 Tab 截图走查
- 2026-07-27 | T1 | [L1] product-spec 定稿:v1 全免费,「在一起第 N 天」计数基准用户自选 | — | 人评审拍板
