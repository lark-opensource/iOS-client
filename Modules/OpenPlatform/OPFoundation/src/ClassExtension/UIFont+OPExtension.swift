//
//  UIFont+OPExtension.swift
//  TTMicroApp
//
//  Created by baojianjun on 2022/9/22.
//

import UIKit

public extension UIFont {
    
    // 数字类型的font-weight可参考 WebKit BuilderConverter::convertFontWeight, 支持程度再做考虑
    private func with(weight: UIFont.Weight) -> UIFont {
        // 支持bold
        var symbolicTraits: UIFontDescriptor.SymbolicTraits?
        switch weight {
        case .bold, .heavy:
            symbolicTraits = .traitBold
        default:
            break
        }
        
        if let symbolicTraits, let result = fontDescriptor.withSymbolicTraits(symbolicTraits) {
            return UIFont(descriptor: result, size: pointSize)
        }
        return self
    }
    
    @objc static func css(fontFamily: String?, fontSize: CGFloat, fontWeight: String?) -> UIFont {
        let weight = UIFont.fontWeight(withStr: fontWeight)
        guard let fontFamily = fontFamily else {
            return UIFont.systemFont(ofSize: fontSize, weight: weight)
        }
        
        // font family
        let fontFamilyArray = fontFamily.components(separatedBy: ",").map { str in
            str.replacingOccurrences(of: "\"", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        
        // WebKit Source/WebCore/editing/cocoa/HTMLConverter.mm 使用了私有方法, 此处无法使用
        // 根据fontFamily生成的font, 结合weight
        for fontFamilyStr in fontFamilyArray {
            if let font = UIFont(name: fontFamilyStr, size: fontSize) {
                let result = font.with(weight: weight)
                return result
            }
        }
        
        return UIFont.systemFont(ofSize: fontSize, weight: weight)
    }
}
