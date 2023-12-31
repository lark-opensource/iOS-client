//
//  AuroraView.swift
//  FigmaKit
//
//  Created by Hayden on 2023/6/1.
//

import UIKit

/// 极光视图
///
/// - [设计规范](https://bytedance.feishu.cn/wiki/Gtuawll85iqPc6kw1LdcveWfnjg)
/// - [使用指南](https://bytedance.feishu.cn/docx/Gl3IdSe2FoLvE6xTXRic0hfcnhg)
open class AuroraView: UIView {

    public typealias Configuration = AuroraViewConfiguration

    public let blobType: BlobType

    public enum BlobType: Int {
        case blur
        case gradient

        private var shouldSpreadFrame: Bool {
            switch self {
            case .blur:     return false
            case .gradient: return true
            }
        }
    }

    /// AuroraView 的色斑透明度，默认 1.0，非必要勿更改
    public var blobsOpacity: CGFloat = 1.0 {
        didSet {
            blobsLayer.opacity = Float(blobsOpacity)
        }
    }

    /// AuroraView 的色斑扩散半径，默认 80，非必要勿更改
    public var blobsBlurRadius: CGFloat = 80 {
        didSet {
            blurView?.blurRadius = blobsBlurRadius
        }
    }
    
    /// AuroraView 遮罩层颜色
    public var headColor: UIColor = .clear {
        didSet {
            headLayer.backgroundColor = headColor.cgColor
        }
    }

    /// AuroraView 遮罩层透明度
    public var headOpacity: CGFloat = 0.0 {
        didSet {
            headLayer.opacity = Float(headOpacity)
        }
    }

    /// 查看 AuroraView 当前使用的配置
    public private(set) var configuration: Configuration

    /// 使用传入的配置，更新 AuroraView
    /// - Parameters:
    ///   - configuration: 更新 AuroraView 所使用的最新配置
    ///   - animated: 更新配置是否需要渐变动画，默认为 `true`
    ///   - duration: 渐变动画的时间，默认为 2s，若动画设为 `false`，该参数不生效
    public func updateAppearance(with configuration: Configuration,
                                 animated: Bool = true,
                                 duration: TimeInterval = 2) {
        self.configuration = configuration

        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(CFTimeInterval(floatLiteral: duration))
        } else {
            CATransaction.setDisableActions(true)
        }

        mainLayer.color = configuration.mainBlob.color
        mainLayer.frame = calcAbsoluteFrame(for: configuration.mainBlob)
        mainLayer.opacity = Float(configuration.mainBlob.opacity)

        subLayer.color = configuration.subBlob.color
        subLayer.frame = calcAbsoluteFrame(for: configuration.subBlob)
        subLayer.opacity = Float(configuration.subBlob.opacity)

        reflectionLayer.color = configuration.reflectionBlob.color
        reflectionLayer.frame = calcAbsoluteFrame(for: configuration.reflectionBlob)
        reflectionLayer.opacity = Float(configuration.reflectionBlob.opacity)

