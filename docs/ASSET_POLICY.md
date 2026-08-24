# 素材策略与第三方登记

## 当前状态

当前纵切片的整张青岚谷、主角、导师和五种灵兽均由内置 OpenAI 图像生成接口产出并接入 Godot。修士与五种灵兽均使用 4×4 四向动画表；移动时播放四帧步态、跳跃、飞行、爬行或奔跑循环，攻击前摇切入高张力帧并叠加脉冲，受击继续使用闪色与像素轮廓。原始高分辨率素材同时用于对话及战斗切入。战斗特效仍由 `CanvasItem` 绘图 API 与原创 `icon.svg` 构成。HUD 装饰边框采用经过筛选的 Kenney CC0 素材。

## 后续引入准则

- 只采用许可证明确的资源；优先 CC0，其次允许商用与改作且可满足署名义务的 CC BY / MIT 类资源。
- 不采用仅限个人使用、禁止改作、来源不明或许可证页面无法留档的资源。
- 每项素材必须登记：名称、来源 URL、作者、许可证、下载日期、修改内容、项目路径。
- 生成式素材必须记录最终提示词、使用模型、生成日期和后续人工修改。
- 项目专属主角、关键灵兽、首领和品牌视觉优先保持统一原创风格，不拼贴互不相容的素材包。

## 第三方素材清单

| 名称 | 来源 | 作者 | 许可证 | 项目路径 | 修改 |
| --- | --- | --- | --- | --- | --- |
| Fantasy UI Borders `panel-border-024.png` | https://kenney.nl/assets/fantasy-ui-borders | Kenney | CC0 1.0 | `assets/third_party/kenney/fantasy_ui_borders/` | 无文件修改；运行时着色与九宫格拉伸 |
| RPG Audio（6 个选定 OGG） | https://kenney.nl/assets/rpg-audio | Kenney | CC0 1.0 | `assets/third_party/kenney/rpg_audio/` | 无文件修改；运行时音量与轻微音高变化 |
| Magic Spell SFX（3 个选定 OGG） | https://opengameart.org/content/magic-spell-sfx | JaggedStone | CC0 1.0 | `assets/third_party/opengameart/magic_spell_sfx/` | 无文件修改；运行时音量与轻微音高变化 |

生成素材的请求链、透明度失败稿淘汰记录、最终提示词和动作表的可复现轮廓清理参数见 `assets/generated/core/SOURCE.md`。当前实机使用为小世界显示重新简化、留足单元格边距并剥离底色的动作表：玉兔与白鹤为 `v5`，进一步提高孤立块阈值的火狐与狻猊为 `v6`；玄甲龟原始 `v2` 无彩屑，使用独立亮度参数补足小尺寸可读性。
