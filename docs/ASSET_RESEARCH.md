# 开源素材候选审计（2026-08-24）

## 目标与筛选维度

本项目需要俯视角实时动作、修仙题材、可收集灵兽和统一的东方幻想视觉。候选按许可证明确度、商用与改作权限、动作覆盖、风格一致性、Godot 集成成本筛选。“免费”但来源或授权不清晰的素材不进入候选。

## 候选集合

| 候选 | 可用范围 | 许可证证据 | 纳入判断 |
| --- | --- | --- | --- |
| [Kenney RPG Base](https://kenney.nl/assets/rpg-base) | 通用地形与物件，230 个 2D 文件 | 官方页面标记 CC0 | 纳入后续环境美术候选；授权清晰、集成成本低 |
| [Kenney Fantasy UI Borders](https://www.kenney.nl/assets/fantasy-ui-borders) | 140 个奇幻 UI 边框 | 官方页面标记 CC0 | 纳入后续 UI 装饰候选；不承担项目核心身份视觉 |
| [Kenney UI Pack: RPG Expansion](https://kenney.nl/assets/ui-pack-rpg-expansion) | 85 个 RPG 控件 | 官方页面标记 CC0 | 纳入后续可访问性与设置界面候选 |
| [Puny Characters](https://opengameart.org/content/puny-characters) | 八方向移动、剑/弓/法杖、投掷、受伤和死亡动画 | OpenGameArt 页面标记 CC0 | 动作覆盖好，但 16×16 西幻像素风与修仙核心角色方向不符；暂不导入 |
| [Zelda-like tilesets and sprites](https://opengameart.org/content/zelda-like-tilesets-and-sprites) | 户外/洞穴/室内、角色、特效、UI | OpenGameArt 页面标记 CC0 | 完整但视觉辨识度偏传统像素冒险；仅保留为原型备选 |
| [16×16 Animated Critters](https://opengameart.org/node/39867) | 兔、鸡、蜘蛛、史莱姆动画 | OpenGameArt 页面标记 CC0 | 可作通用生态小动物，不能覆盖修仙灵兽阵容 |

## 最终结论

- 通用 UI 与环境：优先从 Kenney CC0 候选中选择，下载前固定视觉规格并登记文件级来源。
- 主角、五种核心灵兽、精英首领和标题视觉：当前候选没有同时满足修仙语义、动作覆盖和风格统一的开源资源，使用 GPT Image 2 建立原创视觉锚点，再进行切图和 Godot 动画适配。
- 当前不立即导入像素包：纵切片仍采用可替换的程序化绘制，避免在运行验收前锁死分辨率和美术方向。
- GPT Image 2 生成当前受本机缺少 `OPENAI_API_KEY` 阻塞；不得在聊天、源码、日志或产物中暴露密钥。

## 本轮落地

- 已从 Fantasy UI Borders 1.0 中筛选 `panel-border-024.png`，以原文件入库并在 Godot 中运行时着色、九宫格拉伸。
- RPG Base 已下载到忽略提交的临时审计区并完成视觉比对；因高饱和西式卡通地形与青绿修仙氛围冲突，没有进入正式资产目录。
- 音效补充采用 Kenney RPG Audio 的 6 个通用动作反馈，以及 JaggedStone 在 OpenGameArt 以 CC0 发布的 3 个魔法反馈；正式目录只保留代码实际引用的文件。