        CATransaction.commit()
    }

    /// 仅当 blobType == .blur 时，添加在视图上方
    private lazy var blurView: BackgroundBlurView? = {
        guard blobType == .blur else { return nil }
        let view = BackgroundBlurView()
        view.blurRadius = blobsBlurRadius
        view.fillColor = .clear
        view.fillOpacity = 0
        return view
    }()

    /// 初始化方法，传入配置
    public init(config: Configuration, blobType: BlobType = .blur) {
        self.blobType = blobType
        self.configuration = config
        super.init(frame: .zero)
        setupAuroraLayers()
    }

    /// 初始化方法，使用默认配置，光斑为透明
    public override init(frame: CGRect) {
        self.blobType = .blur
        self.configuration = .default
        super.init(frame: frame)
        setupAuroraLayers()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var headLayer = CALayer()
    private lazy var blobsLayer = CALayer()
    private lazy var mainLayer = makeBlobLayer(color: configuration.mainBlob.color)
    private lazy var subLayer = makeBlobLayer(color: configuration.subBlob.color)
    private lazy var reflectionLayer = makeBlobLayer(color: configuration.reflectionBlob.color)

    open override func layoutSubviews() {
        super.layoutSubviews()
        headLayer.frame = bounds
        blobsLayer.frame = bounds
        mainLayer.frame = calcAbsoluteFrame(for: configuration.mainBlob)
        subLayer.frame = calcAbsoluteFrame(for: configuration.subBlob)
        reflectionLayer.frame = calcAbsoluteFrame(for: configuration.reflectionBlob)
        blurView?.frame = bounds
        mainLayer.setNeedsDisplay()
        subLayer.setNeedsDisplay()
        reflectionLayer.setNeedsDisplay()
    }

    private func setupAuroraLayers() {
        blobsLayer.opacity = Float(blobsOpacity)
        headLayer.opacity = Float(headOpacity)
        layer.addSublayer(blobsLayer)
        layer.addSublayer(headLayer)
        blobsLayer.addSublayer(subLayer)
        blobsLayer.addSublayer(mainLayer)
        blobsLayer.addSublayer(reflectionLayer)
        if let blurView = blurView {
            addSubview(blurView)
            blurView.blurRadius = blobsBlurRadius
        }
        layer.masksToBounds = true
        updateAppearance(with: configuration, animated: false)
    }

    private func makeBlobLayer(color: UIColor) -> BlobLayer {
        switch blobType {
        case .blur:
            let ovalLayer = OvalShapeLayer(color: color)
            return ovalLayer
        case .gradient:
            let gradientLayer = FKGradientLayer(type: .radial)
            gradientLayer.color = color
            return gradientLayer
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            mainLayer.color = configuration.mainBlob.color
            subLayer.color = configuration.subBlob.color
            reflectionLayer.color = configuration.reflectionBlob.color
            headLayer.backgroundColor = headColor.cgColor
        }
    }

    private func calcAbsoluteFrame(for blobStyle: Configuration.BlobStyle) -> CGRect {
        guard bounds.width != 0 else { return .zero }
        let spread = blobType == .blur ? 0 : blobStyle.blurRadius
        return CGRect(
            x: blobStyle.position.left * bounds.width,
            y: blobStyle.position.top * bounds.width,
            width: blobStyle.position.width * bounds.width,
            height: blobStyle.position.height * bounds.width
        ).insetBy(dx: -spread / 2, dy: -spread / 2)
    }
}

protocol BlobLayer: CALayer {
    var color: UIColor { get set }
}

/// 使用 CAGradientLayer 的椭圆色斑，无需叠加 Blur 图层达到扩散效果
extension CAGradientLayer: BlobLayer {

    var color: UIColor {
        get { return .clear }
        set { colors = [newValue, newValue.withAlphaComponent(0)].map({ $0.cgColor }) }
    }
}

/// 使用 CAShapeLayer 的椭圆色斑，需叠加 Blur 图层达到扩散效果
private final class OvalShapeLayer: CAShapeLayer, BlobLayer {

    var color: UIColor = .clear {
        didSet {
            setNeedsDisplay()
        }
    }

    init(color: UIColor) {
        self.color = color
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        guard let ovalLayer = layer as? OvalShapeLayer else { return }
        color = ovalLayer.color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("should not called")
    }

    override func draw(in ctx: CGContext) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: bounds)
    }
}

/*
// https://iphonedev.wiki/index.php/CAFilter
private final class ClearBlurView: UIView {

    /// Blur radius. Defaults to `20`
    var blurRadius: CGFloat = 20 {
        didSet {
            let blurFilter = makeBlurFilter()
            self.blurFilter = blurFilter
            blurFilter.setValue(blurRadius / 2, forKey: Keys.blurRadius)
            blurFilter.setValue(true, forKey: Keys.blurHardEdges)
            layer.filters = [blurFilter]
        }
    }

    /// Tint color. Defaults to `nil`
    var fillColor: UIColor? {
        get { backgroundColor }
        set { backgroundColor = newValue }
    }

    /// Tint color alpha. Defaults to `0`
    var fillOpacity: CGFloat = 0.0 {
        didSet {
            backgroundColor = backgroundColor?.withAlphaComponent(fillOpacity)
        }
    }

    private lazy var blurFilter = makeBlurFilter()

    private func makeBlurFilter() -> NSObject {
        guard let filterClass = NSClassFromString(Keys.filterClass) as? NSObject.Type else {
            return NSObject()
        }
        guard let filter = filterClass
            .perform(NSSelectorFromString(Keys.createFilter), with: Keys.gaussianBlurType)
            .takeUnretainedValue() as? NSObject else {
            return NSObject()
        }
        return filter
    }

    override class var layerClass: AnyClass {
        if let layerClass = NSClassFromString(Keys.blurLayer) {
            return layerClass
        } else {
            return super.layerClass
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.filters = [blurFilter]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Keys {
        static var filterClass: String { "CAFilter" }
        static var createFilter: String { "filterWithName:" }
        static var blurLayer: String { "CABackdropLayer" }
        static var blurRadius: String { "inputRadius" }
        static var gaussianBlurType: String { "gaussianBlur" }
        static var blurHardEdges: String { "inputHardEdges" }
    }
}
*/
