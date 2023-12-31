//
//  ShapeButton.swift
//  ByteView
//
//  Created by yangyao on 2021/5/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class ShapeButton: UIButton {
    public var shadowColor: UIColor? {
        didSet {
            layer.ud.setShadowColor(shadowColor ?? UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0))
        }
    }
    // 系统默认值
    public var shadowOpacity: Float = 0 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    public var shadowOffset: CGSize = CGSize(width: 0, height: -3) {
        didSet {
            layer.shadowOffset = shadowOffset
        }
    }
    public var shadowRadius: CGFloat = 3 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    public var enlargeRegionInsets: UIEdgeInsets?

    private var normalColor: UIColor?
    private var highlightedColor: UIColor?
    private var selectedColor: UIColor?
    private var disabledColor: UIColor?

    func setIcon(_ icon: Icon?, color: UIColor? = .white, for state: UIControl.State) {
        switch state {
        case .normal:
            normalColor = color
        case .highlighted:
            highlightedColor = color
        case .selected:
            selectedColor = color
        case .disabled:
            disabledColor = color
        default:
            normalColor = color
        }

        shapeLayer.iconDrawable = icon
        shapeLayer.fillColor = normalColor?.cgColor
    }

    private lazy var shapeLayer: ShapeLayer = {
        let layer = ShapeLayer()
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            shapeLayer.fillColor = isSelected ? selectedColor?.cgColor : normalColor?.cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet {
            shapeLayer.fillColor = isHighlighted ? highlightedColor?.cgColor : normalColor?.cgColor
        }
    }

    override var isEnabled: Bool {
        didSet {
            shapeLayer.fillColor = isEnabled ? normalColor?.cgColor : disabledColor?.cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        shapeLayer.frame = bounds
        shapeLayer.setNeedsLayout()
        shapeLayer.layoutIfNeeded()

        layer.shadowPath = shapeLayer.transformedPath
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let insets = enlargeRegionInsets {
            let transformInsets = UIEdgeInsets(top: -insets.top,
                                              left: -insets.left,
                                              bottom: -insets.bottom,
                                              right: -insets.right)
            let region = bounds.inset(by: transformInsets)
            return region.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
}
