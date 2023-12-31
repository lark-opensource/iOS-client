//
//  AttributeString.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/8/21.
//

import Foundation

extension NSAttributedString {

    /// 自定义初始化字符串
    /// - Parameter str: 字符
    /// - Parameter color: 默认 N600
    /// - Parameter fontSize: 默认 14
    /// - Parameter lineSpace: 默认 2
    /// - Parameter aligment: 默认 left
    static func tip(str: String, color: UIColor = UIColor.ud.N600, font: UIFont = UIFont.systemFont(ofSize: 14), lineSpace: CGFloat = 2, aligment: NSTextAlignment = .left) -> NSMutableAttributedString {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = lineSpace
        para.lineBreakMode = .byWordWrapping
        para.alignment = aligment

        return NSMutableAttributedString(string: str, attributes: [
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: para
            ]
        )
    }

    /// 自定义 Link
    /// - Parameter str: 字符
    /// - Parameter url: URL
    /// - Parameter color: 默认 colorfulBlue
    /// - Parameter font: 默认 system 14.0
    static func link(str: String, url: URL, color: UIColor = UIColor.ud.colorfulBlue, font: UIFont = UIFont.systemFont(ofSize: 14.0)) -> NSMutableAttributedString {
        NSMutableAttributedString(string: str, attributes: [
            .link: url,
            .foregroundColor: color,
            .font: font
            ]
        )
    }
}

extension NSAttributedString {

    /// 构造有超链接的字符串
    /// - Parameters:
    ///   - plainString: 完整的字符串 例如 “这里是A，这里是B” A 和 B 会添加超链接
    ///   - links: 超链接数组 例如 [("A"， url1), ("B", url2)]
    ///   - font: 字体
    ///   - color: 整体颜色
    ///   - linkColor: 链接颜色
    static func makeLinkString(plainString: String,
                               links: [(name: String, url: URL)],
                               boldTexts: [String] = [],
                               alignment: NSTextAlignment = .left,
                               font: UIFont = UIFont.systemFont(ofSize: 14.0),
                               color: UIColor = UIColor.ud.textPlaceholder,
                               linkFont: UIFont = UIFont.systemFont(ofSize: 14.0),
                               linkColor: UIColor = UIColor.ud.primaryContentDefault,
                               boldFont: UIFont = UIFont.boldSystemFont(ofSize: 14.0),
                               boldColor: UIColor = UIColor.ud.textTitle) -> NSAttributedString {

        let attributedString = NSMutableAttributedString.tip(str: plainString, color: color, font: font, aligment: alignment)
        links.forEach { (link) in
            if let range = plainString.range(of: link.name) {
                let linkAttr: [NSAttributedString.Key: Any] = [
                    .font: linkFont,
                    .foregroundColor: linkColor,
                    .link: link.url
                ]
                attributedString.addAttributes(linkAttr, range: NSRange(range, in: plainString))
            }
        }
        boldTexts.forEach { text in
            if let range = plainString.range(of: text) {
                let linkAttr: [NSAttributedString.Key: Any] = [
                    .font: boldFont,
                    .foregroundColor: boldColor,
                ]
                attributedString.addAttributes(linkAttr, range: NSRange(range, in: plainString))
            }
        }
        return attributedString
    }
}
