# 核心生成素材登记

- 生成日期：2026-08-24
- 生成接口：Codex 内置 OpenAI `image_gen`
- 模型记录：内置接口未返回底层模型标识，不虚构具体版本；未使用本地 API Key 或第三方模型
- 用途：整张青岚谷、主角、导师和五种灵兽均已接入实时场景；高分辨率原图同时供对话、御灵、同契与结契切入层使用
- 通用约束：原创修仙题材、透明 Alpha、无文字、无商标、无水印

## `wanderer-portrait.png`

生成结果：`exec-77c9cc99-664f-4dce-8236-12dad2ea9074.png`

最终提示词：

> A single original wandering Chinese immortal cultivator for a top-down real-time action RPG; full body with slim jian sword, dark high-tied hair, layered jade-green and deep teal robes, warm ivory and pale-gold accents; polished hand-painted 2D game art with Chinese ink-wash influence and crisp cel shading; isolated on genuine transparent alpha; no scenery, text, logo, watermark, frame, shadow, or cropped limbs.

## `wanderer-world.png`

生成链：以主角立绘作身份参考，派生四头身俯视战斗精灵；首次派生图把棋盘格烘焙进 RGB，未入库；随后只做背景提取并经像素 Alpha 检查通过。最终结果：`exec-3c418842-c9b4-42bd-82a4-da0b34f54b48.png`。

最终提示词：

> Preserve the same cultivator identity, jade-green and ivory layered robes, dark high-tied hair, pale-gold accents and slim jian; redraw as a compact four-head-tall real-time world sprite in orthographic three-quarter top-down view facing lower-right; polished hand-painted 2D cel shading; remove only the checkerboard background and replace it with genuine transparent alpha; preserve clean hair, ribbon, robe, sword and boot edges; no halo, shadow, text, watermark or new elements.

## `jade-hare-world.png`

生成结果：`exec-7f38469c-c00f-4908-ae77-337d41b02038.png`

最终提示词：

> A single original Jade Moon Hare spirit companion for a Chinese xianxia action RPG; compact mystical hare with long upright ears, jade-green fur, pale mint belly and tail, crescent forehead mark, leaf-shaped jade ornaments and short spirit ribbons; calm protective expression; polished hand-painted 2D sprite, crisp cel shading, subtle Chinese ink-wash influence, orthographic three-quarter top-down view facing lower-right; genuine transparent alpha; one creature and pose; no scenery, shadow, text, logo, watermark or frame.

## `ember-fox-world.png`

生成过程：带参考的首稿把棋盘格烘焙进 RGB，背景提取又错误生成氛围场景，二者均未入库；最终重新独立生成透明版。最终结果：`exec-6cbd3568-6cf7-41d3-adb3-0adbc3cab9a8.png`。

最终提示词：

> One original Ember-Tail Spirit Fox companion for a Chinese xianxia action RPG; compact agile fox with burnt-orange and vermilion fur, cream muzzle and chest, exactly one flame-shaped tail, fire forehead sigil, red jade collar ornament and short spirit ribbons; polished hand-painted 2D cel-shaded sprite with subtle Chinese ink-wash influence; orthographic three-quarter top-down pouncing stance; genuine transparent PNG alpha with no checkerboard, background, shadow, text, logo, watermark, frame or particles outside the silhouette.

## `cloud-crane-world.png`

最终结果：`exec-ec4ec91f-8c5c-4dd9-a47b-166da986cc84.png`。带参考的首稿出现假透明棋盘格，已淘汰。

> One original Cloud-Feather Immortal Crane; white and pale-cyan feathers, dark-teal wing tips, jade crest, long ribbon-like tail feathers and wind markings; polished hand-painted 2D xianxia game sprite, orthographic three-quarter top-down view; actual transparent alpha; no checkerboard, background, text or watermark.

## `stone-tortoise-world.png`

最终结果：`exec-d25dab9b-be96-4f84-aa77-7bad5dbc4d75.png`。

> One original Mystic Stone Tortoise; moss-green skin, broad slate shell with golden mountain-trigram pattern and jade crystals, heavy defensive silhouette; polished hand-painted 2D xianxia game sprite, orthographic three-quarter top-down view; actual transparent alpha; no background, text or watermark.

## `thunder-cub-world.png`

最终结果：`exec-7bbe5bef-d52e-42c5-bd44-77f152b1dcb9.png`。

> One original Violet-Thunder Suanni cub elite; deep violet fur, lavender mane, swept thunder horns, gold forehead seal and restrained lightning markings; compact boss silhouette, polished hand-painted 2D xianxia game sprite, orthographic three-quarter top-down view; actual transparent alpha; no background, text or watermark.

