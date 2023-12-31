//
//  LKMagnifier.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/24.
//

import Foundation
import UIKit

public protocol LKMagnifier: AnyObject {
    var targetView: UIView? { get set }
    var sourceScanCenter: CGPoint? { get set }
    var magifierView: UIView { get }
    func update()
}

open class LKTextMagnifier: UIView, LKMagnifier {
    public struct GraphicConfiguration {
        public static let `default` = GraphicConfiguration()

        public var padding: CGFloat = 6
        public var mangifierSize: CGSize = CGSize(width: 130, height: 28)
        public var radius: CGFloat = 6
        public var arrow: CGFloat = 14
        public var scale: CGFloat = 1.3
    }

    fileprivate static var coverImage: UIImage?

    public weak var targetView: UIView?

    public var sourceScanCenter: CGPoint?

    public var magifierView: UIView {
        return self
    }

    public var configuration: GraphicConfiguration {
        didSet {
            LKTextMagnifier.coverImage = nil
            layout()
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
    }

    public func update() {
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

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func createSnapshot(_ targetView: UIView, _ scanRect: CGRect) -> UIImage? {
        let app = UIApplication.shared
        UIGraphicsBeginImageContextWithOptions(scanRect.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.scaleBy(x: configuration.scale, y: configuration.scale)

        var windows = app.windows
        if let keyWindow = app.keyWindow, !app.windows.contains(keyWindow) {
            windows.append(keyWindow)
        }
        windows.sort(by: { $0.windowLevel < $1.windowLevel })
        for window in windows where !window.isHidden && window.alpha > 0.01 && window.screen == UIScreen.main {
            let sourceScanRectInWindow = targetView.convert(scanRect, to: window)
            context.saveGState()
            context.translateBy(x: window.frame.minX - sourceScanRectInWindow.minX, y: window.frame.minY - sourceScanRectInWindow.minY)
            window.layer.render(in: context)
            context.restoreGState()
        }

        defer {
            UIGraphicsEndImageContext()
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(
            width: configuration.mangifierSize.width
                + 2 * configuration.padding,
            height: configuration.mangifierSize.height
                + 2 * configuration.padding
                + configuration.arrow
        )
    }

    public func createCoverImage() -> UIImage? {
        if let coverImage = LKTextMagnifier.coverImage {
            return coverImage
        }
        let padding = configuration.padding
        let radius = configuration.radius
        let size = frame.size
        let height = configuration.mangifierSize.height + padding - radius
        let arrow = configuration.arrow

        UIGraphicsBeginImageContext(size)
        if let context = UIGraphicsGetCurrentContext() {
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
                let shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
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
                let shadowColor = UIColor.black.withAlphaComponent(0.32).cgColor
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
            UIColor(white: 1, alpha: 0.95).set()
            context.fillPath()
            context.restoreGState()

            // stroke
            context.saveGState()
            context.addPath(path)
            UIColor(white: 0.6, alpha: 1).setStroke()
            context.setLineWidth(1 / UIScreen.main.scale)
            context.strokePath()
            context.restoreGState()
        }
        LKTextMagnifier.coverImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return LKTextMagnifier.coverImage
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
        contentImageView.frame = CGRect(origin: CGPoint(x: configuration.padding, y: configuration.padding), size: configuration.mangifierSize)
    }
}
