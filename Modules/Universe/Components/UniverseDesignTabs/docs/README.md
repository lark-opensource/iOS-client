# 页签 Tabs

## 简介

页签是将平级信息做模块化分类处理，并可相互之间快速切换查看的组件。

组件不仅支持了页签部分，同时也提供了经常与之联动的 ListContainer，不仅使开发者尽可能的简单实用，同时也增加了开发者的自定义 Tabs 的能力。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignTabs'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignTabs
```

## 页签代理

首先，让我们先构建符合组件要求的子页面作为后续开发的前提。

组件需子视图遵循`UDTabsListContainerViewDelegate`协议，这个协议将实现子视图的生命周期等工作的管理。

下面的代码实现了一个最简单的子视图，并实现了协议中的`listView()`方法，将自身的视图返回给`UDTabs`进行管理。

```swift
class SubVC: UIViewController，UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}
```

## 固定式页签

在初始化页签时，页签所在 viewController 需实现`UDTabsListContainerViewDataSource`协议来获取子视图实例列表和列表数量。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "40"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tab/ud_tab_auto.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tab/ud_tab_auto_dm.png"
    />

1. 申明组件所需变量

```swift
/// 页签视图
var tabsView = UDTabsTitleView()
/// 子视图代理
var subViewControllers: [UDTabsListContainerViewDelegate] = []
/// 子视图映射后的视图
var listContainerView: UDTabsListContainerView = UDTabsListContainerView(dataSource: self)

/// 初始化 3 个 SubVC 视图
var i = 1
while i <= 3 {
   let vc = SubVC()
   subViewControllers.append(vc)
   i += 1
}
```

2. 配置组件相关参数

```swift
// 设置单个页签底部的指示器
let indicator = UDTabsIndicatorLineView()
indicator.indicatorHeight = 2                   // 设置指示器高度

// 设置页签视图
tabsView.titles = ["标签 1"，"标签 2"，"标签 3"]
tabsView.backgroundColor = UIColor.ud.N00       // 设置 tabsView 背景颜色
tabsView.indicators = [indicator]               // 添加指示器
tabsView.listContainer = listContainerView      // 添加子视图

// 设置页签外观配置
let config = tabsView.getConfig()
config.layoutStyle = .average                   // 每个页签平分屏幕宽度
config.isItemSpacingAverageEnabled = false      // 当单个页签的宽度超过整体时，是否还平分，默认为 true
config.itemSpacing = 0                          // 间距，默认为 20
tabsView.setConfig(config: config)              // 更新配置
```

3. 约束视图

```swift
self.view.addSubview(tabsView)
self.view.addSubview(listContainerView)

tabsView.snp.makeConstraints { (make) in
   make.top.equalTo(navigationBar.snp.bottom)
   make.right.equalToSuperview()
   make.left.equalTo(18)
   make.height.equalTo(40)
}

listContainerView.snp.makeConstraints { (make) in
   make.left.bottom.right.equalToSuperview()
   make.top.equalTo(tabsView.snp.bottom)
}
```

4. 实现`UDTabsListContainerViewDataSource`代理方法

```swift
func listContainerView(_ listContainerView: UDTabsListContainerView，
                        initListAt index: Int) -> UDTabsListContainerViewDelegate {
    return subViewControllers[index]
}

func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
    return subViewControllers.count
}
```

:::

## 滑动式页签

在初始化页签时，页签所在 viewController 需实现`UDTabsListContainerViewDataSource`协议来获取子视图实例列表和列表数量。

滑动式页签与固定式页签的最大区别在于**配置组件相关参数**中的**设置页签外观配置**的不同。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "40"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tab/ud_tab_scrollable.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tab/ud_tab_scrollable_dm.png"
    />

1. 申明组件所需变量

```swift
/// 页签视图
var tabsView = UDTabsTitleView()
/// 子视图代理
var subViewControllers: [UDTabsListContainerViewDelegate] = []
/// 子视图映射后的视图
var listContainerView: UDTabsListContainerView = UDTabsListContainerView(dataSource: self)

/// 初始化 3 个 SubVC 视图
var i = 1
while i <= 3 {
   let vc = SubVC()
   subViewControllers.append(vc)
   i += 1
}
```

2. 配置组件相关参数

```swift
// 设置单个页签底部的指示器
let indicator = UDTabsIndicatorLineView()
indicator.indicatorHeight = 2                   // 设置指示器高度

