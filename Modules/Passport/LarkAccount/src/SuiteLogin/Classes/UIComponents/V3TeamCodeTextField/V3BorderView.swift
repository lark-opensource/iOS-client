//
//  V3BorderView.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation

extension V3BorderView {
    public enum BorderStyle {
        case bottomLine, roundedBorder
    }

    enum BorderState {
        case normal
        case hilighted
        case error
    }
}

extension V3BorderView {
    struct Layout {
        static let borderWidth: CGFloat = 1
        static let roundedBorderRadius: CGFloat = Common.Layer.commonButtonRadius
        static let roundedBorderLineWidth: CGFloat = 1
    }
}

class V3BorderView: ShapeLayerContainerView {

    let borderStyle: BorderStyle

    var state: BorderState = .normal {
        didSet {
            if oldValue != state {
                animateBorder()
            }
        }
    }

    init(borderStyle: BorderStyle = .roundedBorder) {
        self.borderStyle = borderStyle
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
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

    var errorBottomLineColor: UIColor {
        return UIColor.ud.functionDangerContentDefault
    }

    var fillErrorBottomLineColor: UIColor {
        switch borderStyle {
        case .bottomLine:
            return errorBottomLineColor
        case .roundedBorder:
            return .clear
        }
    }

    var borderLineWidth: CGFloat {
        switch borderStyle {
        case .bottomLine:
            return ONE_PIXEL
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

        switch state {
        case .normal:
            bottomLine.ud.setStrokeColor(bottomLineColor)
            bottomLine.ud.setFillColor(fillBottomLineColor)
        case .hilighted:
            bottomLine.ud.setStrokeColor(activeBottomLineColor)
            bottomLine.ud.setFillColor(fillActiveBottomLineColor)
        case .error:
            bottomLine.ud.setStrokeColor(errorBottomLineColor)
            bottomLine.ud.setFillColor(fillErrorBottomLineColor)
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

    @objc
    func cancelHighlight() {
        state = .normal
    }

    func update(highlight: Bool) {
        state = highlight ? .hilighted : .normal
    }

    private func animateBorder() {
        guard let bottomLine = bottomLine else {
            return
        }
        CATransaction.begin()
        let strokeColorAnimation = CABasicAnimation(keyPath: "strokeColor")
        strokeColorAnimation.duration = 0.3

        let fromColor = UIColor(cgColor: bottomLine.strokeColor ?? UIColor.clear.cgColor)

        switch state {
        case .normal:
            bottomLine.ud.setStrokeColor(bottomLineColor)
            bottomLine.ud.setFillColor(fillBottomLineColor)
            strokeColorAnimation.fromValue = fromColor
            strokeColorAnimation.toValue = bottomLineColor
        case .hilighted:
            bottomLine.ud.setStrokeColor(activeBottomLineColor)
            bottomLine.ud.setFillColor(fillActiveBottomLineColor)
            strokeColorAnimation.fromValue = fromColor
            strokeColorAnimation.toValue = activeBottomLineColor
        case .error:
            bottomLine.ud.setStrokeColor(errorBottomLineColor)
            bottomLine.ud.setFillColor(fillErrorBottomLineColor)
            strokeColorAnimation.fromValue = fromColor
            strokeColorAnimation.toValue = errorBottomLineColor
        }

        bottomLine.add(strokeColorAnimation, forKey: "strokeColor")
        CATransaction.commit()
    }
}
