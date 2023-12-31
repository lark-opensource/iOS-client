//
//  UIButton+Ext.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/24.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme

extension UIButton {
    
    func setButtonStyle(isGradient: Bool, bounds: CGRect, xMargin: CGFloat) {
        let button = self
        // Lark主题色和系统不一致时导致背景图片渲染有问题，这里需要做下处理
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.getRealUserInterfaceStyle()
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }
        if isGradient {
            button.backgroundColor = nil
            var textSzie = bounds.size
            let textWidth =  bounds.size.width - xMargin * 2
            if textWidth > 0 {
                textSzie = CGSize(width: max(textWidth, 34), height: textSzie.height)
            }
            if let borderColor = UDColor.AIPrimaryContentDefault(ofSize: bounds.size),
               let textColor = UDColor.AIPrimaryContentDefault(ofSize: textSzie),
               let pressBgColor = UDColor.AIPrimaryFillTransparent02(ofSize: bounds.size) {
                button.setBackgroundImage(UIColor.ud.image(with: pressBgColor, size: bounds.size, scale: UIScreen.main.scale), for: .highlighted)
                button.setTitleColor(textColor, for: .normal)
                button.ud.setLayerBorderColor(borderColor)
            } else {
                LarkInlineAILogger.error("color token is nil")
            }
        } else {
            button.setTitleColor(UDColor.textTitle, for: .normal)
            button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.fillPressed), for: .highlighted)
        
            button.ud.setLayerBorderColor(UDColor.lineBorderComponent)
        }
        
        button.setTitleColor(UDColor.textLinkDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgFloat), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.udtokenComponentOutlinedBg), for: .normal)
        
        if !button.isEnabled {
            button.ud.setLayerBorderColor(UDColor.lineBorderComponent)
        }
    }
}
