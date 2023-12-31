# 阴影 Shadow

## 简介

阴影组件提供了对 View 添加阴影的能力。含有 5 种强度，上下左右四个方向的阴影。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignShadow'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignShadow
```

## 为控件添加预设阴影类型

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "100"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDCardHeader/shadow_s5.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDCardHeader/shadow_s5.png"
    />

```swift
view.layer.ud.setShadow(type: .s5Down)
```

:::

组件内置了以下阴影类型：

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
s1Down | 强度 1，朝下
s1DownPri | 强度 1，朝下，主题色
s1Up | 强度 1，朝上
s1Left | 强度 1，朝左
s1Right | 强度 1，朝右
s2Down | 强度 2，朝下
s2DownPri | 强度 2，朝下，主题色
s2Up | 强度 2，朝上
s2Left | 强度 2，朝左
s2Right | 强度 2，朝右
s3Down | 强度 3，朝下
s3DownPri | 强度 3，朝下，主题色
s3Up | 强度 3，朝上
s3Left | 强度 3，朝左
s3Right | 强度 3，朝右
s4Down | 强度 4，朝下
s4DownPri | 强度 4，朝下，主题色
s4Up | 强度 4，朝上
s4Left | 强度 4，朝左
s4Right | 强度 4，朝右
s5Down | 强度 5，朝下
s5DownPri | 强度 5，朝下，主题色
s5Up | 强度 5，朝上
s5Left | 强度 5，朝左
s5Right | 强度 5，朝右
