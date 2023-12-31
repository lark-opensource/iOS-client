//
//  OPThemeImageView.swift
//  OPFoundation
//
//  Created by yinyuan on 2021/7/27.
//

import Foundation
import UniverseDesignTheme

/// 带有一个 fillImgMask 的UIImageView
@objcMembers
public final class OPThemeImageView: UIImageView {
    
    private var maskLayer: CALayer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupMaskLayer()
    }
    
    public override init(image: UIImage?) {
        super.init(image: image)
        setupMaskLayer()
    }
    
    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        setupMaskLayer()
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMaskLayer()
    }
    
    private func setupMaskLayer() {
        if #available(iOS 13.0, *) {
            let maskLayer = CALayer()
            layer.addSublayer(maskLayer)
            maskLayer.ud.setBackgroundColor(UIColor.ud.fillImgMask)
            maskLayer.isHidden = (traitCollection.userInterfaceStyle != .dark)
            self.maskLayer = maskLayer
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13.0, *) {
            maskLayer?.frame = bounds
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                maskLayer?.isHidden = (traitCollection.userInterfaceStyle != .dark)
            }
        }
    }
}
