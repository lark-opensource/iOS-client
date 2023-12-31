//
//  Magnifier.swift
//  LKRichView
//
//  Created by qihongye on 2021/8/29.
//

import Foundation
import UIKit

// A basic `Magnifier` protocol defination.
//
// 
public protocol Magnifier: AnyObject {
    var contentSize: CGSize { get set }
    var targetView: UIView? { get set }
    var sourceScanCenter: CGPoint? { get set }
    var magnifierView: UIView { get }
    func updateRenderer()
    func createSnapshot(_ targetView: UIView, _ scanRect: CGRect) -> UIImage?
    func locateAt(anchorPoint: CGPoint)
}

func createScreenSnapshot(targetView: UIView, in rect: CGRect, scale: CGFloat) -> UIImage? {
    let app = UIApplication.shared
    var windows = app.windows
    if let keyWindow = app.keyWindow, !app.windows.contains(keyWindow) {
        windows.append(keyWindow)
    }
    windows.sort(by: { $0.windowLevel < $1.windowLevel })

    return UIGraphicsImageRenderer(size: rect.size).image { ctx in
        let context = ctx.cgContext
        context.scaleBy(x: scale, y: scale)
        for window in windows where !window.isHidden && window.alpha > 0.01 && window.screen == UIScreen.main {
            let sourceScanRectInWindow = targetView.convert(rect, to: window)
            context.saveGState()
            context.translateBy(x: window.frame.minX - sourceScanRectInWindow.minX, y: window.frame.minY - sourceScanRectInWindow.minY)
            window.layer.render(in: context)
            context.restoreGState()
        }
    }
}

open class TextMagnifier: UIView, Magnifier {
    public struct GraphicConfiguration {
        public static let `default` = GraphicConfiguration()

        public let padding: CGFloat
        public let defaultMagnifierSize: CGSize
        public let radius: CGFloat
        public let arrow: CGFloat
        public let scale: CGFloat

        public let innerShadowColor: UIColor
        public let outerShadowColor: UIColor
        public let arrowColor: UIColor
        public let stockColor: UIColor

        public init(padding: CGFloat = 6,
                    defaultSize: CGSize = .init(width: 130, height: 28),
                    radius: CGFloat = 6,
                    arrow: CGFloat = 14,
                    scale: CGFloat = 1.3,
                    innerShadowColor: UIColor = UIColor.black.withAlphaComponent(0.16),
                    outerShadowColor: UIColor = UIColor.black.withAlphaComponent(0.32),
                    arrowColor: UIColor = UIColor(white: 1, alpha: 0.95),
                    stockColor: UIColor = UIColor(white: 0.6, alpha: 1)) {
            self.padding = padding
            self.defaultMagnifierSize = defaultSize
            self.radius = radius
            self.arrow = arrow
            self.scale = scale
            self.innerShadowColor = innerShadowColor
            self.outerShadowColor = outerShadowColor
            self.arrowColor = arrowColor
            self.stockColor = stockColor
        }
    }

    fileprivate static var coverImage: UIImage?

    public weak var targetView: UIView?

    public var sourceScanCenter: CGPoint?

    public var magnifierView: UIView {
        return self
    }

    /// 放大镜视图的大小
    var _contentSize: CGSize = .zero
    public var contentSize: CGSize {
        get {
            if _contentSize.width <= 0 || _contentSize.height <= 0 {
                return configuration.defaultMagnifierSize
            }
            return _contentSize
        }
        set {
            if _contentSize != newValue {
                Self.coverImage = nil
            }
            _contentSize = newValue
        }
    }

    public var configuration: GraphicConfiguration {
        didSet {
            layout()
            updateRenderer()
        }
    }

