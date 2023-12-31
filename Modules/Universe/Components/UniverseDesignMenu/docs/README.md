# 菜单 Menu

## 简介

菜单是显示临时表面上的选项列表，提供了快捷创建弹出菜单的能力。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignMenu'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignMenu
```

## 普通菜单

::: showcase collapse=false
<SiteImage
    width = "120"
    height = "265"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/menu/ud_menu.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/menu/ud_menu_dm.png"
/>

```swift
/// 创建菜单选项列表
var action1 = UDMenuAction(title: "扫一扫", icon: UDIcon.scanOutlined, tapHandler: handler1)
var action2 = UDMenuAction(title: "创建群组", icon: UDIcon.groupOutlined,tapHandler: handler2)
var action3 = UDMenuAction(title: "创建文档", icon: UDIcon.addDocOutlined, tapHandler: handler3)
var action4 = UDMenuAction(title: "新会议", icon: UDIcon.newJoinMeetingOutlined, tapHandler: handler4)
var action5 = UDMenuAction(title: "加入会议", icon: UDIcon.joinMeetingOutlined, tapHandler: handler5)
var actions:[UDMenuAction] = [action1, action2, action3, action4, action5]

/// 创建菜单实例
let menu = UDMenu(actions: actions)

/// 弹出菜单
func click() {
    menu.showMenu(sourceView: sourceView, sourceVC: sourceVC)
}
```

:::

## 设置菜单辅助文字

你可以在创建完 [action](#udmenuaction) 后，设置其`subTitle`属性，来为该菜单项添加描述文字。

::: showcase collapse=false
<SiteImage
    width = "120"
    height = "178"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDMenu/UDMenu_subTitle.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDMenu/UDMenu_subTitle_dm.png"
/>

```swift
var action1 = UDMenuAction(title: "扫一扫", icon: UDIcon.addDocOutlined, tapHandler: handler)
var action2 = UDMenuAction(title: "创建群组", icon: UDIcon.groupOutlined, tapHandler: handler)
var action3 = UDMenuAction(title: "创建团队", icon: UDIcon.teamAddOutlined, tapHandler: handler)
action1.subTitle = "这是扫一扫的说明文字"
var actions:[UDMenuAction] = [action1, action2, action3]
```

:::

## 禁用某一个菜单选项

你可以在创建完 [action](#udmenuaction) 后，设置其`isDisabled`属性，来确认是否禁用该菜单选项。

::: showcase collapse=false
<SiteImage
    width = "120"
    height = "158"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDMenu/UDmenu_ban.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDMenu/UDmenu_ban_dm.png"
/>

```swift
var action1 = UDMenuAction(title: "扫一扫", icon: UDIcon.addDocOutlined, tapHandler: handler)
var action2 = UDMenuAction(title: "创建群组", icon: UDIcon.groupOutlined, tapHandler: handler)
var action3 = UDMenuAction(title: "创建团队", icon: UDIcon.teamAddOutlined, tapHandler: handler)
action1.isDisabled = true
var actions:[UDMenuAction] = [action1, action2, action3]
```

:::

## 自定义菜单

你可以在实例化菜单时，传入[`config`](#udmenuconfig)控制菜单的位置，[`style`](#udmenustyleconfig)控制菜单的样式。

```swift
let config = UDMenuConfig(position: .topLeft)
var style = UDMenuStyleConfig.defaultConfig()
style.cornerRadius = 8
style.menuItemBackgroundColor = UIColor.gray
style.menuItemSelectedBackgroundColor = UIColor.darkGray
style.menuItemSeperatorColor = UIColor.gray
style.menuColor = UIColor.gray
style.maskColor = UIColor.darkGray.withAlphaComponent(0.5)
menu = UDMenu(actions: actions, config: config, style: style)
```

## API 及配置列表

### UDMenuAction

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
title<SiteTableRequired />| - | 菜单选项标题
icon<SiteTableRequired />| - | 菜单选项图标
showBottomBorder|false| 是否显示边框
tapHandler|nil| 点击事件

**为了更好的显示效果，可以将 icon 的`renderMode`设定为`template`，icon 显示颜色与 title 颜色会更加匹配（也可以手动指定）。**

#### 属性

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
subTitle|nil| 选项副标题
isDisabled|false| 该选项是否被禁用
attributedTitle|nil| 选项标题使用富文本进行配置
hasBadge|false| 选项是否开启小红点
tapDisableHandler|nil| 选项禁用后的点击事件

**菜单副标题选项默认至多两行，自动换行，如果有场景需要副标题以一行显示，则需要配置`UDMenuStyleConfig`中的`showSubTitleInOneLine`属性。**

### UDMenu

负责接收外部传入的各种参数、创建 Menu 实例 (UIViewController)，并弹出菜单。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
sourceView<SiteTableRequired />| - | 触发 Menu 的锚点 View
sourceVC<SiteTableRequired />| - | 触发 Menu 的 ViewController
animated|true| 是否显示动画
completion|nil| 菜单显示后回调
dismissed|nil| 菜单关闭后回调

### UDMenuConfig

菜单控制显示位置的配置为[`UDMenuConfig`](#udmenuconfig)。默认显示规则：

- 若显示空间足够的情况下，Menu 会显示在触发区域的底部，并保持居对齐
- 若底部空间不够且触发区域顶部空间大于底部空间，则会显示在触发区域顶部
- 若居中对齐时两侧空间不够，则会自动切换至左 / 右对齐

6 种情况的位置均可手动强制指定：
<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
auto| 默认显示规则
topAuto|Menu 处于起始 view 的上方，默认居中，边界空间不足是自动切换左右对齐
topLeft|Menu 处于起始 view 的上方，并保持右侧对齐
topRight|Menu 处于起始 view 的上方，并保持右侧对齐
bottomAuto|Menu 处于起始 view 的下方，默认居中，边界空间不足是自动切换左右对齐
bottomLeft|Menu 处于起始 view 的下方，并保持左侧对齐
bottomRight|Menu 处于起始 view 的下方，并保持右侧对齐

### UDMenuStyleConfig

菜单样式配置为[`UDMenuStyleConfig`](#udmenuconfig)，可以配置 Menu 字体、颜色、间距、大小等参数。

可以使用`defaultConfig()`方法拿到默认样式配置。

也可以通过属性访问的形式，修改特定属性。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
maskColor|menu 背景遮罩层颜色 |UIColor|UDColor.neutralColor14.withAlphaComponent(0.3)
menuColor|menu 列表的背景色 |UIColor|UDColor.neutralColor1
menuShadowSize|menu 列表的阴影大小 |UDMenuShadowSize|.medium
menuShadowPosition|menu 列表阴影位置 |UDMenuShadowType|.down
menuWidth|menu 列表的宽度 |CGFloat|132
cornerRadios|menu 列表的圆角大小 |CGFloat|4
marginToSourceY|menu 列表距离触发区的垂直距离 |CGFloat|UDSytleTheme.smallRadius
marginToSourceX|menu 列表距离触发区的水平距离 |CGFloat|UDSytleTheme.smallRadius
menuListInset|menu 列表项第一项和最后一项额外增加的距离边缘的 Inset|CGFloat|8
menuItemHeight|menu 列表项的高度 |CGFloat|48
menuItemIconWidth|menu 列表项的 icon 宽高 |CGFloat|20
menuItemIconTintColor|menu 列表项 icon 的主色，传入 icon 的 renderMode 为 template 时生效 |UIColor|neutralColor11
menuItemTitleColor| menu 列表项的标题色 |UIColor|neutralColor12
menuItemTitleFont| menu 列表项的标题字体 |UIFont|UDFont.body2
menuItemBackgroundColor| menu 列表项的背景色 |UIColor|neutralColor1
menuItemSeperatorColor| menu 列表间隔线的颜色 |UIColor|neutralColor5
menuItemSelectedBackgroundColor| menu 列表项被选中时的背景色 |UIColor|neutralColor4
showSubTitleInOneLine| 是否 subTitle 只以一行显示 |Bool|false

### UDMenu 接口

#### showMenu

弹出菜单。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
actions<SiteTableRequired />| - | 菜单选项集合
config|UDMenuConfig|UDMenuConfig()| 菜单位置配置
style|UDMenuStyleConfig|UDMenuStyleConfig.defaultConfig()| 菜单外观配置

#### 注意：当前未对触发线程进行检查，需要在主线程触发 showMenu 方法，回调方法也会在主线程执行。
