//
//  MessageCardPinClipView.swift
//  LarkOpenPlatform
//
//  Created by MJXin on 2022/6/16.
//

import Foundation
import UIKit
import UniverseDesignTheme
import UniverseDesignColor

final class MessageCardPinClipView: UIView {
    private var gradientLayer = CAGradientLayer()
    public override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer = CAGradientLayer()
        gradientLayer.ud.setColors(getGradientColors())
        gradientLayer.locations = [0.0, 1.0]
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.ud.setColors(getGradientColors())
        gradientLayer.frame = bounds
    }
    
    func getGradientColors() -> [UIColor] {
        // 设置正确的 TraitCollection
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            UITraitCollection.current = correctTrait
        }
        let topColor = UIColor.ud.bgFloat.withAlphaComponent(0)
        let buttomColor =  UIColor.ud.bgFloat.withAlphaComponent(1)
        let gradientColors = [topColor, buttomColor]
        return gradientColors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
