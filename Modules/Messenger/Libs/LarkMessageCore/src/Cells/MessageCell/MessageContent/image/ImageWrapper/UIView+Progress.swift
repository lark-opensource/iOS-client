//
//  UIView+Progress.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkCompatible

extension UIView {
    func showProgress(
        progress: Float,
        progressType: UploadProgressType = .default,
        showType: UploadProgressConfig.ShowProgressType = .incomplete,
        centerYOffset: CGFloat
    ) {
        if !UploadProgressConfig.uploadProgressEnable {
            return
        }

        var view: UIView? = self.viewWithTag(UploadProgressConfig.uploadProgressLayerTag)

        let newLayerBlock = { [weak self] () -> UIView in
            let view = progressType.layer(centerYOffset: centerYOffset)
            view.tag = UploadProgressConfig.uploadProgressLayerTag
            view.setContentHuggingPriority(UILayoutPriority(rawValue: UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            view.setContentHuggingPriority(UILayoutPriority(rawValue: UILayoutPriority.defaultLow.rawValue - 1), for: .vertical)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UILayoutPriority.defaultLow.rawValue - 1), for: .vertical)
            if let strongSelf = self {
                strongSelf.addSubview(view)
                view.snp.makeConstraints({ (make) in
                    make.edges.equalTo(strongSelf)
                })
            }
            return view
        }

        if let layer = view {
            if type(of: layer) != progressType.layerType() {
                self.hideProgress()
                view = newLayerBlock()
            }
        } else {
            view = newLayerBlock()
        }

        if let layer = view as? UploadProgressLayerProtocol {
            var newProgress = progress
            if newProgress > 1 {
                newProgress = 1
            }
            if newProgress == 1 && showType == .incomplete {
                newProgress = 0.99
            }
            layer.progress = newProgress
        }
    }

    func hideProgress() {
        let view: UIView? = self.viewWithTag(UploadProgressConfig.uploadProgressLayerTag)
        view?.removeFromSuperview()
    }
}

extension LarkUIKitExtension where BaseType: UIView {

    /// 设置图片背景并缩放到全屏
    ///
    /// - Parameters:
    ///   - backgroundImage: 背景图
    ///   - size: 背景大小
    public func stretchBackgroundImage(_ backgroundImage: UIImage, _ size: CGSize? = nil) {
        let layer = CAShapeLayer()
        let size = size ?? self.base.bounds.size
        layer.frame = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        layer.contents = backgroundImage.cgImage
        layer.contentsCenter = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)
        layer.contentsScale = UIScreen.main.scale
        self.base.layer.mask = layer
    }

    /// 给气泡描边
    ///
    /// - Parameter displaySize: 视图的大小（描边区域）
    public func drawBubbleBorder(_ displaySize: CGSize, lineWidth: CGFloat = 2.0) {
        for layer in self.base.layer.sublayers ?? [] {
            if let shapeLayer = layer as? CAShapeLayer {
                shapeLayer.removeFromSuperlayer()
            }
        }

        let redius = CGFloat(10)
        let width = displaySize.width
        let height = displaySize.height

        let path = UIBezierPath()
        path.move(to: CGPoint(x: redius, y: 0))
        path.addLine(to: CGPoint(x: width - redius, y: 0))
        path.addArc(withCenter: CGPoint(x: width - redius, y: redius), radius: redius, startAngle: .pi * 3 / 2, endAngle: 2 * .pi, clockwise: true)
        path.addLine(to: CGPoint(x: width, y: height - redius))
        path.addArc(withCenter: CGPoint(x: width - redius, y: height - redius), radius: redius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: redius, y: height))
        path.addArc(withCenter: CGPoint(x: redius, y: height - redius), radius: redius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: redius))
        path.addArc(withCenter: CGPoint(x: redius, y: redius), radius: redius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.strokeColor = UIColor.ud.N300.cgColor
        shapeLayer.fillColor = nil
        shapeLayer.allowsEdgeAntialiasing = true
        self.base.layer.addSublayer(shapeLayer)
    }
}
