# Icon 开发文档

**系统图标** 是指具有明确指代含义的图形符号，是常用操作、文件、设备、目录等功能的图形化表现形式，用于触发界面中的局部操作，是界面设计中的重要组成部分。iOS没有icon相关的统一组件，会出现多处icon不一致的问题。并且之后会搭建相应的icon资源平台，希望能够有自动化的流程完成icon下载更新到出包使用的流程，减少UI和RD的不必要工作。

## 参考文档

[ESUX - 系统图标规范](https://bytedance.feishu.cn/docs/doccnWc0oGQRNHJKaj7L1pDF4nb#DHCzmE)

## 目录
- [目标](#目标)
- [收益](#收益)
- [设计方案](#设计方案)
  - [icon获取](#icon获取)
  - [Universe Icon Pod](#universe-icon-pod)

## 目标

提供一套自动化更新icon资源并打包发版的 Universe Design Icon pod，使用者只需要根据key便可获取到相应资源，不需要关心下载、分辨率等问题。

## 收益

- UI不在需要对iOS单独切图。
- icon样式统一，避免有地方使用旧图标的情况。
- 减少RD加资源时浪费的精力。

## 设计方案

### icon获取
如图所示为icon入库的顺序图：

<img src="9bb4ee65-e4bb-4111-8a16-cf00fdbd8240.png" width = "400" height = "300" div align=center/>

前面步骤由icon管理平台提供，我们需要解决 `Universe icon` 仓库入库时处理，以及发版处理等操作。

#### icon管理平台

职责：在icon更新时能够将最新的资源push到仓库中。
仓库地址：

#### 处理SVG图片
> 此前针对iOS平台对SVG格式文件处理调研：[iOS平台SVG解决方案](https://bytedance.feishu.cn/docs/doccnX3beCTiM67Gdfg0syUXSIc)

选择处理SVG的方法会影响我们 `Universe icon` 内部实现。
SVG解决方案主要分为两种：

1. 直接引入SVG
优点：可以省略SVG处理PNG的步骤，SVG可以省略2x/3x的区分，这样会减少资源。
缺点：处理SVG会引入其他三方库，增大包体积。目前iOS平台理论上是不支持SVG的，可能会带来性能问题。

2. SVG转PNG
优点：不会有性能方面的困扰，不需要引入三方库。
缺点：不支持无损缩放。

结论：
获取SVG格式文件后，使用工具转换为PNG格式图片。

### Universe Icon Pod

#### 目标

- 对外提供获取icon接口，用户可根据自身需求获取对应颜色icon。
- 提供一个可以动态切换 `tintcolor` 及背景色的 `UIImage` 扩展功能。

#### Universe icon 设计

`Universe icon` 分为两部分， `UDIconType` 和 `UDIcon` 。为了避免使用string获取图片失败，所有图标都以 enum 的形式获取，这样能够严格控制外部使用。

##### UDIconType

````swift
public enum UDIconType: String {
    case back = "icon_back"
    ·····
}
````

##### UDIcon

`UDIcon` 提供了根据 `UDIconType` 获取 icon 的方法以及，简便获取方式。

````swift
public class UDIcon {
    public static func getIconByKey(_ key: UDIconType,
                                    renderingMode: UIImage.RenderingMode = .automatic,
                                    iconColor: UIColor? = nil) -> UIImage {
        var iconImage = Resources.image(named: key.rawValue)
        if let iconColor = iconColor {
            iconImage = iconImage.ud.withTintColor(iconColor,
                                                   renderingMode: renderingMode)
        }
        return iconImage
    }
}
````

扩展 `UDIcon` ，用户能够更加简便获取 icon :

````swift
extension UDIcon {
    public class var back: UIImage { return UDIcon.getIconByKey(.back) }
}
````

#### UIImage 扩展功能
iOS 12及以下版本不支持 `UIImage` 直接设置 `tintColor`，无法使用系统方法，所以我们对其进行了扩展。

##### UDImageExtension
对 `UIImage` 以及 `UIImageView` 属性扩展，更加简便更改 `UIImage` 的 `tintColor` 以及获取 Icon。

````swift
public class UDImageExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol UDImageExtensionCompatible {
    associatedtype UDImageCompatibleType
    var ud: UDImageCompatibleType { get }
    static var ud: UDImageCompatibleType.Type { get }
}

public extension UDImageExtensionCompatible {
    var ud: UDImageExtension<Self> {
        return UDImageExtension(self)
    }

    static var ud: UDImageExtension<Self>.Type {
        return UDImageExtension.self
    }
}
````

##### UIImage 扩展

扩展 `withTintColor` 方法:

````swift
extension UIImage: UDImageExtensionCompatible {}

extension UDImageExtension where BaseType: UIImage {
    public func withTintColor(_ color: UIColor, renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        if #available(iOS 13.0, *) {
            return self.base.withTintColor(color, renderingMode: renderingMode)
        } else {
            /// 解决iOS12不能使用withTintColor函数
            UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
            color.setFill()

            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: 0, y: self.base.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.setBlendMode(CGBlendMode.normal)

            let rect = CGRect(origin: .zero, size: CGSize(width: self.base.size.width, height: self.base.size.height))
            context?.clip(to: rect, mask: self.base.cgImage!)
            context?.fill(rect)

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage?.withRenderingMode(renderingMode) ?? UIImage()
        }
    }
}
````

##### UIImageView 扩展

与 `UIImage` 扩展类似，方法如下：

````swift
extension UIImageView: UDImageExtensionCompatible {}

extension UDImageExtension where BaseType: UIImageView {
    public func withTintColor(_ color: UIColor, backgroundColor: UIColor? = nil, renderingMode: UIImage.RenderingMode = .automatic) {
        self.base.image = self.base.image?.lk.withTintColor(color, renderingMode: renderingMode)
        self.base.backgroundColor = backgroundColor
    }
}
````