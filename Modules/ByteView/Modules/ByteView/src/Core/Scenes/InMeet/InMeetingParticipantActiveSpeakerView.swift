//
//  InMeetingParticipantActiveSpeakerView.swift
//  ByteView
//
//  Created by yangyao on 2021/4/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class InMeetingParticipantActiveSpeakerView: UIView {
    private var borderLayer: CAShapeLayer = CAShapeLayer()
    var corners: UIRectCorner = .allCorners {
        didSet {
            guard corners != oldValue else {
                return
            }
            setNeedsLayout()
        }
    }

    var asStrokeOutside: Bool = true {
        didSet {
            guard asStrokeOutside != oldValue else {
                return
            }
            setNeedsLayout()
        }
    }

    var borderColor: UIColor = UIColor.ud.functionSuccessFillDefault {
        didSet {
            borderLayer.ud.setStrokeColor(borderColor)
        }
    }
    var borderWidth: CGFloat = 2.0 {
        didSet {
            guard self.borderWidth != oldValue else {
                return
            }
            borderLayer.lineWidth = borderWidth
            setNeedsLayout()
        }
    }
    var roundedRadius: CGFloat = 8.0 {
        didSet {
            guard roundedRadius != oldValue else {
                return
            }
            setNeedsLayout()
        }
    }

    var fillColor: UIColor? {
        didSet {
            if let fillColor = fillColor {
                borderLayer.ud.setFillColor(fillColor)
            } else {
                borderLayer.fillColor = nil
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        layer.addSublayer(borderLayer)
        borderLayer.fillColor = nil
        borderLayer.ud.setStrokeColor(borderColor)
        borderLayer.lineWidth = borderWidth

        borderLayer.ud.setShadowColor(UIColor.ud.G400.withAlphaComponent(0.6))
        borderLayer.shadowRadius = 4
        borderLayer.shadowOpacity = 1
        borderLayer.shadowOffset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // UX 交互图 针对 AS 使用外部轮廓描边，CoreAnimation 不支持仅在外部描边，因此需要增加 1.0 偏移量
        let roundedRadius: CGFloat
        if asStrokeOutside {
           roundedRadius = self.roundedRadius + self.borderWidth * 0.5
        } else {
           roundedRadius = self.roundedRadius - self.borderWidth * 0.5
        }

        let borderPath = UIBezierPath(roundedRect: bounds,
                                      byRoundingCorners: corners,
                                      cornerRadii: CGSize(width: roundedRadius, height: roundedRadius))
        borderLayer.path = borderPath.cgPath
        borderLayer.frame = bounds

        let shadowOutsidePath = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: -1, left: -1, bottom: -1, right: -1)),
                                             byRoundingCorners: corners,
                                             cornerRadii: CGSize(width: roundedRadius, height: roundedRadius))
        let shadowInsidePath = UIBezierPath(roundedRect: bounds,
                                            byRoundingCorners: corners,
                                            cornerRadii: CGSize(width: roundedRadius, height: roundedRadius))
        shadowOutsidePath.append(shadowInsidePath.reversing())

        borderLayer.shadowPath = shadowOutsidePath.cgPath
        borderLayer.frame = bounds
    }
}
