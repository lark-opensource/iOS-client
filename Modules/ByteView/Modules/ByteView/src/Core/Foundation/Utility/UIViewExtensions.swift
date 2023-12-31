//
//  Utility.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/15.
//

import Foundation
import UIKit
import ByteViewCommon
import WebKit
import UniverseDesignShadow

extension VCExtension where BaseType: UIView {
    func screenshot() -> UIImage? {
        let transform = self.base.transform
        self.base.transform = .identity
        let render = UIGraphicsImageRenderer(bounds: self.base.bounds)
        let screenshot = render.image { rendererContext in
            self.base.layer.render(in: rendererContext.cgContext)
        }
        self.base.transform = transform
        return screenshot
    }

    func addOverlayShadow(isTop: Bool) {
        // 主线程async，以防止和其它动画耦合在一起造成展示问题
        DispatchQueue.main.async {
            let layer = self.base.layer
            layer.masksToBounds = false
            layer.ud.setShadow(type: isTop ? .s1Down : .s1Up, shouldRasterize: false)
        }
    }

    func removeOverlayShadow() {
        DispatchQueue.main.async {
            self.base.layer.shadowOpacity = 0
        }
    }

    func getWebView() -> WKWebView? {
        for subview in base.subviews {
            if let webView = subview as? WKWebView {
                return webView
            }
            if let webview = subview.vc.getWebView() {
                return webview
            }
        }
        return nil
    }
}

extension VCExtension where BaseType: UILabel {

    func justReplaceText(to string: String) {
        if let length = base.attributedText?.length, length > 0 {
            let attributes = base.attributedText?.attributes(at: 0, effectiveRange: nil)
            base.attributedText = NSAttributedString(string: string, attributes: attributes)
        } else {
            base.text = string
        }
    }
}

extension UIView.AnimationCurve {
    var timingFunction: CAMediaTimingFunction {
        let name: CAMediaTimingFunctionName
        switch self {
        case .easeIn:
            name = .easeIn
        case .easeOut:
            name = .easeOut
        case .easeInOut:
            name = .easeInEaseOut
        case .linear:
            name = .linear
        @unknown default:
            name = .linear
        }
        return CAMediaTimingFunction(name: name)
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension CGSize {
    func equalSizeTo(_ other: CGSize) -> Bool {
        return (width == other.width && height == other.height) || (height == other.width && width == other.height)
    }
}

extension CGPath {
    /// 自定义各圆角的cornerRadius，生成path
    /// - Parameters:
    ///   - bounds: 待绘制区域
    ///   - topLeft: 左上cornerRadius
    ///   - topRight: 右上cornerRadius
    ///   - bottomLeft: 左下cornerRadius
    ///   - bottomRight: 右下cornerRadius
    /// - Returns: 生成自定义圆角的path
    static func createSpecializedCornerRadiusPath(bounds: CGRect, topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) -> CGPath {
        let minX: CGFloat = bounds.minX
        let minY: CGFloat = bounds.minY
        let maxX = bounds.maxX
        let maxY = bounds.maxY

        let topLeftCenterX = minX + topLeft
        let topLeftCenterY = minY + topLeft
        let topRightCenterX = maxX - topRight
        let topRightCenterY = minY + topRight
        let bottomLeftCenterX = minX + bottomLeft
        let bottomLeftCenterY = maxY - bottomLeft
        let bottomRightCenterX = maxX - bottomRight
        let bottomRightCenterY = maxY - bottomRight

        let path: CGMutablePath = CGMutablePath()
        path.addArc(center: CGPoint(x: topLeftCenterX, y: topLeftCenterY), radius: topLeft, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 3 / 2, clockwise: false)
        path.addArc(center: CGPoint(x: topRightCenterX, y: topRightCenterY), radius: topRight, startAngle: CGFloat.pi * 3 / 2, endAngle: 0, clockwise: false)
        path.addArc(center: CGPoint(x: bottomRightCenterX, y: bottomRightCenterY), radius: bottomRight, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: false)
        path.addArc(center: CGPoint(x: bottomLeftCenterX, y: bottomLeftCenterY), radius: bottomLeft, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: false)
        path.closeSubpath()
        return path
    }
}

extension UIWindow.Level {
    static let interviewQuestionnaire = Self.init(8)
    static let floatingWindow = Self.init(9.9) // SuspendWindow.window.level=9.8，二者均低于系统默认window.level(10)
}
