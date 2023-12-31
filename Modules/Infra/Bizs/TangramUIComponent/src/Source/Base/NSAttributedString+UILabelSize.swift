//
//  NSAttributedString+UILabelSize.swift
//  AsyncComponent
//
//  Created by Meng on 2019/4/15.
//

import Foundation
import UIKit

/// `NSStringDrawingContext`布局计算相关非公开属性
/// 详见 [UILabel布局计算调研](https://bytedance.feishu.cn/space/doc/doccnBfdmHJwBJOgzrWPcu)
extension NSAttributedString {

    /// 可用于`UILabelComponent` textSize计算的方法
    ///
    /// 逆向系统`UILabel`的`textRect(forBounds:limitedToNumberOfLines:)`实现后的仿照实现，适用于异步布局，含有降级策略
    /// 详见 [UILabel布局计算调研](https://bytedance.feishu.cn/space/doc/doccnBfdmHJwBJOgzrWPcu)
    ///
    /// - Parameters:
    ///   - limitedSize: 约束size
    ///   - limitedToNumberOfLines: 限定行数
    /// - Returns: 计算结果size
    func componentTextSize(for limitedSize: CGSize, limitedToNumberOfLines: Int) -> CGSize {
        guard !string.isEmpty else { return .zero }

        var size: CGSize

        let context = NSStringDrawingContext()
        /// 下面几个属性不在Private Frameworks中，在libswiftUIKit中，因此不去掉
        if context.responds(to: Selector("setMaximumNumberOfLines:")) &&
            context.responds(to: Selector("setWrapsForTruncationMode:")) {
            context.setValue(limitedToNumberOfLines, forKey: "maximumNumberOfLines")
            context.setValue(1, forKey: "wrapsForTruncationMode")
            size = boundingRect(with: limitedSize, options: .usesLineFragmentOrigin, context: context).size
        } else { /* 系统属性失效，降级策略 */
            assertionFailure("UILabelComponent size计算，系统属性失效，降级策略")
            size = _suggestSize(forSize: limitedSize, limitedToNumberOfLines: limitedToNumberOfLines)
        }

        if limitedSize.width < size.width {
            size.width = limitedSize.width
        }
        if limitedSize.height < size.height {
            size.height = limitedSize.height
        }
        return CGSize(width: _ceilToViewScale(size.width), height: _ceilToViewScale(size.height))
    }

    /// 模仿系统策略，像素取整
    @inline(__always)
    private func _ceilToViewScale(_ measure: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return ceil(measure * scale) / scale
    }

}

extension NSAttributedString {

    /// Returns the drawing size for the attributed string.
    /// 通过CoreText手动计算布局，上面的降级方案，结果不能保证最精确
    ///
    /// - Parameters:
    ///   - size: The bounding size of the receiver.
    ///   - numberOfLines: The maximum number of lines to use, The value 0 indicates there is no maximum number of
    ///                    lines and that the size should encompass all of the text.
    /// - Returns: The computed drawing size for the attributed string.
    private func _suggestSize(forSize constraints: CGSize, limitedToNumberOfLines numberOfLines: Int = 0) -> CGSize {
        let attributedString = _removingLineBreakMode()
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

        var visibleLinesCount = 0
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: constraints))
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        // swiftlint:disable:next force_cast
        let lines = CTFrameGetLines(frame) as! [CTLine]

        guard !lines.isEmpty else { return .zero }

        if numberOfLines == 0 {
            visibleLinesCount = lines.count
        } else {
            visibleLinesCount = min(numberOfLines, lines.count)
        }

        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        var totalHeight: CGFloat = 0
        var width: CGFloat = 0
        var lineSpacing: CGFloat = 0

        for index in 0..<visibleLinesCount {
            let line = lines[index]
            width = max(width, CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading)))

            let cfRange = CTLineGetStringRange(line)
            let styles = _paragraphStyles(in: NSRange(location: cfRange.location, length: cfRange.length))
            lineSpacing = styles.reduce(0) { max($0, $1.lineSpacing) }
            let lineHeightMultiple = styles.reduce(1) { max($0, $1.lineHeightMultiple) }

            let lineHeight = (ascent + descent + leading) * lineHeightMultiple
            totalHeight += lineHeight + lineSpacing
        }
        totalHeight -= lineSpacing
        return CGSize(width: width, height: totalHeight)
    }

    /// Returns a new attributed string made by removing lineBreakMode paragraph style from the receiver
    /// a given attributed string.
    private func _removingLineBreakMode() -> NSAttributedString {
        let mutableAttrStr = NSMutableAttributedString(string: string)
        enumerateAttributes(in: NSRange(location: 0, length: length), options: []) { attrs, range, _ in
            var copiedAttrs = attrs
            if let paragraphStyle = copiedAttrs[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                // swiftlint:disable:next force_cast
                let copied = paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                copied.lineBreakMode = .byWordWrapping
                copiedAttrs[NSAttributedString.Key.paragraphStyle] = copied
            }
            mutableAttrStr.addAttributes(copiedAttrs, range: range)
        }
        return mutableAttrStr
    }

    /// Returns all the paragraph styles for characters in a given range
    ///
    /// - Parameter range: Range where to return paragraph styles, This value must lie within
    ///                    the bounds of the receiver.
    /// - Returns: The paragraph styles for the characters in range.
    private func _paragraphStyles(in range: NSRange) -> [NSParagraphStyle] {
        let ending = range.location + range.length
        var effectiveRange = NSRange(location: 0, length: 0)
        var styles = [NSParagraphStyle]()
        var start = range.location

        while start < ending {
            let attrs = attributes(at: start, effectiveRange: &effectiveRange)
            if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
                styles.append(paragraphStyle)
            }
            start = effectiveRange.location + effectiveRange.length
        }
        return styles
    }
}
