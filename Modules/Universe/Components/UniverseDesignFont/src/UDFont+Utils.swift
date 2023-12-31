//
//  UDFont+Utils.swift
//  UniverseDesignFont
//
//  Created by bytedance on 2021/4/30.
//

import Foundation
import UIKit

extension UIFont {

    /// Find appropriate built-in font by name. If not found, it trys to find the font with nearast naming.
    public static func named(_ fontName: String,
                             zoom: UDZoom = UDZoom.currentZoom,
                             transformer: UDZoom.Transformer = .s6) -> UIFont? {
        let name = fontName.lowercased()
        // If the font name matchs current built-in fonts, return directly.
        if let fontType = UDFont.FontType(rawValue: name) {
            return fontType.uiFont(forZoom: transformer.mapper(zoom))
        }
        // Check if the font name is valid. The name should start with a word
        // and end with none or serial of numbers, like 'body1' or 'subheading'.
        guard name.range(of: #"^[a-zA-Z]+\d*$"#, options: .regularExpression) != nil else {
            return nil
        }
        // Find nearest font in built-in fonts dictionary according to the name.
        if let wordRange = name.range(of: #"^[a-zA-Z]+"#, options: .regularExpression),
           let numRange = name.range(of: #"\d*$"#, options: .regularExpression),
           let num = Int(name[numRange]),
           let fonts = UDFont.FontType.fontDic[String(name[wordRange])] {
            if num < fonts.count {
                return fonts[num].uiFont(forZoom: transformer.mapper(zoom))
            } else {
                return fonts.last?.uiFont(forZoom: transformer.mapper(zoom))
            }
        }
        return nil
    }
}

private extension UDFont.FontType {

    static var fontDic: [String: [UDFont.FontType]] {
        [
            "title": [.title0, .title1, .title2, .title3, .title4],
            "body": [.body0, .body1, .body2],
            "caption": [.caption0, .caption1, .caption2, .caption3]
        ]
    }
}

// MARK: - Convenient helper

public extension UIFont {

    /// Return the row height of a single line text in current font.
    var rowHeight: CGFloat {
        return ceil(lineHeight)
    }

    /// Return the row height of multi line text in current font.s
    func rowHeight(forLines numberOfLines: Int) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let multiLineString = Array(repeating: " ", count: numberOfLines).joined(separator: "\n")
        let boundingBox = multiLineString.boundingRect(with: constraintRect,
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [NSAttributedString.Key.font: self],
                                                       context: nil)
        return boundingBox.height
    }

    /// Return the row height in figma.
    /// NOTE: Sometimes it is useful for view height calculation.
    var figmaHeight: CGFloat {
        return UDFont.figmaHeightFor(fontSize: pointSize)
    }

    /// use monospaced digital number
    func withMonospacedNumbers() -> UIFont {
        let monospacedFeature: [UIFontDescriptor.FeatureKey: Any]
        if #available(iOS 15.0, *) {
            monospacedFeature = [ .type: kNumberSpacingType, .selector: kMonospacedNumbersSelector]
        } else {
            monospacedFeature = [ .featureIdentifier: kNumberSpacingType, .typeIdentifier: kMonospacedNumbersSelector]
        }
        let descriptor = fontDescriptor.addingAttributes([.featureSettings: [monospacedFeature]])
        return UIFont(descriptor: descriptor, size: 0)
    }

    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        return self.withTraits(UIFontDescriptor.SymbolicTraits(traits))
    }

    /// Set font traits
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if UDFontAppearance.isCustomFont {
            var font: UIFont
            if let descriptor = self.fontDescriptor.withSymbolicTraits(traits.union(self.fontDescriptor.symbolicTraits)) {
                font = UIFont(descriptor: descriptor, size: pointSize)
            } else {
                font = self
            }
            font.isBold = self.isBold
            font.isItalic = self.isItalic
            let needAddItalic = !self.isItalic && traits.contains(.traitItalic)
            let needAddBold = !self.isBold && traits.contains(.traitBold)
            switch (needAddItalic, needAddBold) {
            case (true, true):
                return font.boldItalic
            case (true, false):
                return font.italic
            case (false, true):
                return font.medium
            case (false, false):
                return font
            }
        } else {
            guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits.union(self.fontDescriptor.symbolicTraits)) else {
                return self
            }
            return UIFont(descriptor: descriptor, size: pointSize)
        }
    }

    func withoutTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        return self.withoutTraits(UIFontDescriptor.SymbolicTraits(traits))
    }

    /// Set font traits
    func withoutTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if UDFontAppearance.isCustomFont {
            var font: UIFont
            if let fd = fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(traits)) {
                font = UIFont(descriptor: fd, size: pointSize)
            } else {
                font = self
            }

            let needRemoveItalic = traits.contains(.traitItalic)
            let needRemoveBold = traits.contains(.traitBold)
            switch (needRemoveItalic, needRemoveBold) {
            case (true, true):
                return font.removeBold().removeItalic()
            case (true, false):
                return font.removeItalic()
            case (false, true):
                return font.removeBold()
            case (false, false):
                return font
            }
        } else {
            guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(traits)) else {
                return self
            }
            return UIFont(descriptor: descriptor, size: 0)
        }
    }

    /// Create a new font that is identical to the current font except the specified weight.
    func withWeight(_ fontWeight: UIFont.Weight) -> UIFont {
        if UDFontAppearance.isCustomFont {
            var attributes = fontDescriptor.fontAttributes
            var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
            
            if UIAccessibility.isBoldTextEnabled {
                if fontWeight == .regular {
                    traits[.weight] = UIFont.Weight.semibold
                } else {
                    traits[.weight] = UIFont.Weight.bold
                }
            } else {
                traits[.weight] = fontWeight
            }

            attributes[.name] = nil
            attributes[.traits] = traits
            attributes[.family] = familyName

            let descriptor = UIFontDescriptor(fontAttributes: attributes)
            let font = UIFont(descriptor: descriptor, size: self.pointSize)
            if fontWeight == .regular {
                font.isBold = false
            } else {
                font.isBold = true
            }
            font.isItalic = false
            return self.isItalic ? font.italic : font.removeItalic()
        } else {
            return UIFont.systemFont(ofSize: self.pointSize, weight: fontWeight)
        }
    }

    /// whether to set italic
    func withItalic(_ showItalic: Bool = true) -> UIFont {
        if UDFontAppearance.isCustomFont {
            let matrix = createMatrixWith(showItalic) ?? .identity
            let font = UIFont(descriptor: self.fontDescriptor.withMatrix(matrix), size: self.pointSize)
            font.isItalic = showItalic
            font.isBold = self.isBold
            return font
        } else {
            if showItalic {
                return self.withTraits(.traitItalic)
            } else {
                return self.withoutTraits(.traitItalic)
            }
        }
    }

    /// remove italic effect
    func removeItalic() -> UIFont {
        return self.withItalic(false)
    }

    func removeBold() -> UIFont {
        return self.regular
    }

    /// 创建放射变换
    fileprivate func createMatrixWith(_ showItalic: Bool) -> CGAffineTransform? {
        if showItalic {
            if self.isItalic {
                return nil
            } else {
                let slope: Float = showItalic ? 11 : 0
                return .init(a: 1, b: 0, c: CGFloat(tanf(.pi / 180 * slope)), d: 1, tx: 0, ty: 0)
            }
        } else {
            return nil
        }
    }

    func italicOffset() -> CGFloat {
        guard self.isItalic, UDFontAppearance.isCustomFont else { return 0 }
        let radians = CGFloat.pi / 180 * 12
        let italicWidth = abs(self.pointSize * tan(radians))
        return italicWidth * 0.7
    }
}

public extension String {
    /// Return the row width of current string in specified font within constrainted height.
    func getWidth(withConstrainedHeight height: CGFloat = .greatestFiniteMagnitude, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        )
        return ceil(boundingBox.width)
    }

    /// Return the row height of current string in specified font within constrainted width.
    func getHeight(withConstrainedWidth width: CGFloat = .greatestFiniteMagnitude, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}
