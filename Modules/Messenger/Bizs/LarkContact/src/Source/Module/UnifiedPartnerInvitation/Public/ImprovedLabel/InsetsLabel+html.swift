//
//  InsetsLabel+html.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/6/11.
//

import Foundation
import UIKit

extension String {
    func html2AttributeStringSafe(_ handler: @escaping (NSAttributedString?) -> Void) {
        // https://izziswift.com/nsattributedstring-crash-when-converting-html-to-attrubuted-string/
        DispatchQueue.main.async {
            handler(html2AttributeStringUnsafe())
        }
    }

    func html2AttributeStringUnsafe() -> NSAttributedString? {
        guard let data = data(using: String.Encoding.utf8) else {
            return nil
        }
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }

    func html2AttributeStringSafe(
        font: UIFont? = nil,
        forgroundColor: UIColor? = nil,
        paragraphStyle: NSParagraphStyle? = nil,
        handler: @escaping (NSAttributedString?) -> Void
    ) {
        html2AttributeStringSafe { (result) in
            guard let result = result else {
                handler(nil)
                return
            }
            let attributedString = NSMutableAttributedString(attributedString: result)
            attributedString.edit(with: font, forgroundColor: forgroundColor, paragraphStyle: paragraphStyle)
            handler(attributedString)
        }
    }

    func html2AttributeStringUnsafe(
        font: UIFont? = nil,
        forgroundColor: UIColor? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) -> NSAttributedString? {
        guard let result = html2AttributeStringUnsafe() else {
            return nil
        }
        let attributedString = NSMutableAttributedString(attributedString: result)
        attributedString.edit(with: font, forgroundColor: forgroundColor, paragraphStyle: paragraphStyle)
        return attributedString
    }
}

extension NSMutableAttributedString {
    func edit(
        with font: UIFont? = nil,
        forgroundColor: UIColor? = nil,
        paragraphStyle: NSParagraphStyle? = nil
    ) {
        beginEditing()
        if let font = font {
            enumerateAttribute(
                .font,
                in: NSRange(location: 0, length: length),
                options: NSAttributedString.EnumerationOptions(rawValue: 0)
            ) { (value, range, _) in
                if let oldFont = value as? UIFont {
                    var newDescriptor = oldFont.fontDescriptor.withFamily(font.familyName)
                    let symbolicTraits: UIFontDescriptor.SymbolicTraits
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
                    addAttribute(.font, value: newFont, range: range)
                }
            }
        }
        if let forgroundColor = forgroundColor {
            enumerateAttribute(
                .foregroundColor,
                in: NSRange(location: 0, length: length),
                options: NSAttributedString.EnumerationOptions(rawValue: 0)
            ) { (value, range, _) in
                if let oldColor = value as? UIColor {
                    if forgroundColor != oldColor {
                        addAttribute(.foregroundColor, value: forgroundColor, range: range)
                    }
                }
            }
        }
        if let paragraphStyle = paragraphStyle {
            enumerateAttribute(
                .paragraphStyle,
                in: NSRange(location: 0, length: length),
                options: NSAttributedString.EnumerationOptions(rawValue: 0)
            ) { (value, range, _) in
                if (value as? NSParagraphStyle) != nil {
                    addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                }
            }
        }
        endEditing()
    }
}

extension InsetsLabel {
    func setHtml(_ htmlString: String, forceLineSpacing: CGFloat? = nil, isSafeRendering: Bool = true) {
        var paragraphStyle: NSParagraphStyle?
        if let forceLineSpacing = forceLineSpacing {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = forceLineSpacing
            style.alignment = textAlignment
            style.lineBreakMode = lineBreakMode
            paragraphStyle = style
        }
        htmlString.html2AttributeStringSafe(
            font: font,
            forgroundColor: textColor,
            paragraphStyle: paragraphStyle
        ) { (result) in
            self.setText(attributedString: result)
        }
    }
}
