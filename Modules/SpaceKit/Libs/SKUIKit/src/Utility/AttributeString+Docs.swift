//
//  File.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/3.
//

import Foundation
import SKFoundation

extension NSAttributedString: DocsExtensionCompatible {}

public extension NSAttributedString {
    /// Calculate the estimated width of a single-line UILabel with the specified attributed text.
    ///
    /// - Returns: The estimated width of the single-line UILabel
    var estimatedSingleLineUILabelWidth: CGFloat {
        let test = UILabel()
        test.attributedText = self
        test.numberOfLines = 1
        test.frame.size = CGSize(width: 400, height: 400)
        test.sizeToFit()
        return test.frame.width
    }

    /// Calculate the estimated height of a multiline UILabel with the specified attributed text bounded by the specific `maxWidth`.
    ///
    /// - Parameters:
    ///   - maxWidth: The maximum width of the UILabel's text
    ///   - ratio: The minimum percentage that the last line of the UILabel should fill. Pass `nil` if you don't need this constraint.
    /// - Returns: The estimated height of the multiline UILabel.
    func estimatedMultilineUILabelSize(maxWidth: CGFloat,
                                       expectLastLineFillPercentageAtLeast ratio: CGFloat?) -> CGSize {
        let test = UILabel()
        test.attributedText = self
        test.numberOfLines = 0
        test.lineBreakMode = .byWordWrapping
        test.frame.size = CGSize(width: maxWidth, height: 1000)
        test.sizeToFit()
        if let ratio = ratio {
            var dx: CGFloat = 0
            var previousWidth = test.lastLineWidth
            while test.lastLineWidth < ratio * maxWidth {
                dx += test.font.pointSize
                test.frame.size = CGSize(width: maxWidth - dx, height: 1000)
                test.sizeToFit()
                if test.lastLineWidth >= previousWidth {
                    previousWidth = test.lastLineWidth
                } else {
                    dx -= test.font.pointSize
                    test.frame.size = CGSize(width: maxWidth - dx, height: 1000)
                    test.sizeToFit()
                    break
                }
            }
        }
        return test.frame.size
    }

//    func estimatedSingleLineUILabelWidth(in font: UIFont!) -> CGFloat {
//        let tmpLabel = UILabel()
//        tmpLabel.attributedText = self
//        tmpLabel.font = font
//        tmpLabel.numberOfLines = 1
//        tmpLabel.frame.size = CGSize(width: 400, height: 400)
//        tmpLabel.sizeToFit()
//        return tmpLabel.frame.width
//    }
}


public extension String {
    /// Calculate the estimated width of a single-line UILabel with the specified text and font.
    ///
    /// - Parameters:
    ///   - font: The text's font. This parameter must not be `nil`.
    /// - Returns: The estimated width of the single-line UILabel
    func estimatedSingleLineUILabelWidth(in font: UIFont!) -> CGFloat {
        let test = UILabel()
        test.text = self
        test.font = font
        test.numberOfLines = 1
        test.frame.size = CGSize(width: 400, height: 400)
        test.sizeToFit()
        return test.frame.width
    }

    /// Calculate the estimated size of a multiline UILabel with the specified text and font bounded by the specific `maxWidth`.
    /// Last line fill percentage will be curated to be more than `percent` if is given.
    ///
    /// - Parameters:
    ///   - font: The text's font. This parameter must not be `nil`.
    ///   - maxWidth: The maximum width of the UILabel's text.
    ///   - ratio: The minimum percentage that the last line of the UILabel should fill. Pass `nil` if you don't need this constraint.
    /// - Returns: The estimated size of the multiline UILabel.
    func estimatedMultilineUILabelSize(in font: UIFont!, maxWidth: CGFloat,
                                       expectLastLineFillPercentageAtLeast ratio: CGFloat?) -> CGSize {
        let test = UILabel()
        test.text = self
        test.font = font
        test.numberOfLines = 0
        test.lineBreakMode = .byWordWrapping
        test.preferredMaxLayoutWidth = maxWidth
        test.frame.size = CGSize(width: maxWidth, height: 1000)
        test.sizeToFit()
        if let ratio = ratio {
            var dx: CGFloat = 0
            var previousWidth = test.lastLineWidth
            while test.lastLineWidth < ratio * maxWidth {
                dx += test.font.pointSize
                test.frame.size = CGSize(width: maxWidth - dx, height: 1000)
                test.sizeToFit()
                if test.lastLineWidth >= previousWidth {
                    previousWidth = test.lastLineWidth
                } else {
                    dx -= test.font.pointSize
                    test.frame.size = CGSize(width: maxWidth - dx, height: 1000)
                    test.sizeToFit()
                    break
                }
            }
        }
        return test.frame.size
    }

    /// Apply the string with specified attributes and bound its width within the max width.
    /// - Parameters:
    ///   - attr: The attributes of the desired attributed string.
    ///   - maxWidth: The maximum width of the attributed string.
    ///   - minPercent: The minimum percentage that the last line of the UILabel should fill. Pass `nil` if you don't need this constraint.
    /// - Returns: The attributed string and its actual size.
    func attrString(withAttributes attr: [NSAttributedString.Key: Any], boundedBy maxWidth: CGFloat,
                    expectLastLineFillPercentageAtLeast minPercent: CGFloat? = nil) -> (NSAttributedString, CGSize) {
        let attributedString = NSAttributedString(string: self, attributes: attr)
        let neededWidthIfInSingleLine = attributedString.estimatedSingleLineUILabelWidth
        var realSize: CGSize = .zero
        if neededWidthIfInSingleLine <= maxWidth {
            let font = attr[.font] as? UIFont
            let fontSize = font?.pointSize ?? UIFont.systemFontSize
            let paraStyle = attr[.paragraphStyle] as? NSParagraphStyle
            let lineSpacing = paraStyle?.lineSpacing ?? 0.0
            realSize = CGSize(width: neededWidthIfInSingleLine, height: fontSize + lineSpacing)
        } else {
            realSize = attributedString.estimatedMultilineUILabelSize(maxWidth: maxWidth,
                                                                      expectLastLineFillPercentageAtLeast: minPercent)
        }
        return (attributedString, realSize)
    }

    func lineCount(width: CGFloat, font: UIFont) -> Int {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = NSString(string: self).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        let lineHeight = font.lineHeight
        let numberOfLines = ceil(boundingBox.height / lineHeight)
        return Int(numberOfLines)
    }

}


public extension NSParagraphStyle {
    var mutableParagraphStyle: NSMutableParagraphStyle {
        let copy = self.mutableCopy() as? NSMutableParagraphStyle
        return copy ?? NSMutableParagraphStyle()
    }
}
