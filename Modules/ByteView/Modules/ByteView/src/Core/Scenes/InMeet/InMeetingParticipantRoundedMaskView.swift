//
//  InMeetingParticipantRoundedMaskView.swift
//  ByteView
//
//  Created by yangyao on 2021/4/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class InMeetingParticipantRoundedMaskView: UIView {
    // 圆角
    var cornerColor: UIColor = UIColor.ud.bgBody {
        didSet {
            roundedLayer.ud.setFillColor(cornerColor)
        }
    }
    var cornerRadius: CGFloat = 6.0 {
        didSet {
            guard cornerRadius != oldValue else {
                return
            }
            roundedLayer.isHidden = cornerRadius == 0.0
            borderLayer.isHidden = cornerRadius == 0.0

            setNeedsLayout()
        }
    }
    // 边框
    var borderColor: UIColor = UIColor.ud.lineDividerDefault {
        didSet {
            borderLayer.ud.setStrokeColor(borderColor, bindTo: self)
        }
    }
    var borderWidth: CGFloat = 0.5 {
        didSet {
            borderLayer.lineWidth = borderWidth
        }
    }

    private var roundedLayer: CAShapeLayer = CAShapeLayer()
    private var borderLayer: CAShapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(roundedLayer)
        layer.addSublayer(borderLayer)

        roundedLayer.ud.setFillColor(cornerColor)
        roundedLayer.fillRule = .evenOdd
        roundedLayer.ud.setStrokeColor(cornerColor)
        roundedLayer.lineWidth = borderWidth

        borderLayer.fillColor = nil
        borderLayer.ud.setStrokeColor(borderColor, bindTo: self)
        borderLayer.lineWidth = borderWidth
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let roundedPath = UIBezierPath(rect: bounds)
        roundedPath.append(UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius))
        roundedLayer.path = roundedPath.cgPath

        let borderPath = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: 0.5, left: 0.5, bottom: 0.5, right: 0.5)), cornerRadius: cornerRadius)
        borderLayer.path = borderPath.cgPath

        roundedLayer.frame = bounds
        borderLayer.frame = bounds
    }
}
