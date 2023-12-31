//
//  MagicShareGradientBackgroundButton.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/8/1.
//

import Foundation

/// 跟随主讲人按钮，背景色渐变且高亮时显示蒙层
class MagicShareGradientBackgroundButton: VisualButton {

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                highlightMaskLayer.isHidden = false
            } else {
                highlightMaskLayer.isHidden = true
            }
        }
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.ud.setColors([UIColor.ud.colorfulViolet, UIColor.ud.R400, UIColor.ud.colorfulYellow], bindTo: self)
        gradientLayer.locations = [0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        return gradientLayer
    }()

    private lazy var highlightMaskLayer: CALayer = {
        let layer = CALayer()
        layer.ud.setBackgroundColor(UIColor.ud.N00.withAlphaComponent(0.3), bindTo: self)
        layer.isHidden = true
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.insertSublayer(highlightMaskLayer, at: 0)
        self.layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.isHidden && self.frame.size.height == 0 {
            self.layoutIfNeeded()
        }
        // 去除隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        highlightMaskLayer.frame = bounds
        CATransaction.commit()
    }

}