    public init(configuration: GraphicConfiguration = .default) {
        self.configuration = configuration
        super.init(frame: .zero)
        addSubview(contentImageView)
        addSubview(coverImageView)
        self.backgroundColor = .clear
        self.isOpaque = true
        self.contentImageView.layer.cornerRadius = configuration.radius
        self.contentImageView.clipsToBounds = true
        layout()
        updateRenderer()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateRenderer() {
        guard let targetView = self.targetView,
              let scanCenterPoint = self.sourceScanCenter else {
            return
        }
        var scanRect = contentImageView.bounds
        scanRect.origin.x = scanCenterPoint.x - scanRect.width / configuration.scale / 2
        scanRect.origin.y = scanCenterPoint.y - scanRect.height / configuration.scale / 2
        let img = self.createSnapshot(targetView, scanRect)
        self.contentImageView.image = img
    }

    public func locateAt(anchorPoint: CGPoint) {
        self.frame.origin = CGPoint(
            x: anchorPoint.x - self.frame.width / 2,
            y: anchorPoint.y - self.frame.height
        )
    }

    public func createSnapshot(_ targetView: UIView, _ scanRect: CGRect) -> UIImage? {
        return createScreenSnapshot(targetView: targetView, in: scanRect, scale: configuration.scale)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(
            width: contentSize.width
                + 2 * configuration.padding,
            height: contentSize.height
                + 2 * configuration.padding
                + configuration.arrow
        )
    }

    public func createCoverImage() -> UIImage? {
        if let coverImage = TextMagnifier.coverImage {
            return coverImage
        }
        let padding = configuration.padding
        let radius = configuration.radius
        let size = frame.size
        let height = contentSize.height + padding - radius
        let arrow = configuration.arrow

        TextMagnifier.coverImage = UIGraphicsImageRenderer(size: size).image { ctx in
            let context = ctx.cgContext
            let boxPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: padding + radius, y: padding))
            path.addLine(to: CGPoint(x: size.width - padding - radius, y: padding))
            path.addQuadCurve(to: CGPoint(x: size.width - padding, y: padding + radius), control: CGPoint(x: size.width - padding, y: padding))
            path.addLine(to: CGPoint(x: size.width - padding, y: height))
            path.addCurve(
                to: CGPoint(x: size.width - padding - radius, y: padding + height),
                control1: CGPoint(x: size.width - padding, y: padding + height),
                control2: CGPoint(x: size.width - padding - radius, y: padding + height)
            )
            path.addLine(to: CGPoint(x: size.width / 2 + arrow, y: padding + height))
            path.addLine(to: CGPoint(x: size.width / 2, y: padding + height + arrow))
            path.addLine(to: CGPoint(x: size.width / 2 - arrow, y: padding + height))
            path.addLine(to: CGPoint(x: padding + radius, y: padding + height))
            path.addQuadCurve(to: CGPoint(x: padding, y: height), control: CGPoint(x: padding, y: padding + height))
            path.addLine(to: CGPoint(x: padding, y: padding + radius))
            path.addQuadCurve(to: CGPoint(x: padding + radius, y: padding), control: CGPoint(x: padding, y: padding))
            path.closeSubpath()

            let arrowPath = CGMutablePath()
            arrowPath.move(to: CGPoint(x: size.width / 2 - arrow, y: padding + height))
            arrowPath.addLine(to: CGPoint(x: size.width / 2 + arrow, y: padding + height))
            arrowPath.addLine(to: CGPoint(x: size.width / 2, y: padding + height + arrow))
            arrowPath.closeSubpath()

            // inner shadow
            context.saveGState()
            if true {
                let blurRadius: CGFloat = 25
                let offest = CGSize(width: 0, height: 15)
                let shadowColor = configuration.innerShadowColor.cgColor
                let opaqueShadowColor = shadowColor.copy(alpha: 1.0)!
                context.addPath(path)
                context.clip()
                context.setAlpha(shadowColor.alpha)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
                context.setShadow(offset: offest, blur: blurRadius, color: opaqueShadowColor)
                context.setBlendMode(.sourceOut)
                context.setFillColor(opaqueShadowColor)
                context.addPath(path)
                context.fillPath()
                context.endTransparencyLayer()
            }
            context.restoreGState()

            // outer shadow
            context.saveGState()
            if true {
                context.addPath(boxPath)
                context.addPath(path)
                context.clip(using: .evenOdd)
                let shadowColor = configuration.outerShadowColor.cgColor
                context.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3, color: shadowColor)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
                context.addPath(path)
                UIColor(white: 0.7, alpha: 1).setFill()
                context.fillPath()
                context.endTransparencyLayer()
            }
            context.restoreGState()

            // arrow
            context.saveGState()
            context.addPath(arrowPath)
            configuration.arrowColor.set()
            context.fillPath()
            context.restoreGState()

            // stroke
            context.saveGState()
            context.addPath(path)
            configuration.stockColor.setStroke()
            context.setLineWidth(1 / UIScreen.main.scale)
            context.strokePath()
            context.restoreGState()
        }

        return TextMagnifier.coverImage
    }

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        return imageView
    }()

    private lazy var contentImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        return imageView
    }()

    private func layout() {
        frame = CGRect(origin: .zero, size: self.sizeThatFits(.zero))
        coverImageView.frame = CGRect(origin: .zero, size: frame.size)
        coverImageView.image = createCoverImage()
        contentImageView.frame = CGRect(origin: CGPoint(x: configuration.padding, y: configuration.padding), size: contentSize)
    }
}

