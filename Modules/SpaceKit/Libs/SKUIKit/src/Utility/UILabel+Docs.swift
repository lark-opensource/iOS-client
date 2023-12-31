//
//  UILabel+Docs.swift
//  Common
//
//  Created by Da Lei on 2018/5/10.
//

import Foundation
import SKFoundation

//public extension DocsExtension where BaseType: UILabel {
//    func maxLines() -> Int {
//        let maxSize = CGSize(width: base.frame.size.width, height: CGFloat(Float.infinity))
//        let charSize = base.font.lineHeight
//        let text = (base.text ?? "") as NSString
//        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: base.font as Any], context: nil)
//        let lines = Int(textSize.height / charSize)
//        return lines
//    }
//}

extension UILabel {
    public var lines: [String]? {
        guard let text = text, let font = font else { return nil }

        let attStr = NSMutableAttributedString(string: text)
        attStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: attStr.length))
        let frameSetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.width, height: .greatestFiniteMagnitude))
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attStr.length), path.cgPath, nil)

        guard let lines = CTFrameGetLines(frame) as? [CTLine] else { return nil }
        return lines.map { line in
            let lineRange = CTLineGetStringRange(line)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            return (text as NSString).substring(with: range)
        }
    }

    public var lastLineWidth: CGFloat {
        if let lastLine = self.lines?.last {
            return lastLine.estimatedSingleLineUILabelWidth(in: self.font)
        } else {
            return 0
        }
    }

    //fg开关去掉后，用下面calculateLinesAndlastLineInfo方法
    public func linesAndlastLineWidth(labelWidth: CGFloat) -> (numeOfLines: Int, width: CGFloat) {
        guard let attText = attributedText else { return (0, 0) }
        let message = NSMutableAttributedString(attributedString: attText)
        guard message.length > 0 else {
            return (0, 0)
        }
        let labelSize = CGSize(width: labelWidth, height: .infinity)
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

//        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
//        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
//                                                                      effectiveRange: nil)

        var lastLineFragmentRect: CGRect = .zero
        var range: NSRange = NSRange(location: 0, length: 0)
        layoutManager.glyphRange(forCharacterRange: NSRange(location: 0, length: message.length - 1), actualCharacterRange: &range)
        var numOfLines: Int = 0
        layoutManager.enumerateLineFragments(forGlyphRange: range) { (_, userRect, _, _, _) in
            numOfLines += 1
            lastLineFragmentRect = userRect
            //DocsLogger.debug(" userRect = \(userRect)")
        }
        return (numOfLines, lastLineFragmentRect.size.width)
    }

    
    ///  计算label行数，和最后一行的信息
    /// - Parameters:
    ///   - labelWidth: label的宽度
    ///   - lineSpace: 行间距
    /// - Returns:numeOfLines：行数，lastLineWidth：最后一行宽度，allLineHeight：整体文本高度（行高+行间距），lastLineHeight：最后一行高度
    public func calculateLinesAndlastLineInfo(labelWidth: CGFloat,
                                               lineSpace: CGFloat,
                                           lineBreakMode: NSLineBreakMode?)
                                         -> (numeOfLines: Int, lastLineWidth: CGFloat, allLineHeight: CGFloat, lastLineHeight: CGFloat) {
        guard let attText = attributedText else { return (0, 0, 0, 0) }
        let message = NSMutableAttributedString(attributedString: attText)
        guard message.length > 0 else {
            return (0, 0, 0, 0)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        //这里 1.5385是根据 UIlabel 和 UITextView，虽然attributedString设置了一样的lineSpacing，但算出来还是不一样，算出来大概的差值
        //暂时这样处理，后续label显示改成用textView显示
        paragraphStyle.lineSpacing = lineSpace / 1.5385
        // 新版loading 设置字符串换行模式
        if let lineBreakMode = lineBreakMode {
            paragraphStyle.lineBreakMode = lineBreakMode
        }
        message.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: message.length))
                                             
        
        let labelSize = CGSize(width: labelWidth, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: message)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = .byWordWrapping

        var lastLineFragmentRect: CGRect = .zero
        var range: NSRange = NSRange(location: 0, length: 0)
        
        layoutManager.glyphRange(forCharacterRange: NSRange(location: 0, length: message.length), actualCharacterRange: &range)
        var numOfLines: Int = 0
        var allLineHeight: CGFloat = 0
        layoutManager.enumerateLineFragments(forGlyphRange: range) { (_, userRect, _, _, _) in
            
            //这里有个坑：当对应的一行有@ 人的时候，self.font.lineHeight是0，
            if self.font.lineHeight >= userRect.size.height {
                //当 self.font.lineHeight不为0的时候，则代表没有没有@ 人
                // 而加了行间距的话，则userRect.size.height取出来是不准的，所以只能自己计算 lineHeight + lineSpace算整体文本高度
                allLineHeight += self.font.lineHeight
                if numOfLines != 0 { //第一行不用加行间距，例如一共三行，就只要加两次行间距
                    allLineHeight += lineSpace
                }
            } else {
                //有@ 人的时候，直接取userRect.size.height就对的
                allLineHeight += userRect.size.height
            }
            numOfLines += 1
            lastLineFragmentRect = userRect
        }
        //最后一行的高度取max(self.font.lineHeight, lastLineFragmentRect.size.height)，原因同上面计算整体高度的说明
        return (numOfLines, lastLineFragmentRect.size.width, allLineHeight, max(self.font.lineHeight, lastLineFragmentRect.size.height))
    }
   
}
