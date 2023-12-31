//
//  String+RichText.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/1.
//

import Foundation
import LKCommonsLogging
import CoreGraphics
import UniverseDesignColor
import UniverseDesignTheme

private let logger = Logger.plog(String.self, category: "SuiteLogin.RichText")

extension String {
    var html2Attributed: NSAttributedString? {
        do {
            guard let data = data(using: String.Encoding.utf8) else {
                logger.info("parse html rich text to AttributedString Fail length: \(self.count), encode utf8 failed")
                return nil
            }
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        } catch {
            logger.info("parse html rich text to AttributedString Fail length: \(self.count), error: \(error)")
            return nil
        }
    }

    func html2Attributed(font: UIFont, forgroundColor: UIColor = .black) -> NSAttributedString {
        let colorString = self.replaceTokenWithHexColor(string: self)
        let attributedString = NSMutableAttributedString(attributedString: colorString.html2Attributed ?? .init())
        attributedString.beginEditing()
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, _) in
            if let oldFont = value as? UIFont {
                var newDescriptor = oldFont.fontDescriptor.withFamily(font.familyName)
                let symbolicTraits: UIFontDescriptor.SymbolicTraits
                // html rich text font has italic or bold style, inherit
                // else use default
                if !(oldFont.fontDescriptor.symbolicTraits.contains(.traitItalic) ||
                    oldFont.fontDescriptor.symbolicTraits.contains(.traitBold)) {
                    symbolicTraits = font.fontDescriptor.symbolicTraits
                } else {
                    symbolicTraits = oldFont.fontDescriptor.symbolicTraits
                }
                if let descriptor = newDescriptor.withSymbolicTraits(symbolicTraits) {
                    newDescriptor = descriptor
                }
                let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
                attributedString.addAttribute(.font, value: newFont, range: range)
            }
        }
        attributedString.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attributedString.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, _) in
            if let oldColor = value as? UIColor {
                // black will override by forgroundColor
                if oldColor == UIColor.black, forgroundColor != oldColor {
                    attributedString.addAttribute(.foregroundColor, value: forgroundColor, range: range)
                }
            }
        }
        attributedString.endEditing()
        return attributedString
    }

    /**
    富文本token色值替换成真实颜色：
    1. 色值表：
    https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9?sheet=VWFxF8&table=tbla6gFejRrROOeD&view=vewSGyZ02H
    2. 仅支持主端支持的token, 无法转换基础色表
    3. 文案给的是"primary_pri_500", 请求UD时需要用"-"替换"_"
    4. 其他token转color问题可以询问 @姚启灏
    */
    private func replaceTokenWithHexColor(string: String) -> String  {
        guard let regex = try? NSRegularExpression.init(pattern: #"(?<=color:@\{)(.+?)(?=\})"#, options: .caseInsensitive) else {
            logger.error("parse html rich text: set regex pattern failed.")
            return ""
        }
        
        var targetString: String = string
        let matches = regex.matches(in: targetString, options: [], range: NSMakeRange(0, targetString.count))

        var sourceSubStrings: [String] = []
        _ = matches.map { item in
            if let sourceSubString = targetString.substring(in: item.range) {
                sourceSubStrings.append(sourceSubString)
            }
        }

        _ = sourceSubStrings.map { subString in
            let tempString = targetString.replacingOccurrences(of: "@{\(subString)}", with: subString.getHexColor())
            targetString = tempString
        }

        return targetString
    }
}

extension String {
    private func getHexColor() -> String {
        let targetString = self.replacingOccurrences(of: "_", with: "-")
        let color = UDColor.getValueByBizToken(token: targetString)
        let themeColor: UIColor?
        if #available(iOS 13.0, *), let color = color {
            let theme = UDThemeManager.getRealUserInterfaceStyle()
            let trait = UITraitCollection(userInterfaceStyle: theme)
            themeColor = color.resolvedCompatibleColor(with: trait)
        } else {
            themeColor = color
        }
        guard let hex = themeColor?.hexString else {
            logger.error("parse html rich text: wrong token!", method: .local)
            return ""
        }
        return hex
    }
}

extension NSParagraphStyle {
    static var adjustLineHeightParagraph: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return paragraphStyle
    }
}

extension NSMutableAttributedString {
    func adjustLineHeight() {
        addAttribute(.paragraphStyle, value: NSParagraphStyle.adjustLineHeightParagraph, range: NSRange(location: 0, length: self.length))
    }
}

extension UILabel {
   func setHtml(_ htmString: String) {
       attributedText = htmString.html2Attributed(font: self.font, forgroundColor: UIColor.ud.textTitle)
   }
}

extension UIColor {
    // UIColor -> Hex String
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let multiplier = CGFloat(255.999999)

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }

    static func == (l: UIColor, r: UIColor) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        l.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        r.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
    }

    static func != (l: UIColor, r: UIColor) -> Bool {
        return !(l == r)
    }
}

func == (l: UIColor?, r: UIColor?) -> Bool {
   let l = l ?? .clear
   let r = r ?? .clear
   return l == r
}
