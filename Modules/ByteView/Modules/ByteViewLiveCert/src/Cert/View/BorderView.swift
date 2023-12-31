//
//  BorderView.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignTheme
import UniverseDesignColor

extension BorderView {
    enum BorderStyle {
        case bottomLine, roundedBorder
    }

    struct Layout {
        static let borderWidth: CGFloat = 1
        static let roundedBorderRadius: CGFloat = 4
        static let roundedBorderLineWidth: CGFloat = 1
    }
}

final class BorderView: UIView {

    var onePixel: CGFloat {
        1 / self.vc.displayScale
    }

    let borderStyle: BorderStyle = .roundedBorder

    var highlight: Bool = false {
        didSet {
            if oldValue != highlight {
                bottomLineAnimated()
            }
        }
    }

    var shapeLayer: CAShapeLayer? {
        return layer as? CAShapeLayer
    }

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let shapeLayer = layer as? CAShapeLayer else {
            return
        }
        shapeLayer.contentsScale = self.vc.displayScale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawBorderLine()
    }

    var bottomLine: CAShapeLayer? {
        return shapeLayer
    }

    var bottomLineColor: UIColor {
        return UIColor.ud.lineBorderComponent
    }

    var fillBottomLineColor: UIColor {
        switch borderStyle {
        case .bottomLine:
            return bottomLineColor
        case .roundedBorder:
            return .clear
        }
    }

    var activeBottomLineColor: UIColor {
        return UIColor.ud.primaryContentDefault
    }

    var fillActiveBottomLineColor: UIColor {
        switch borderStyle {
        case .bottomLine:
            return activeBottomLineColor
        case .roundedBorder:
            return .clear
        }
    }

    var borderLineWidth: CGFloat {
        switch borderStyle {
        case .bottomLine:
            return onePixel
        case .roundedBorder:
            return Layout.roundedBorderLineWidth
        }
    }

    private func drawBorderLine() {
        guard let bottomLine = bottomLine else { return }
        let rect = bounds
        if rect.isEmpty {
            return
        }
        if highlight {
            bottomLine.ud.setStrokeColor(activeBottomLineColor)
            bottomLine.ud.setFillColor(fillActiveBottomLineColor)
        } else {
            bottomLine.ud.setStrokeColor(bottomLineColor)
            bottomLine.ud.setFillColor(fillBottomLineColor)
        }
        bottomLine.lineWidth = borderLineWidth
        let path: CGPath
        switch borderStyle {
        case .bottomLine:
            path = CGPath(rect: CGRect(x: rect.minX, y: rect.minY + rect.height - borderLineWidth, width: rect.width, height: borderLineWidth), transform: nil)
        case .roundedBorder:
            path = CGPath(roundedRect: rect, cornerWidth: Layout.roundedBorderRadius, cornerHeight: Layout.roundedBorderRadius, transform: nil)
        }
        bottomLine.path = path
    }

    func update(highlight: Bool) {
        self.highlight = highlight
    }

    private func bottomLineAnimated() {
        guard let bottomLine = bottomLine else {
            return
        }
        let fillAnimation = CABasicAnimation(keyPath: "strokeColor")
        fillAnimation.duration = 0.3
        if highlight {
            bottomLine.ud.setStrokeColor(activeBottomLineColor)
            bottomLine.ud.setFillColor(fillActiveBottomLineColor)
            fillAnimation.fromValue = bottomLineColor.cgColor
            fillAnimation.toValue = activeBottomLineColor.cgColor
        } else {
            bottomLine.ud.setStrokeColor(bottomLineColor)
            bottomLine.ud.setFillColor(fillBottomLineColor)
            fillAnimation.fromValue = activeBottomLineColor.cgColor
            fillAnimation.toValue = bottomLineColor.cgColor
        }
        bottomLine.add(fillAnimation, forKey: "strokeColor")
    }
}
