# 月迹 / hercula product promo demo

26 秒、1920×1080、30fps 的可编辑 Remotion 宣传片 Demo。

## 时间线

| 时间 | 内容 |
| --- | --- |
| 0–3s | 经期标记同尺寸圆点、脉冲与日期显现 |
| 3–7s | 圆形涟漪展开为真实单屏日历，玻璃外框与品牌锁定 |
| 7–10s | 操作按钮开合特写，镜头拉回完整界面，背景色与浮动光斑同步换肤 |
| 10–15s | 滚动布局下移至历史预测模块，靛蓝主题稳定 |
| 15–24s | compact → dual → single → compact，模拟折叠设备运行时切换 |
| 24–26s | 真实 UI 收束回标记圆点，品牌与“简单记，月月迹，更懂你”落定 |

工程使用真实运行时截图作为页面纹理，动画只负责相机、景深、遮罩、玻璃外框、主题换肤和设备状态过渡。

## 运行

```bash
npm install
npm run dev
npm run render
npm run render:nobgm
```

输出位于 `out/`。宣传素材与验收静帧位于 `/Users/kiruno/Documents/_code/vibe/hercula/docs/assrt/promo-video/`。

## 可改参数

- 所有镜头边界：`src/Promo.tsx` 中各场景的 `frame` 区间。
- 主题色与背景：`THEMES`、`COLOR_PHASES`。
- BGM 与音效：`AudioRig`。
- 真实页面纹理：`public/ui/`。
