# 空状态 Empty

空状态用于对内容、结果为空，或是整个动作完成的即时反馈。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignEmpty'
```

接着，执行以下命令：

```bash
pod install
```

### 引入

引入组件：

```swift
import UniverseDesignEmpty
```

## 使用

## 普通的空状态视图

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "136"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_dm.png"
/>

```swift
var empty = UDEmptyView(.noContent)
empty.title = "无内容"
```

:::

## 添加说明文字

组件提供了两种方式来应对不同的说明文字场景需求。

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "160"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_desc.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_desc_dm.png"
/>

```swift
var empty = UDEmptyView(.noContent)
empty.title = "无内容"
// 设置为 string 类型
emptyView.detail = "无内容，等等再来看吧"
// 设置为 NSAttributedString 类型
emptyView.setDetail("无内容，等等再来看吧")
```

:::

## 添加说明文字超链接操作

组件提供了[`setDetailActionText()`](#setdetailactiontext)实现对说明文字中的超链接的点击事件处理。

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "160"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_desc.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_desc_dm.png"
/>

```swift
var empty = UDEmptyView(.noContent)
empty.title = "无内容"
emptyView.detail = "无内容，等等再来看吧"
emptyView.setDetailActionText("等等")
```

:::

## 添加操作按钮

组件提供了[`addButton()`](#addbutton)来添加底部按钮。

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "260"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_action.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/emptystate/ud_emptystate_action_dm.png"
/>

```swift
var empty = UDEmptyView(.noContent)
empty.title = "无内容"
emptyView.detail = "无内容，等等再来看吧"
emptyView.addButton("重试", .primary)
emptyView.addButton("取消", .secondary)
```

:::

## API 及配置列表

### UDEmpty

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
type<SiteTableRequired />| - | 空状态插画
scale|.normal| 缩放尺寸

### UDEmpty 属性

<SiteTableHighlight columns="2" type="3" />

属性 | 说明
---|---
emptyType| 空状态类型
imageSize| 特殊场景下空白页图片尺寸
detailFont| 特殊场景下空白页描述文字字体
title| 设置空状态标题文字
detail| 设置空状态描述文字

### UDEmpty 接口

#### setDetailActionText

添加描述文字属性（颜色突出或文字点击事件）。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
actionString<SiteTableRequired />| - | 超链接文字
color|emptyNegtiveOperableColor| 超链接文字颜色
handler|nil| 点击事件

#### addButton

添加按钮。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
title<SiteTableRequired />| - | 按钮标题
type|.primary| 按钮类型
handler|nil| 点击事件