## `mentor-portrait.png`

最终结果：`exec-8f76d8ec-b4c7-4926-b525-c06352ddf5cb.png`。

> One original elder cultivator mentor Qingxu Sanren; gray topknot, white beard, layered slate-blue and cyan robes, jade sash and bamboo slip; full-body hand-painted Chinese xianxia character art; transparent Alpha; no text, logo or watermark.

## `qinglan-valley-map.png`

最终结果：`exec-48260fa2-cf17-448b-a953-19d65342483e.png`。

> Complete orthographic top-down Qinglan Valley game map: main road crosses the center, pale-gold sanctuary at exact center, turquoise spirit spring in the northeast, bamboo groves north-center and southeast, stone outcrops around the outer thirds; hand-painted Chinese ink-wash/cel-shaded environment, broad playable surfaces, no characters, creatures, text, UI or watermark.

## `wanderer-walk-sheet-v2.png`

生成链：以 `wanderer-world.png` 为身份与服装参考生成 4×4 四向步态表；首稿 `exec-f0f5c617-9cbf-46b3-a08c-c2ed492ffd08.png` 的棋盘格被烘焙进 RGB，未接入；随后仅提取背景并经 Alpha 检查通过。最终结果：`exec-1b9461db-c8a3-47c4-a959-fc2adc3b23c1.png`。实际行序为正面、向右、向左、背面，每行四个脚步帧。

> Preserve the exact cultivator identity, face, high ponytail, emerald-and-white robes, gold-and-jade ornaments, boots and sword; create exactly sixteen equal-scale full-body chibi world sprites in a 4-by-4 sheet with four walk frames for front, side and back directions; identical cell padding and ground baseline; transparent background; no labels, grid lines, cropped parts, extra limbs, text or watermark. Remove only the baked checkerboard and replace it with genuine Alpha while preserving all frames and positions.

## `jade-hare-hop-sheet-v2.png`

生成链：以 `jade-hare-world.png` 为身份与饰品参考生成 4×4 四向跳跃表；首稿 `exec-fde5150f-8c07-4ae6-8edb-96c49def2714.png` 为假透明棋盘格；背景提取结果 `exec-60a62055-58f4-400a-aec6-745c05f9d46c.png` 具有真实 Alpha 并入库，低 Alpha 边缘噪点由专用材质截断；二次清理稿 `exec-3b29e0ac-9b8c-41c5-a029-72a7f3625dd3.png` 再次烘焙棋盘格，已淘汰。实际行序为正面、向右、向左、背面，每行四个跳跃帧。

> Preserve the exact mint-and-white moon hare, emerald eyes, crescent forehead mark, gold-and-jade ear jewelry, collar, ribbons and fluffy tail; create exactly sixteen equal-scale full-body sprites in a 4-by-4 sheet with four hopping frames for front, side and back directions; identical cell padding and baseline; transparent background; no labels, grid lines, cropped ears or ribbons, extra limbs, text or watermark. Remove only checkerboard pixels and retain clean antialiased Alpha around fur and ribbons.

## `ember-fox-run-sheet-v2.png`

生成链：以 `ember-fox-world.png` 为身份、单尾与饰品参考生成 4×4 四向奔跑表；首稿 `exec-df8030c4-cbce-4313-82d9-fb75cf6bfd99.png` 为假透明棋盘格，未接入；背景提取结果 `exec-2a8ad108-bca0-4c8e-bf79-274c9038a17f.png` 具有真实 Alpha，低 Alpha 火色边缘噪点由同一专用材质截断。实际行序为正面、向右、向左、背面，每行四个奔跑帧。

> Preserve the exact orange-red spirit fox, cream muzzle, forehead flame sigil, amber eyes, red-jade bell, teal tassel, gold ornaments, two short ribbons and exactly one enormous flame-shaped tail; create exactly sixteen equal-scale full-body sprites in a 4-by-4 sheet with four running frames for front, right, left and back directions; identical padding and baseline; transparent background; no labels, grid lines, cropped tail or paws, additional tails, extra limbs, text or watermark. Remove only the baked checkerboard and retain clean antialiased Alpha.

## `cloud-crane-flight-sheet-v2.png`

