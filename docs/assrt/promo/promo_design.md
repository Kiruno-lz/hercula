
全部图片尺寸：1920×1080px

### 字体规格

标题字体：PingFang SC Semibold

标题字号：82px

标题颜色：#35433D

标题位置：水平居中，视觉中心约距顶部 175px

品牌副标题字体：PingFang SC Regular

品牌副标题字号：30px

品牌副标题颜色：#586F64

品牌副标题字间距：2.5px

品牌副标题位置：水平居中，视觉中心约距顶部 285px


### 背景基础色

- 基础底色：`#FDFAF6`
- 暖白高光：`#FFFBF6`
- 暖杏色：`#F3D5C0`
- 雾绿色：`#D9E9E1`
- 右侧浅绿终点：`#F2F6F1`

### 主背景渐变

```css
background-color: #FDFAF6;

background-image:
  radial-gradient(
    ellipse 58% 72% at 12% 72%,
    rgba(243, 213, 192, 0.23) 0%,
    rgba(243, 213, 192, 0) 72%
  ),
  radial-gradient(
    ellipse 60% 72% at 91% 72%,
    rgba(217, 233, 225, 0.20) 0%,
    rgba(217, 233, 225, 0) 72%
  ),
  linear-gradient(
    110deg,
    #FDF8F1 0%,
    #FFFBF6 46%,
    #F2F6F1 100%
  );
```

### 顶部文字区域遮罩

为了保证四张图文字区域一致，顶部再叠加一层：

```css
background: linear-gradient(
  to bottom,
  #FCF9F4 0%,
  #FCF9F4 83.333%,
  rgba(252, 249, 244, 0) 100%
);
height: 360px;
```

对应关系：

- `0–300px`：`#FCF9F4`
- `300–360px`：从 `#FCF9F4` 逐渐透明
- `360px` 以下：恢复主背景渐变

颜色空间统一使用 `sRGB`，所有色值为 8-bit HEX/RGB。