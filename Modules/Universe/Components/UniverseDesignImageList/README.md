# 图片墙 ImageList

## 简介

图片墙是表单场景中用户上传图片的组件。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignImageList'
```

接着，执行以下命令：

```bash
pod install
```

## 引入

引入组件：

```swift
import UniverseDesignTag
```
## 单个图片元素
### 初始化

```swift
//image 可为空
var item = ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .success)
```
### 状态
图片分为 initial、success、inProgress、error 四种状态，分别对应初始状态（还未设置时）、成功状态、传输状态、错误状态，如下图：

::: showcase collapse=false
<SiteImage
    width = "180"
    height = "180"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/4status.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/4status_dark.png"
    />
```swift
var datasource = [
    ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .initial),
    ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .success),
    ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .inProgress(progressValue: 0)),
    ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .error(message: nil))
]
```
:::

### 修改状态
调用 UDImageList 中的 changeStatus() 方法

## 图片墙
### 初始化
#### 不传入初始图片源
::: showcase collapse=false
<SiteImage
    width = "130"
    height = "130"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/upload_cell.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/upload_cell_dark.png"
    />

```swift
var imageList = UDImageList(dataSource: [], configuration: .init(maxImageNumber: 7))
```
:::
#### 传入初始图片源
::: showcase collapse=false
<SiteImage
    width = "250"
    height = "250"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/with_img.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDImageList/with_img_dark.png"
    />

```swift
let dataSource = [
    ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .success),
    ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .error(message: nil)),
    ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .inProgress(progressValue: 0)),
    ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .success),
    ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .inProgress(progressValue: 0)),
    ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .success),
]

var imageList = UDImageList(dataSource: dataSource, configuration: .init())
```
:::
## 定制样式
图片墙提供了以下属性可供定制：
### maxImageNumber
最大图片数量
```swift
var imageList = UDImageList(dataSource: self.datasource, configuration: .init(maxImageNumber: 10))
```

### cameraBackground
相机 cell 的背景类型
```swift
var imageList = UDImageList(dataSource: self.datasource, configuration: .init(cameraBackground: .grey))
```

### leftRightMargin
图片墙左右边的留白距离
```swift
var imageList = UDImageList(dataSource: self.datasource, configuration: .init(leftRightMargin: 30))
```

### interitemSpacing
图片间的间距
```swift
var imageList = UDImageList(dataSource: self.datasource, configuration: .init(interitemSpacing: 10))
```


## API 及配置列表
### UDImageList
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
dataSource<SiteTableRequired />| 数据源 | [ImageListItem] | 
configuration<SiteTableRequired />| 样式配置 | UDImageList.Configuration | 

### UDImageList 点击事件
<SiteTableHighlight columns="4" type="3" />

回调名 | 说明 | 类型 | 默认值
---|---|---|---|
onRetryClicked| 点击重试按钮后触发的回调 | ((ImageListItem) -> Void)? | nil
onImageClicked| 点击图片后触发的回调 | ((ImageListItem) -> Void)? | nil
onCameraClicked| 点击相机 cell 后触发的回调 | (() -> Void)? | nil
onDeleteClicked| 点击删除按钮后触发的回调 | ((ImageListItem) -> Void)? | nil

### UDImageList 接口
#### reloadItems
重新加载 index 索引位置的图片
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
index| 图片索引号 | Int | 

#### reloadAllItems
重新加载所有的图片，无参数

#### updateProgress
更新某个 id 的图片的进度值，并将状态设为 inProgress
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
id| 图片索引号 | String | 
#### changeStatus
修改某个 id 的图片的状态到 status
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
id| 图片索引号 | String | 
status| 图片状态 | ImageListItem.Status | 

#### deleteItem
删除某个图片元素
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
item| 要删除的 item | ImageListItem | 

#### insertItem
将某个图片元素插到特定的位置
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
item| 要加入的元素 | ImageListItem | 
index| 要插入的索引位置 | Int | 

#### appendItem
将某个图片元素加到图片墙末尾
<SiteTableHighlight columns="4" type="3" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---|
item| 要加入的元素 | ImageListItem | 
