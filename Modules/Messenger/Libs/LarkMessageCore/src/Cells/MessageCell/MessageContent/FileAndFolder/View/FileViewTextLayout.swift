//
//  FileViewTextLayout.swift
//  LarkMessageCore
//
//  Created by llb on 2020/7/31.
//

import Foundation
import UIKit
import RichLabel

struct FileViewTextLayout {
    static func contentHeight(text: String, size: CGSize, textAttributes: [NSAttributedString.Key: Any]) -> (LKTextLayoutEngine, CGFloat) {
        let (layoutEngine, contentSize) = FileViewTextLayout.layoutForText(text: text, attributes: textAttributes, size: size)
        // 这里多加一个lineSpace是保证单行或者多行最后一行有个间距 满足UI需求
        return (layoutEngine, contentSize.height + FileView.Cons.nameLabelLineSpace)
    }

    private static func layoutForText(text: String, attributes: [NSAttributedString.Key: Any], size: CGSize) -> (LKTextLayoutEngine, CGSize) {
        let layoutEngine: LKTextLayoutEngine = LKTextLayoutEngineImpl()
        let strs = text.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .both).components(separatedBy: ".")
        layoutEngine.attributedText = NSAttributedString(string: text, attributes: attributes)
        if let last = strs.last {
            layoutEngine.outOfRangeText = NSAttributedString(string: "... .\(last)", attributes: attributes)
        }
        layoutEngine.lineSpacing = FileView.Cons.nameLabelLineSpace
        layoutEngine.numberOfLines = FileView.Cons.nameLabelNumberOfLine
        let contentSize = layoutEngine.layout(size: size)
        return (layoutEngine, contentSize)
    }

    static func textSizeForSystemFont(text: String, fontSize: CGFloat, width: CGFloat) -> CGSize {
        let font = UIFont.systemFont(ofSize: fontSize)
        let size = NSString(string: text).boundingRect(with: CGSize(width: width, height: 40),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil).size
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
