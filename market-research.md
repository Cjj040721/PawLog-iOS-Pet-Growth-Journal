# PawLog 市场调研与可行性分析

> 调研日期：2026-07-27
> 目的：评估「宠物成长记录 App」是否值得以「一人公司 + vibe coding」的方式开发、上架、变现。

## 结论速览

- **技术可行性**：★★★★★ 一人 + AI 辅助完全能做出来。spec 里的功能全是成熟本地 iOS API。
- **市场空白**：赛道已被验证有需求，但**很拥挤**，v1 规划的功能没有一个是空白。
- **差异化机会**：同角度叠加拍照、成长对比图/视频、「在一起第 N 天」小组件——这三点是立足点。
- **赚钱难度**：★★★★★ 成败 90% 取决于差异化定位与获客，而非代码。中位数结果是几乎不赚钱。
- **一句话**：可做、可上架、技术无障碍；把它当低成本、有小概率跑出「几百~几千美元/月」的副业，而非替代工资的生意。

---

## 一、市场现状：赛道成熟但拥挤，无绝对垄断者

宠物成长记录品类**已被验证有需求**，但也**已经拥挤**。App Store 直接竞品众多：

| 竞品 | 定位 | 与 PawLog v1 重叠度 |
|---|---|---|
| Puppy Journal / Your Dog Diary | 幼犬日记 + 分享 | 高 |
| Pet Memories+ | 宠物回忆册 | 高 |
| Pet Growth Notes | 成长记录 + 提醒 | 高 |
| PuppyPlanner | 幼犬前几个月：疫苗/驱虫/社会化/体重 | 高 |
| Dog Buddy Pro | 日记 + 里程碑 + 体重 + 疫苗，多宠物 | 高 |
| Pet Care Tracker 等健康类 | 体重/用药/健康记录 | 中，已做到 4.8★、900+ 评价 |

GPS 硬件系（Tractive 4.7★/41K、Fi 4.7★/37K）是硬件生意，不冲突。

**关键判断**：spec 里 v1 的功能（档案、照片日记、体重曲线、疫苗提醒）**没有一个是市场空白**。真正还没被做透、能当差异化的是三点：

1. **同角度半透明叠加拍照** —— 竞品几乎无人做，是最亮的点。
2. **一键成长对比图 / 成长视频** —— 有 PhotoJourney 这类通用 timelapse，但没有「宠物专用 + 日期/年龄字幕」的。
3. **「在一起第 N 天」小组件** —— 情感钩子，竞品普遍弱。

这三点合起来是「情感回顾」而非「记账」，恰好对上 spec 里 problem 的核心洞察（回顾价值低）。**这是唯一的立足点，必须守住。**

---

## 二、变现参照：Tinybeans，而非宠物 App

母婴记录赛道的 Tinybeans（ASX: TNY，上市公司）是最佳参照——「宝宝成长记录」与「宠物成长记录」的用户心理几乎一致（情感、不可逆的时间窗口、愿为回忆付费）：

- 从广告 freemium **转向订阅**后才盈利；FY25 订阅占收入 **69%**。
- 付费用户**续订率 93%**。
- Q3 FY26 订阅收入同比 +87%，占总收入 81%，实现公司史上首个正 EBITDA 季度。

**启示**：这类情感记录产品，订阅制可行且留存能很高——前提是真正沉淀了用户舍不得丢的数据。

---

## 三、独立开发者收入的真实分布（RevenueCat 2025）

必须直视的数据：

- **中位数 App 月收入 < $500**；上线 12 个月后**中位数 < $50/月**。
- Top 5% 才过 $10K/月，Top 1% 才 $50K+/月。
- 头部 200 家发行商拿走了绝大部分的约 $960 亿 App Store 年收入。

**含义**：「做出来上架赚钱」的中位数结果是几乎不赚钱。能到「几百到几千美元/月」已跑赢大多数人，需要 ASO + 留存 + 变现三者都对。

---

## 四、可行性拆解：赚钱靠的不是编码

**vibe coding 一人做出来上架——技术上 100% 可行。** spec 里所有功能（SwiftData、相机叠加、Swift Charts、AVFoundation 视频合成、WidgetKit）都是成熟本地 API，一个人用 AI 辅助几个月能做完。这不是瓶颈。

真正的瓶颈是三件和写代码无关的事：

| 环节 | 难度 | 说明 |
|---|---|---|
| 做出来 | ★★☆☆☆ | vibe coding 能搞定，spec 已很清楚 |
| 被看到（ASO/获客） | ★★★★★ | 赛道拥挤，自然流量要和几十个竞品抢关键词 |
| 让人付费 + 留存 | ★★★★☆ | 需要数据沉淀足够深，用户才舍不得走 |

---

## 五、行动建议

1. **缩小切入点，别做第 N 个「大而全」的记录 App。**
   市场不缺记账工具，缺「同角度对比 + 成长视频」这种情感产品。App 名字与营销叙事都聚焦**「看着它长大」**，而非「记录健康」。

2. **重新考虑「纯免费无内购」的 v1 决策。**
   把付费推到 v1.2，会让上线后**完全拿不到「用户是否愿意付费」的信号**，而这是最该早验证的假设。建议 v1 就上轻订阅（参考 Tinybeans）：免费能记录，**高清视频导出 / 多宠物 / 主题**作为订阅点。RevenueCat 接入成本低。

3. **上线前先验证需求，别闷头做半年。**
   - 先做 landing page + 演示同角度叠加拍照的 demo 视频，发到宠物社群 / 小红书 / Reddit r/dogs，看是否有人说「我想要这个」。
   - 有真实兴趣信号再投入完整开发。

4. **把预期调对。**
   当成低成本、能学到东西、有小概率跑出「几百~几千美元/月」的副业项目，而非替代工资的生意。差异化点若做得漂亮，有机会跑赢中位数。

---

## 参考来源

- [How Much Do Indie iOS Developers Make? (theswiftkit)](https://theswiftk.it.com/blog/how-much-do-indie-ios-developers-make)
- [iOS App Monetization Strategies (Ptolemay)](https://www.ptolemay.com/post/best-ios-app-monetization-strategies)
- [Tinybeans Q3 FY26 — first EBITDA profit, 86% revenue growth (Investing.com)](https://au.investing.com/news/company-news/tinybeans-q3-fy26-slides-first-ebitda-profit-86-revenue-growth-93CH-4394823)
- [Puppy Journal: Your Dog Diary (App Store)](https://apps.apple.com/us/app/puppy-journal-your-dog-diary/id1528796446)
- [PuppyPlanner: Puppy Tracker (App Store)](https://apps.apple.com/us/app/puppyplanner-puppy-tracker/id6760142762)
- [Pet Growth Notes (App Store)](https://apps.apple.com/us/app/pet-growth-notes/id1202148489)
