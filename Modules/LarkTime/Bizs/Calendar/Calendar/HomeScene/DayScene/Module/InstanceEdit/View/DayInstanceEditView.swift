//
//  DayInstanceEditView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/12.
//

import UIKit
import CalendarFoundation

/// DayScene - InstanceEdit - InstanceView

final class DayInstanceEditView: UIView {

    var padding: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }

    var borderColor = UIColor.blue {
        didSet {
            borderLayer.ud.setBorderColor(borderColor, bindTo: self)
            knobViews.top.borderColor = borderColor
            knobViews.bottom.borderColor = borderColor
        }
    }

    var contentView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let contentView = contentView {
                contentView.removeFromSuperview()
                clipView.insertSubview(contentView, at: 0)
                placeholderLabel.isHidden = true
            } else {
                placeholderLabel.isHidden = false
            }
            setNeedsLayout()
        }
    }

    var placeholder: String? {
        didSet { placeholderLabel.text = placeholder }
    }

    // 修改时间把手 views
    let knobViews = (
        top: KnobView(),
        bottom: KnobView()
    )

    private let knotViewSize = CGSize(width: 39, height: 39)

    // 边框阴影
    private let borderGradientLayers = (
        top: CAGradientLayer(),
        left: CAGradientLayer(),
        bottom: CAGradientLayer(),
        right: CAGradientLayer()
    )

    // 角阴影
    private let cornerGradientLayers = (
        topLeft: CAGradientLayer(),
        topRight: CAGradientLayer(),
        bottomRight: CAGradientLayer(),
        bottomLeft: CAGradientLayer()
    )

    private let borderLayer = CALayer()

    private let clipView = UIView()

    // placeholder
    private let placeholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipView.clipsToBounds = true
        addSubview(clipView)

        let gradientLayerInfos: [(layer: CAGradientLayer, startPoint: CGPoint, endPoint: CGPoint)] = [
            (borderGradientLayers.top, CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0)),
            (borderGradientLayers.left, CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 0)),
            (borderGradientLayers.bottom, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1)),
            (borderGradientLayers.right, CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0)),
            (cornerGradientLayers.topLeft, CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 0.5)),
            (cornerGradientLayers.topRight, CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 0.5)),
            (cornerGradientLayers.bottomLeft, CGPoint(x: 1, y: 0), CGPoint(x: 0.5, y: 0.5)),
            (cornerGradientLayers.bottomRight, CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0.5))
        ]
        gradientLayerInfos.forEach { info in
            info.layer.startPoint = info.startPoint
            info.layer.endPoint = info.endPoint
            layer.addSublayer(info.layer)
        }

        clipView.layer.cornerRadius = 4

        placeholderLabel.textAlignment = .center
        placeholderLabel.font = UIFont.cd.mediumFont(ofSize: 14)
        placeholderLabel.textColor = UIColor.ud.primaryContentDefault
        placeholderLabel.backgroundColor = UIColor.ud.primaryFillSolid01.withAlphaComponent(0.85)
        clipView.addSubview(placeholderLabel)

        borderLayer.borderWidth = 1
        borderLayer.cornerRadius = 5
        layer.addSublayer(borderLayer)

        addSubview(knobViews.top)
        addSubview(knobViews.bottom)

        hideKnobs()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        clipView.frame = bounds.inset(by: padding)
        borderLayer.frame = bounds.inset(by: padding)

        knobViews.top.frame = CGRect(
            x: bounds.width - knotViewSize.width - 4 - padding.right,
            y: padding.top - (knotViewSize.height / 2 - 1),
            width: knotViewSize.width,
            height: knotViewSize.height
        )

        knobViews.bottom.frame = CGRect(
            x: 4 + padding.left,
            y: bounds.height - (knotViewSize.height / 2 + 1) - padding.bottom,
            width: knotViewSize.width,
            height: knotViewSize.height
        )

        contentView?.frame = clipView.bounds
        placeholderLabel.frame = clipView.bounds

        borderGradientLayers.top.frame = CGRect(x: 0.5, y: -4, width: bounds.width, height: 4)
            .insetBy(dx: padding.left, dy: padding.top)
        borderGradientLayers.left.frame = CGRect(x: -4.5, y: 0, width: 5, height: bounds.height)
            .insetBy(dx: padding.left, dy: padding.top)
        borderGradientLayers.bottom.frame = CGRect(x: 0, y: frame.height, width: bounds.width, height: 6)
            .insetBy(dx: -padding.right, dy: -padding.bottom)
        borderGradientLayers.right.frame = CGRect(x: bounds.width, y: 0, width: 5, height: bounds.height)
            .insetBy(dx: -padding.right, dy: -padding.bottom)

        cornerGradientLayers.topLeft.frame = CGRect(x: -4.5, y: -4, width: 5, height: 4)
            .insetBy(dx: padding.left, dy: padding.top)
        cornerGradientLayers.topRight.frame = CGRect(x: bounds.width, y: -4, width: 5, height: 4)
            .insetBy(dx: padding.left, dy: padding.top)
        cornerGradientLayers.bottomLeft.frame = CGRect(x: -5, y: bounds.height, width: 5, height: 6)
            .insetBy(dx: -padding.right, dy: -padding.bottom)
        cornerGradientLayers.bottomRight.frame = CGRect(x: bounds.width, y: bounds.height, width: 5, height: 6)
            .insetBy(dx: -padding.right, dy: -padding.bottom)
    }

    func hideKnobs() {
        knobViews.top.isHidden = true
        knobViews.bottom.isHidden = true
    }

    func showKnobs() {
        knobViews.top.isHidden = false
        knobViews.bottom.isHidden = false
    }

}

extension DayInstanceEditView {

    // 抓手 view
    final class KnobView: UIView {
        var borderColor: UIColor = UIColor.ud.primaryContentDefault {
            didSet { circleView.layer.ud.setBorderColor(borderColor) }
        }

        private let circleView = UIView()

        override init(frame: CGRect) {
            super.init(frame: frame)

            circleView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            circleView.layer.ud.setBorderColor(borderColor)
            circleView.layer.borderWidth = 2
            circleView.layer.masksToBounds = true
            circleView.isUserInteractionEnabled = false
            addSubview(circleView)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("not implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            circleView.frame.size = CGSize(width: 9, height: 9)
            circleView.layer.cornerRadius = 4.5
            circleView.center = bounds.center
        }
    }

}
