//
//  UIView+Ext.swift
//  LarkInlineAI
//
//  Created by ByteDance on 2023/7/3.
//

import Foundation
import UIKit
import UniverseDesignTheme

extension UIView {
    
    var affiliatedViewController: UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.affiliatedViewController
        } else {
            return nil
        }
    }
}

extension UIColor {
    /// 忽略alpha，不带#前缀
    var hexString: String {
        let color: UIColor
        // 依照app设置
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            color = self.alwaysDark
        } else {
            color = self.alwaysLight
        }
        let string = UIColor.ud.hex(color, withAlphaPrefix: false, withPrefix: false) ?? ""
        return string
    }
}


extension UIView {

    static func createCustomViewForDialog(string: String) -> UIView {
        
        let attributedText = NSMutableAttributedString(string: string)
        attributedText.addAttribute(.font, value: UIFont.ud.body0(.fixed))
        attributedText.addAttribute(.foregroundColor, value: UIColor.ud.textTitle)
        
        let paragraphStyle = NSMutableParagraphStyle(); paragraphStyle.alignment = .left; paragraphStyle.lineSpacing = 4
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle)
        
        let contentLabel = UILabel()
        contentLabel.attributedText = attributedText; contentLabel.numberOfLines = 0; contentLabel.isUserInteractionEnabled = true
        
        let label = UILabel(); label.attributedText = attributedText; label.numberOfLines = 0; label.isUserInteractionEnabled = false
        let scrollView = UIScrollView(); scrollView.backgroundColor = UIColor.ud.bgFloat; scrollView.bounces = false
        scrollView.addSubview(label); label.snp.makeConstraints { make in make.edges.equalToSuperview(); make.width.equalToSuperview() }
        contentLabel.addSubview(scrollView); scrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        return contentLabel
    }
}
