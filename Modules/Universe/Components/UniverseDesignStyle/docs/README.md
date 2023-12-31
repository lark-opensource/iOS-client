# Universe-UI iOS Style README

> [ESUX - 系统样式规范](https://bytedance.feishu.cn/wiki/wikcnOMgp9ZOTZPU6RkC3qlTjcc)

## 简介

建立样式规范的初衷是为了通过让系统内的元素保持一致、有序。一致的样式，能有效传达产品价值，加深市场与用户对品牌的认知。

通过建立合理的样式规范，一方面能有效提升信息传达的效率，降低用户的认知成本；另一方面，对于跨地域、跨业务的团队合作来说，能有效降低沟通的成本，通过一致的规范与有据可依的设计原则，迅速达成一致。

适当的圆角样式能使界面看起来柔和友好，拉近用户与产品的距离。
通常情况下，圆角的使用遵循面积越大的组件使用越大的圆角，来保持整体视觉的平衡与一致。而在一些需要聚焦的情况下，我们通过打破这样的规则，来引起用户的视觉注意。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignStyle'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignStyle
```

## 使用

### StyleTheme

StyleTheme 主要是为了 Universe Design Component 样式主题化而提供的相关数据结构。

目前 StyleTheme 已提供了圆角固定大小，无特殊需求无需扩展。

````swift
view.layer.cornerRadius = UDStyle.lessSmallRadius
````

UDStyle 提供 Store 字典，支持用户根据对应的 Key 设置全局该圆角的值，如修改`lessSmallRadius`的大小

````swift
let storeMap = UDColor.getCurrentStore()
storeMap[.lessSmallRadius] = UDColor.middleRadius
````

如此修改则会将全局使用`lessSmallRadius`的 key 的值修改为`middleRadius`对应的值。

## API 及配置列表

UDStyle 字体

变量名 | key | size
----|-----|------|
lessSmallRadius | Radius-XS | 2
smallRadius | Radius-S | 4
middleRadius | Radius-M | 6
largeRadius | Radius-L | 8
moreLargeRadius |Radius-XL | 10