// 设置页签视图
tabsView.titles = ["标签名称 1"，"标签名称 2"，"标签名称 3"，"标签名称 4"，"标签名称 5"，"标签名称 6"，"标签名称 7"]
tabsView.backgroundColor = UIColor.ud.N00       // 设置 tabsView 背景颜色
tabsView.indicators = [indicator]               // 添加指示器
tabsView.listContainer = listContainerView      // 添加子视图

// 设置页签外观配置
let config = tabsView.getConfig()
config.isShowGradientMaskLayer = true           // 是否开启右侧模糊
config.contentEdgeInsetLeft = 6                 // 整体内容的左边距
config.itemSpacing = 24                         // 间距
tabsView.setConfig(config: config)              // 更新配置
```

3. 约束视图

```swift
self.view.addSubview(tabsView)
self.view.addSubview(listContainerView)

tabsView.snp.makeConstraints { (make) in
   make.top.equalTo(navigationBar.snp.bottom)
   make.right.equalToSuperview()
   make.left.equalTo(18)
   make.height.equalTo(40)
}

listContainerView.snp.makeConstraints { (make) in
   make.left.bottom.right.equalToSuperview()
   make.top.equalTo(tabsView.snp.bottom)
}
```

4. 实现`UDTabsListContainerViewDataSource`代理方法

```swift
func listContainerView(_ listContainerView: UDTabsListContainerView，
                        initListAt index: Int) -> UDTabsListContainerViewDelegate {
    return subViewControllers[index]
}

func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
    return subViewControllers.count
}
```

:::

## API 及配置列表

### Config

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
layoutStyle|item 布局 |UDTabsViewItemLayoutStyle|custom
itemWidthIncrement| 真实的 item 宽度 = itemContentWidth + itemWidthIncrement|CGFloat|0
itemSpacing|item 之前的间距 |CGFloat|20
isItemSpacingAverageEnabled| 当`collectionView.contentSize.width`小于 UDTabsView 的宽度时，是否将 itemSpacing 均分。|Bool|true
isItemTransitionEnabled|item 左右滚动过渡时，是否允许渐变。比如`UDTabsTitleDataSource`的`titleZoom`、`titleNormalColor`、`titleStrokeWidth`等渐变。|Bool|true
isSelectedAnimable| 选中的时候，是否需要动画过渡。自定义的 cell 需要自己处理动画过渡逻辑，动画处理逻辑参考`UDTabsTitleCell`|Bool|false
selectedAnimationDuration| 选中动画的时长 |TimeInterval|0.25
isItemWidthZoomEnabled| 是否允许 item 宽度缩放 |Bool|false
itemWidthSelectedZoomScale|item 宽度选中时的 scale|CGFloat|1.5
itemWidthNormalZoomScale|item 宽度在普通状态下的 scale|CGFloat|1
isShowGradientMaskLayer|Tabs 右侧展示一个渐变图层 |Bool|false
contentEdgeInsetLeft| 整体内容的左边距，默认`UDTabsViewAutomaticDimension`（等于 itemSpacing ）|CGFloat|UDTabsViewAutomaticDimension
contentEdgeInsetRight| 整体内容的右边距，默认`UDTabsViewAutomaticDimension`（等于 itemSpacing ）|CGFloat|UDTabsViewAutomaticDimension
isContentScrollViewClickTransitionAnimationEnabled| 点击切换的时候，`contentScrollView`的切换是否需要动画 |Bool|true
maskWidth|mask 长度 |CGFloat|64
maskColor|mask 颜色 |UIColor|UDTabsColorTheme.tabsScrollableDisappearColor

### UDTabsViewItemLayoutStyle

<SiteTableHighlight columns="2" type="3" />

属性 | 说明
---|---
average| 均分布局
custom| 自定义长度布局

### UDTabsView 属性

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
titles| 页签标题 |[String]|[]
config| 外观配置 |UDTabsViewConfig|UDTabsTitleViewConfig()

### UDTabsView 接口

#### setConfig()

设置 UDTabsView 的外观配置。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
config|UDTabsViewConfig()| 新配置

#### getConfig()

获取 UDTabsView 的外观配置。

#### reloadData()

刷新数据。
