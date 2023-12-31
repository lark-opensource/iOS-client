//
//  DetailViewExtension.swift
//  Calendar
//
//  Created by tuwenbo on 2023/6/13.
//

import Foundation
import UIKit

extension UILabel {
    // 设置字体行高，跟 figma 上的一样
    func setFigmaLineHeight(for font: UIFont) {
        if let text = self.text {
            let fontFigmaHeight = font.figmaHeight
            let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = fontFigmaHeight
            paragraphStyle.maximumLineHeight = fontFigmaHeight
            paragraphStyle.lineBreakMode = lineBreakMode
            attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .baselineOffset: baselineOffset,
                    .paragraphStyle: paragraphStyle,
                    .font: font
                ]
            )
        }
     }

    // 设置字体行高，跟 figma 上的一样
    func tryFitFoFigmaLineHeight() {
        if let font = self.font {
            setFigmaLineHeight(for: font)
        }
    }

    func setText(text: String, font: UIFont, lineHeight: CGFloat) {
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        let offset = (lineHeight - font.lineHeight) / 4.0

        let attributedText = NSAttributedString(string: text,
                                                attributes: [.paragraphStyle: style,
                                                             .baselineOffset: offset,
                                                             .font: font])
        self.attributedText = attributedText
    }
}
