//
//  BTURLToTitleConverter.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/21.
//  


import SKFoundation
import SKUIKit
import SKCommon
import UniverseDesignColor
import SKBrowser
import SpaceInterface


final class BTURLToTitleConverter {
    
    static func convertURLToTitle(_ url: String, with info: AtInfo, by textView: SheetTextView) -> NSAttributedString? {
        let editingTextView = textView
        guard let atConvertResult = editingTextView.convertToAtAttrString(url, with: info) else {
            return nil
        }
        let textAttrString = NSMutableAttributedString(attributedString: atConvertResult.0)
        let range = NSRange(location: 0, length: textAttrString.length)
        let currentLocation = editingTextView.selectedRange.location - url.utf16.count
        let colorRange = NSRange(location: currentLocation, length: info.at.utf16.count + 2) //icon以及@渲染 空格 length+2
        guard
            colorRange.location >= 0,
            colorRange.location < textAttrString.length,
            colorRange.location + colorRange.length <= textAttrString.length
        else {
            DocsLogger.info("at array out of range - \(textAttrString) -\(colorRange)")
            return nil
        }
        let font = UIFont.systemFont(ofSize: 14)
        textAttrString.addAttribute(.font, value: font, range: range)
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        textAttrString.addAttribute(.baselineOffset, value: baselineOffset, range: colorRange)
        textAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: colorRange)
        textAttrString.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: colorRange)
        editingTextView.attributedText = textAttrString
        editingTextView.selectedRange = NSRange(location: atConvertResult.1, length: 0)
        return editingTextView.attributedText
    }
}
