# Universe-UI iOS UniverseDesignLoading

## 简介
提供三种加载中状态: 骨架（Skeleton）、Spin 加载（Spin）和插图加载（Loading Image），用于不同场景下的 Loading。
### Skeleton：列表视图、网格视图等模版加载
### Spin：局部加载，例如用户网络请求，按钮点击响应等
Loading Image：整体页面跳转的加载
## 安装
```
pod 'UniverseDesignLoading', 'version'
```
## 使用
### Skeleton
**以 UITableView 举例**
```swift
let table: UITableView
table.isSkeletonable = true // 该 Table 使用骨架图
table.register(SkeletonTableViewCell.self, reusableIdentifeir: "identifier")
...

table.udPrepareSkeleton(completion: {
    table.showUDSkeleton()
    {
        // 耗时任务执行
        table.hideUDSkeleton()
    }
})


class SkeletonTableViewCell: UITableViewCell {
    let avatarView: UIImageView
    let nameLabel: UILabel
    ...
    self.isSkeletonable = true
    self.avatarView.isSkeletonable = true
    self.nameLabel.isSkeletonable = true
}
```
> UICollectionView 与 UITableView 类似

**说明**

- 上述实现是基于实际的 DataSource 数量生成对应数量的骨架 Cell，可以通过实现 `UDSkeletonTableViewDataSource` 和 `UDSkeletonCollectionViewDataSource` Skeleton 会根据 Table 或 Collection 布局自动生成骨架，数量由布局大小决定。

- Cell 中的 Label 如果没有文案 Skeleton 不会为之生成骨架，所以初始化时候需要带上默认值（空格也行）

**一般视图的骨架**
```swift
let view: UIView
view.isSkeletonable = true
view.showUDSkeleton()
{
    // 耗时任务
    view.hideUDSkeleton()
}
```
> 子视图只要标记了 isSkelenable 会自动生成骨架

具体 Skeleton 实现和使用细节 [这里](https://github.com/Juanpe/SkeletonView)
### Spin
**预设样式的Spin**
```swift
// 创建Spin 自由添加约束
let spin = UDLoading.presetSpin()
view.addSubview(spin)

// 使用自动约束（view的中间）
UDLoading.showPresetSpin(on: view)
```
**使用自定义Spin**
```swift
let config: UDSpinConfig()
let spin = UDLoading.spin(config: config)
view.addSubview(spin)
```
### LoadingImage
```swift
// 创建ImageView 自由添加约束
let imageView = UDLoading.loadingImageView()
view.addSubview(imageView)

// 创建约束好的 VC 直接显示
let vc = UDLoading.loadingImageViewController()
self.present(vc, animated: true)
```
## API列表
### Skeleton
 接口 | 参数 | 说明
:---: | :---: | :---:
showUDSkeleton | none | 显示UD风格骨架图
hideUDSkeleton | none | 关闭UD风格骨架图
udSkeletonCorner | none | 设置 UD 风格的文本视图 Corner
udPrepareSkeleton | 回调：() -> Void | TableView或ColletionView视图准备好时执行的任务
### Loading Image
 接口 | 参数 | 说明
:---: | :---: | :---:
loadingImageView | Lottie 资源路径 | 生成一个Loading ImageView
loadingImageController | Lottie 资源路径 | 生成一个 Loading Image ViewController
### Spin
**UDSpinIndicatorConfig**

属性 | 默认值 | 说明
:---: | :---: | :---:
size | none | Indicator 的大小
color | none | Indicator 线条颜色
circleDegree | 0.6 | Indicator 圆圈最大圆弧比例（默认一半），取值范围 [0.1, 0.9]
animationDuration | 1.2 | Indicator 旋转周期（单位秒）

**UDSpinLabelConfig**
属性 | 默认值 | 说明
:---: | :---: | :---:
text | none | 文案内容
font | none | 文案字体
textColor | none | 文案颜色

**UDSpinConfig**

属性 | 默认值 | 说明
:---: | :---: | :---:
indicatorConfig | none | Spin 的 Indicator 配置
textLabelConfig | none | Spin 的文案配置
textDistribution | vertical |  Spin Indicator 和文案的布局相对位置（vertical：上下，horizonal：左右）

**预设样式**
属性 | 取值
:---: | :---:
Indicator 尺寸 | normal: 24, large: 40
Indicator 线条颜色 | primary: B500, neutralWhite: N00, neutralGray: N400
Indicator 圆弧比例 | 0.6
Indicator 旋转周期 | 1.2
文本颜色 | primary: N600, neutralWhite: N00, neutralGray: N400
文本字体 | PingFang SC 14.0
布局 | vertical

**Spin接口**

接口 | 参数 | 说明
:---: | :---: | :---:
spin | UDSpinConfig | 返回 UDSpin 视图
presetSpin | size: Indicator 预设尺寸，color：Indicator 预设颜色，loadingText：文本 | 返回预设风格的视图
