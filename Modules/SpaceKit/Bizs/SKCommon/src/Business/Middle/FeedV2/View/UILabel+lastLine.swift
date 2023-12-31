//
//  UILabel+lastLine.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/15.
//  


import UIKit

extension UILabel {
    
    func lastLineMaxX(width: CGFloat) -> CGFloat {
        guard let message = self.attributedText else {
            return 0
        }
        let labelSize = CGSize(width: width, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: message)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0

        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
                                                                      effectiveRange: nil)
        return lastLineFragmentRect.maxX
    }
}
