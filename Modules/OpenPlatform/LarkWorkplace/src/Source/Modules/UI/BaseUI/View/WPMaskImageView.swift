//
//  WPMaskImageView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/6/15.
//

import UIKit
import FigmaKit

final class WPMaskImageView: UIImageView {

    /// 方圆形半径
    var sqRadius: CGFloat {
        get {
            return self.interSqRadius
        }
        set {
            // 在 layoutSubviews 中进行视图更新
            self.interSqRadius = newValue
        }
    }

    /// 方圆形内描边
    var sqBorder: CGFloat {
        get {
            return self.interSqBorder
        }
        set {
            // 在 layoutSubviews 中进行视图更新
            self.interSqBorder = newValue
        }
    }
    // 内部存储数据
    private var interSqBorder: CGFloat = 0
    private var interSqRadius: CGFloat = 0

    private let maskLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(maskLayer)
    }

    override init(image: UIImage?) {
        super.init(image: image)
        layer.addSublayer(maskLayer)
        updateMaskColor()
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        layer.addSublayer(maskLayer)
        updateMaskColor()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(maskLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
        layer.ux.removeSmoothCorner()
        layer.ux.removeSmoothBorder()
        if interSqRadius != 0 {
            layer.ux.setSmoothCorner(radius: interSqRadius)
        }
        if interSqBorder != 0 {
            layer.ux.setSmoothBorder(width: interSqBorder, color: UIColor.ud.lineDividerDefault)
        }
    }

    override var image: UIImage? {
        didSet {
            updateMaskColor()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.sqBorder = self.interSqBorder
    }

    @discardableResult
    func hideMask(_ hidden: Bool = true) -> WPMaskImageView {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.isHidden = hidden
        CATransaction.commit()
        return self
    }

    private func updateMaskColor() {
        if image != nil {
            maskLayer.ud.setBackgroundColor(UIColor.ud.fillImgMask)
        } else {
            maskLayer.ud.setBackgroundColor(UIColor.clear)
        }
    }
}