/*
 /// 实现文档：https://bytedance.feishu.cn/wiki/wikcnLqStFdwxIz4B27JJjXmoNf
 @available(iOS 15, *)
 public final class TextMagnifierForIOS15: UIView, Magnifier {
 public struct GraphicConfiguration {
 public static let `default` = GraphicConfiguration()

 public let defaultMagnifierSize: CGSize
 public let scale: CGFloat

 public init(defaultMagnifierSize: CGSize = .init(width: 78, height: 44),
 scale: CGFloat = 1.3) {
 self.defaultMagnifierSize = defaultMagnifierSize
 self.scale = scale
 }
 }

 public weak var targetView: UIView?

 public var sourceScanCenter: CGPoint?

 public var magnifierView: UIView {
 return self
 }

 private var _contentSize: CGSize = .zero
 public var contentSize: CGSize {
 get {
 if _contentSize.width <= 0 || _contentSize.height <= 0 {
 return configuration.defaultMagnifierSize
 }
 return _contentSize
 } set {
 _contentSize = newValue
 }
 }

 let configuration: GraphicConfiguration

 public init(configuration: GraphicConfiguration = .default) {
 self.configuration = configuration
 super.init(frame: CGRect(origin: .zero, size: configuration.defaultMagnifierSize))

 self.layer.shadowColor = UIColor.black.cgColor
 self.layer.shadowOffset = .init(width: 0, height: 2)
 self.layer.shadowRadius = 20
 self.layer.shadowOpacity = 0.1
 addSubview(containerView)
 containerView.addSubview(contentImageView)
 containerView.addSubview(filterView)
 updateColorsForTraitCollection(self.traitCollection)
 }

 required init?(coder: NSCoder) {
 fatalError("init(coder:) has not been implemented")
 }

 public func updateRenderer() {
 guard let targetView = self.targetView,
 let scanCenterPoint = self.sourceScanCenter else {
 return
 }
 var scanRect = contentImageView.bounds
 scanRect.origin.x = scanCenterPoint.x - scanRect.width / configuration.scale / 2
 scanRect.origin.y = scanCenterPoint.y - scanRect.height / configuration.scale / 2
 let img = self.createSnapshot(targetView, scanRect)
 self.contentImageView.image = img
 }

 public func createSnapshot(_ targetView: UIView, _ scanRect: CGRect) -> UIImage? {
 return createScreenSnapshot(targetView: targetView, in: scanRect, scale: configuration.scale)
 }

 public func locateAt(anchorPoint: CGPoint) {
 self.frame.origin = CGPoint(
 x: anchorPoint.x - self.frame.width / 2,
 y: anchorPoint.y - self.frame.height
 )
 }

 public override func sizeThatFits(_ size: CGSize) -> CGSize {
 return CGSize(
 width: contentSize.width,
 height: contentSize.height
 )
 }

 public override func layoutSubviews() {
 super.layoutSubviews()
 containerView.frame = bounds
 filterView.frame = bounds
 contentImageView.frame = bounds
 }

 public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
 super.traitCollectionDidChange(previousTraitCollection)
 updateRenderer()
 updateColorsForTraitCollection(self.traitCollection)
 }

 private lazy var containerView: UIView = {
 let view = UIView(frame: self.bounds)
 view.layer.cornerCurve = .continuous
 view.layer.masksToBounds = true
 view.layer.cornerRadius = 22
 view.layer.borderWidth = 2 / UIScreen.main.scale
 view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: -50)
 return view
 }()

 private lazy var filterView: UIView = {
 let view = UIView(frame: self.bounds)
 // extern NSString * _Nullable const kCAFilterLightenSourceOver;
 // lightenSourceOver
 let data = Data(
 bytes: [UInt8]([108, 105, 103, 104, 116, 101, 110, 83, 111, 117, 114, 99, 101, 79, 118, 101, 114]),
 count: 17
 )
 view.layer.compositingFilter = String(data: data, encoding: .utf8)
 view.layer.filters = [TextModernLoupe.colorFilter(), TextModernLoupe.gaussianFilter()]
 view.layer.masksToBounds = true
 view.layer.cornerCurve = .continuous
 view.layer.cornerRadius = 2
 view.layer.rasterizationScale = UIScreen.main.scale
 view.layer.shouldRasterize = true
 return view
 }()

 private lazy var contentImageView: UIImageView = {
 let imageView = UIImageView(frame: self.bounds)
 return imageView
 }()

 private func updateColorsForTraitCollection(_ traitCollection: UITraitCollection) {
 var white: CGFloat = 0
 var alpha: CGFloat = 0
 if traitCollection.userInterfaceStyle == .dark {
 white = 1
 alpha = 0.2
 } else {
 white = 0
 alpha = 0.1
 }
 containerView.layer.borderColor = UIColor(white: white, alpha: alpha).cgColor
 }
 }
 */
