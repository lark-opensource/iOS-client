# 字体 Font

## 简介

字体系统可以统一端内字体，并且实现动态替换等功能。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignFont'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignFont
```

## 使用

### FontTheme

FontTheme 主要是为了 Universe Design Component 字体主题化而提供的相关数据结构。

目前 UDFont 已提供了字体固定样式，无特殊需求无需扩展。并且为了方便使用，UDFont 针对 UIFont 做了拓展，可以在 ud 的属性下使用相关字体。

````swift
let font = UDFont.caption3
let font1 = UIFont.ud.caption3
````

UDFont 提供 Store 字典，支持用户根据对应的 Key 设置全局该字体的值，如修改[`caption3`](#udfont-字体对照表)的大小。

````swift
let storeMap = UDColor.getCurrentStore()
storeMap[.caption3] = UDColor.caption2
````

如此修改则会将全局使用`caption3`的 key 的字体修改为`caption2`对应的字号大小。

## API 及配置列表

### UDFont 字体对照表

变量名 | key | size | weight
:----:|:-----:|:------:|:-------:
title0 | title0 | 26 | semibold
title1 | title1 | 24 | semibold
title2 | title2 | 20 | medium
title3 | title3 | 17 | medium
title4 | title4 | 17 | regular
body | body | 16 | regular
body1 | body1 | 14 | regular
headLine | headLine | 14 | medium
caption1 | caption1 | 12 | regular
caption2 | caption2 | 10 | medium
caption3 | caption3 | 10 | regular
