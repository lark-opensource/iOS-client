# 评分 Rate

## 简介

评分组件用于展示评价 / 分数，或为用户提供打分功能。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignRate'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignRate
```

## 默认评分

你在使用时，需要使 baseViewController 实现`UDRateViewDelegate`协议中的`func rateView(_ rateView: UDRateView, didSelectedStep step: Double)`。

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "50"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/rate/ud_rate.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/rate/ud_rate_dm.png"
    />

```swift
var rate = UDRateView()
var config = rate.config

config.itemImage = UDIcon.collectFilled

rate.update(config: config)
rate.setRateText("请点击进行评分")
rate.delegate = self

rate.snp.makeConstraints { (make) in
    make.centerX.equalToSuperview()
    make.top.equalToSuperview().offset(100)
}

/// 实现 UDRateViewDelegate 协议
func rateView(_ rateView: UDRateView, didSelectedStep step: Double) {
    if step <= 0 {
        rateView.setRateText("请点击进行评分")
    } else if step <= 1 {
        rateView.setRateText("非常不满意，各方面都很差")
    } else if step <= 2 {
        rateView.setRateText("不满意，比较差")
    } else if step <= 3 {
        rateView.setRateText("一般，还需改善")
    } else if step <= 4 {
        rateView.setRateText("比较满意，仍可改善")
    } else {
        rateView.setRateText("非常满意，无可挑剔")
    }
}
```

:::

## 自定义评分

你在使用时，可通过获取到`UDRateView`的`config`来对评分组件的外观进行配置。

组件提供了以下参数可供定制：

属性名 | 默认值 | 说明
:--:|:--:|:--:
dragStep|.none| 拖动时的步数
itemImage |UIImage()| 评分的显示图片
itemCount |5| 评分图片数
itemSize|CGSize(width: 44, height: 44)| 图片大小
itemScale|1| 图片缩放
defaultColor|UDColor.N900.withAlphaComponent(0.15)| 默认颜色
selectedColor|UDColor.Y500| 选中颜色

## API 及配置列表

### UDRateView 接口

#### update

更新评分组件外观配置。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
config<SiteTableRequired />| - | 新外观配置

#### setRateText

设置评分组件文本。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 新外观配置
textFont|caption1| 字体
textColor|textCaption| 文字颜色
textWidth|nil| 文字宽度

#### setRateCustomView

设置评分组件自定义视图。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
view<SiteTableRequired />| - | 自定义视图