生成链：以 `cloud-crane-world.png` 为身份、羽色、冠饰与长尾羽参考生成 4×4 翼拍表；首稿 `exec-1c4f7402-4740-4119-a0ec-b2a5f5eed684.png` 为假透明棋盘格；首次背景提取 `exec-02a667c9-df4d-4479-a1e9-592c2a98326a.png` 擅自加入蓝灰渐变和光晕，已淘汰；第二次严格提取 `exec-43068e77-ca4e-4ea2-aa2a-94b9226b3669.png` 经 Alpha 检查通过并入库。实际行序为正面、向左、向右、背面，每行四个翼拍帧；代码为仙鹤单独交换左右行。

> Preserve the exact white-and-cyan Cloud-Feather Immortal Crane, dark teal wing tips, gold beak, red eyes, jade-gold crest, two wings, two legs and long marked tail feathers; create exactly sixteen equal-scale sprites in a 4-by-4 sheet with four hovering or gliding wingbeat phases for front, side and back directions; no cropped feathers or extra wings. Delete every checkerboard and background pixel so all non-crane pixels have alpha 0; no gradient, glow, shadow, scenery, text or watermark.

## `stone-tortoise-crawl-sheet-v2.png`

生成链：初稿 `exec-1d600ad6-60a8-4b7c-a468-6632478b84d1.png` 为假透明；背景提取 `exec-afa369fe-7920-4efc-b54f-93af3269e4d7.png` 仍是不透明白底，第二次提取 `exec-720756a9-ac8d-4477-9860-86e96e4098fe.png` 又生成渐变场景，均淘汰；重新生成稿 `exec-0d623c4f-fe92-45e5-9a3d-8a28a0ba4f9a.png` 仍为假透明，最终仅删除该稿棋盘格得到 `exec-7bb327b1-6fa3-4fae-bc7d-f7b13bd72ac2.png`，经 Alpha 检查后入库。实际行序为正面、向右、向左、背面，每行四个负重爬行帧。

> Preserve the same moss-green stone skin, massive dark segmented shell, gold mountain-trigram plate, emerald shell crystals, gold brow horns, four heavy legs, claws and short tail; create a strict 4-by-4 sheet with four heavy crawling frames for front, right, left and back directions. Remove only the alternating gray-white squares; every non-tortoise pixel and corner must have alpha 0; no opaque background, gradient, glow, shadow, scenery, text or watermark.

## `thunder-cub-run-sheet-v2.png`

以 `thunder-cub-world.png` 为身份、双角、雷纹、金饰和单尾参考直接生成；结果 `exec-1e80cbc6-6cc5-4c46-b8d1-e2a4e69422df.png` 首次即为真实 Alpha，尺寸可被 4×4 精确切分。实际行序为正面、向右、向左、背面，每行四个疾跑帧；低 Alpha 雷缘噪点由专用材质截断。

> Preserve the exact indigo-violet Suanni cub, lavender mane, violet eyes, two swept lightning horns, gold forehead seal, cloud armor, glowing body markings, four feline paws and exactly one long tufted tail; create exactly sixteen equal-scale sprites in a 4-by-4 sheet with four powerful run frames for front, right, left and back directions; genuine transparent alpha; no extra horns, tails or limbs, projectiles, scenery, text or watermark.

## `*-sheet-v3.png` / `*-sheet-v4.png` / `*-sheet-v5.png` 轮廓精修

五灵兽实机同屏验收发现玉兔、火狐、仙鹤和狻猊的透明区仍含少量彩色残屑。先以 imagegen 对四张动作表执行“保持 4×4 布局与动作不变，只删除轮廓外色屑”的编辑：首轮结果为 `exec-2c54550a-cd92-4eb1-ba56-5d92aaf1719b.png`、`exec-3c2349e1-211b-4635-a935-665a4a230ed5.png`、`exec-57ccd2df-c48f-42d7-a5cf-21d05f4eefb9.png`、`exec-ff46e8ab-b3c4-456e-8332-5ed6e1bc9b5f.png`；其中前两张烘焙了棋盘格，后两张仍有彩边。随后两轮背景剥离与严格轮廓编辑结果 `exec-ff34ad43-c1bd-42d8-b6e6-dc1756e5854e.png`、`exec-91b3a4cf-7e48-4cbc-a83a-f3c4a100a0e1.png`、`exec-6a4af80f-9349-4967-902e-c641df527d98.png`、`exec-dc96a547-6078-474d-9c89-ef075964ce09.png`、`exec-98f40939-3785-4b65-9927-b49dcde9329b.png`、`exec-6625bf20-beb2-4315-810e-4244e090a694.png`、`exec-c2781b4d-660d-4c9a-808b-054049b66ea2.png`、`exec-7e184143-3cbe-4ae2-80b5-f1ce7ded7127.png` 仍在“假透明棋盘格”和“重新产生低 Alpha 彩边”之间反复，全部拒绝入库。

