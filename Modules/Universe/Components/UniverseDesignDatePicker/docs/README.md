# 日期选择器 Date Picker

## 简介

日期选择器用于在多个备选选项中选择、筛选一个合适的日期相关项目。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignDatePicker'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignDatePicker
```

## 12 时制小时分钟选择器

本组件提供了[`config.is12Hour`](#udwheelsstyleconfig)来配置是否开启 12 小时制，默认为 12 小时制。

本组件提供了[`config.mode`](#udwheelsstyleconfig)来配置当前组件的日期显示模式。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "256"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/datepicker_12_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/date_picker_12_d.png"
    />

```swift
/// 小时 - 分钟 12 小时模式 显示 5 行
var config = UDWheelsStyleConfig(mode: .hourMinute, maxDisplayRows: 5, is12Hour: true)
var picker = UDDateWheelPickerView(wheelConfig: config)
```

:::

## 24 时制小时分钟选择器

本组件提供了[`config.is12Hour`](#udwheelsstyleconfig)来配置是否开启 12 小时制，默认为 12 小时制。

本组件提供了[`config.mode`](#udwheelsstyleconfig)来配置当前组件的日期显示模式。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "256"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/24_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/24_d.png"
    />

```swift
/// 日 - 小时 - 分钟 24 小时模式 显示 5 行
var config = UDWheelsStyleConfig(mode: .dayHourMinute, maxDisplayRows: 5, is12Hour: false)
var picker = UDDateWheelPickerView(wheelConfig: config)
```

:::

## 年月日选择器

本组件提供了[`config.mode`](#udwheelsstyleconfig)来配置当前组件的日期显示模式。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "256"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/yearmonthday_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/yearmonthday_d.png"
    />

```swift
/// 年 - 月 - 日 显示 5 行
var config = UDWheelsStyleConfig(mode: .yearMonthDay, maxDisplayRows: 5)
var picker = UDDateWheelPickerView(wheelConfig: config)
```

:::

## 月历选择器

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "256"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/datepicker_calendar_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/datepicker_calendar_d.png"
    />

```swift
let config = UDCalendarStyleConfig()
let upperView = UDDateCalendarPickerView(calendarConfig: config)
picker.delegate = self

func dateChanged(_ date: Date) {
    let result = Calendar.current.dateComponents(in: .current, from: date)
    print(String(describing: result))
}
```

:::

## 基础式 / 嵌入式日期滚轮选择器

基础式日期滚轮选择器使用[`UDDateWheelPickerViewController`](#uddatewheelpickerviewcontroller)初始化 config，会单独与 baseViewController 存在。

嵌入式日期滚轮选择器使用[`UDDatePickerView`](#uddatepickerview)初始化 config，可以添加在任何 baseViewController 需要的位置。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "812"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/datepicker_base_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDatePicker/datepicker_base_d.png"
    />

```swift
/// 基础式
let config = UDWheelsStyleConfig(maxDisplayRows: 5, is12Hour: false, mode: .dayHourMinute)
let datePicker = UDDateWheelPickerViewController(customTitle: "自定义标题", wheelConfig: config)
datePicker.confirm = { (data) in
    let result = calendar.dateComponents(in: .current, from: data)
    print(String(describing: result))
}

/// 嵌入式
let config = UDWheelsStyleConfig(is12Hour: true, mode: .dayHourMinute)
let datePicker = UDDatePickerView(wheelConfig: config)
datePicker.dateChanged = {(changedDate) in
    let result = calendar.dateComponents(in: .current, from: changedDate)
    print(String(describing: result))
}
self.view.addSubview(datePicker)
```

:::

## API 及配置列表

### UDWheelsStyleConfig

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
maxDisplayRows |3| 最大显示行数
centerWheels |true| 滚轮内容是否居中
is12Hour |true| 是否 12 小时制
showSepeLine|true| 是否显示分割线
textColor |N900| 显示颜色
textFont | title5| 显示字体
mode | 年月日 | 滚轮选择器类型

### UDDatePickerView

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
date|Date()| 日期
timeZone|.current| 当前时区
maximumDate|2099.12.31 23:59| 最大可选日期
minimumDate|1900.01.01 00:00| 最小可选日期
wheelConfig|UDWheelsStyleConfig(maxDisplayRows: 3)| 滚轮选择器 UI 配置

### UDDatePickerView 接口

#### dateChanged

滚动时抛出选中值 Date 回调。

#### dateChangedOnCompleted

Date 选择完成回调。

#### select

将日期选择器设置为 date 对应时刻。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
date|Date()| 日期

#### switchTo

动态切换「滚轮类型」。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
mode<SiteTableRequired />| - | 滚轮类型
with<SiteTableRequired />| - | 滚轮展示日期

### UDDateWheelPickerViewController

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
customTitle<SiteTableRequired />| - | 标题
date|Date()| 日期
timeZone|.current| 当前时区
maximumDate|2099.12.31 23:59| 最大可选日期
minimumDate|1900.01.01 00:00| 最小可选日期
wheelConfig|UDWheelsStyleConfig(maxDisplayRows: 3)| 滚轮选择器 UI 配置

### UDDateWheelPickerViewController 接口

#### confirm

确认回调，传出选中值 Date。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
pickedDate<SiteTableRequired />| - | 选中的 date

#### select

将日期选择器设置为 date 对应时刻。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
date|Date()| 日期