imagegen 精修提示词集合：

> Edit this exact 4 columns by 4 rows transparent game sprite sheet. Preserve the character design, every pose, exact frame order, spacing and canvas size. Remove every colored edge speck, halo, dust pixel, detached particle and stray colored fragment outside the silhouette in all 16 cells. Keep legitimate anatomy and ornaments intact. No shadow, glow, background, grid or labels. Output one clean RGBA sprite sheet with true alpha transparency.

> Transparency repair only. The gray and white checkerboard is baked into the image and must be completely removed. Convert every checkerboard or background pixel to true alpha transparency while preserving all sixteen poses, character pixels, spacing, frame order and canvas size. No checker pattern, colored fringe, shadow, glow, dust or detached pixels. Output RGBA PNG with corner alpha exactly zero.

由于生成式背景剥离连续三轮无法同时满足“真 Alpha + 无彩边”，改用可复现的保守后处理 `tools/cleanup_sprite_sheet.ps1`。`v3` 先以 Alpha 32 为阈值、按每个动作格做八邻域连通域去噪；实机复验进一步发现部分侧向动作靠近格边，邻帧尾脚仍可能串入当前帧。

最终接入的 `v4` 从上述 imagegen 无彩屑精修稿中启用 `-OpaqueCheckerboard`：仅从画布外缘洪泛删除高亮中性棋盘背景，再按动作格清理不连通碎片。玉兔与火狐使用主体面积 0.5% 的保守阈值，白鹤使用 200 像素下限以保留长尾羽，狻猊使用 1000 像素下限以保留主体与大尾并删除邻帧脚爪碎块。最终文件为 `jade-hare-hop-sheet-v4.png`、`ember-fox-run-sheet-v4.png`、`cloud-crane-flight-sheet-v4.png`、`thunder-cub-run-sheet-v4.png`；`stone-tortoise-crawl-sheet-v2.png` 原图无彩屑，继续使用并在材质中单独提升亮度。

`v4` 实机复验虽然去除了彩屑，却暴露旧稿本身把尾、脚和饰带画成断开装饰块。为匹配“小世界 RPG 动作 + 高清立绘切入”的显示策略，重新生成简化轮廓、无长饰带、每格至少 12% 安全边距的动作表：玉兔 `exec-b41adbc0-5761-422a-b7d7-b4db95d71d6d.png`、火狐 `exec-719216d5-05af-401f-b2d1-8fe36b49be54.png`、白鹤 `exec-c7bb79ad-6426-40eb-b935-623ea9003ee6.png`。狻猊首稿 `exec-30cd2556-2a75-48cd-a4c2-4d16283b78ad.png` 每行第 4 格误画为背面，淘汰；方向修正版为 `exec-f8ec4ecf-cde1-4cdd-9534-081ea0ac89ce.png`。四稿均为假透明或不透明底，使用 `tools/cleanup_sprite_sheet.ps1` 的外缘洪泛模式确定性转为真 Alpha，输出并最终接入 `jade-hare-hop-sheet-v5.png`、`ember-fox-run-sheet-v5.png`、`cloud-crane-flight-sheet-v5.png`、`thunder-cub-run-sheet-v5.png`。

火狐与狻猊的 `v5` 实机移动行仍各出现 133–286 像素的孤立底色块；由于简化稿的身体和尾巴已连成单一主体，对这两个物种将最小连通域提高到 300 像素，输出并接入 `ember-fox-run-sheet-v6.png` 与 `thunder-cub-run-sheet-v6.png`。玉兔、白鹤继续使用 `v5`，玄甲龟继续使用 `v2`。

`v5` 生成提示词核心约束：

> Redraw this as a production-ready small-world RPG sprite sheet while preserving the creature identity and palette. Exactly 4 columns by 4 rows with four motion phases for front, side and back directions. Simplify fine jewelry and long loose ornaments. Every frame must be one connected readable silhouette, fully contained inside its own equal cell, with at least 12 percent empty transparent gutter on every cell edge. No frame may overlap or leak into another cell. Consistent scale and crisp cel shading readable at 70 screen pixels. No particles, detached elements, shadows, glow, grid, labels, text or watermark.

狻猊方向修正追加约束：

> Enforce direction by entire row: row 1 must contain four FRONT-facing run phases, row 2 four RIGHT-facing run phases, row 3 four LEFT-facing run phases, row 4 four BACK-facing run phases. No cell in rows 1 through 3 may show the back.
