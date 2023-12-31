//
//  TextView.swift
//  LarkCore
//
//  Created by chengzhipeng-bytedance on 2018/6/14.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import RichLabel

public final class TextView: UIView {

    public var numberOfLines: Int = 0
    public let fontSize: CGFloat
    public var contentLabel: LKSelectionLabel!

    public lazy var outOfRangeAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.ud.N900,
        .font: UIFont.systemFont(ofSize: fontSize)
    ]

    public init(numberOfLines: Int = 0, fontSize: CGFloat = 16, delegate: LKLabelDelegate) {
        self.fontSize = fontSize
        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear
        self.numberOfLines = numberOfLines

        // label
        var contentLabel = LKSelectionLabel()
        if let selectionLabel = (contentLabel as LKLabel).lu.setProps(fontSize: fontSize, numberOfLine: numberOfLines, textColor: UIColor.ud.N900) as? LKSelectionLabel {
            contentLabel = selectionLabel
        }
        contentLabel.font = UIFont.systemFont(ofSize: fontSize)
        contentLabel.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        contentLabel.debugOptions = [.logger(LKLabelLoggerImpl())]
        #if DEBUG
        contentLabel.seletionDebugOptions = LKSelectionLabelDebugOptions([.printTouchEvent])
        #endif
        contentLabel.lineSpacing = 1
        contentLabel.delegate = delegate
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.contentLabel = contentLabel
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setSelectionDelegate(_ delegate: LKSelectionLabelDelegate) {
        contentLabel.selectionDelegate = delegate
    }

    /// 设置 contentLabel 属性和内容.
    ///
    /// - Parameters:
    ///   - contentMaxWidth: 内容最大宽度,必须设置.
    ///   - attributedText: attributedText
    ///   - rangeLinkMap: 文本中 url 对应的 range 字典, 用于渲染 url 链接, 通过 delegate 的方式处理点击.
    ///   - tapableRangeList: 文本中需要点击区域的, 通过 delegate 的方式处理点击.
    ///   - invaildLinkMap: 文本中普通 string 渲染成 url 样式, 通过 invaildLinkBlock 处理点击.
    ///   - invaildLinkBlock: 处理普通 string 的点击事件.
    public func setContentLabel(
        contentMaxWidth: CGFloat,
        attributedText: NSAttributedString,
        rangeLinkMap: [NSRange: URL] = [:],
        tapableRangeList: [NSRange] = [],
        textLinkMap: [NSRange: String] = [:],
        linkAttributes: [NSAttributedString.Key: Any]? = nil,
        textLinkBlock: ((String) -> Void)? = nil) {

        self.contentLabel.preferredMaxLayoutWidth = contentMaxWidth
        self.contentLabel.numberOfLines = numberOfLines
        self.contentLabel.rangeLinkMapper = rangeLinkMap
        self.contentLabel.tapableRangeList = tapableRangeList
        if let linkAttributes = linkAttributes {
            self.contentLabel.linkAttributes = linkAttributes
        }
        self.contentLabel.removeLKTextLink()
        textLinkMap.forEach { [weak self] (range, url) in
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { (_, _) in
                textLinkBlock?(url)
            }
            self?.contentLabel.addLKTextLink(link: textLink)
        }

        let attribute = outOfRangeAttributes
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attribute)
        self.contentLabel.outOfRangeText = outOfRangeText
        let attrtext = attributedText.mutableCopy() as? NSMutableAttributedString
        attrtext?.replaceFont(with: UIFont.ud.body0)
        self.contentLabel.attributedText = attrtext ?? attributedText
    }
}

extension NSMutableAttributedString {
    func replaceFont(with font: UIFont) {
        beginEditing()
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { (value, range, _) in
            if let f = value as? UIFont,
               let ufd = f.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits) {
                let newFont = UIFont(descriptor: ufd, size: f.pointSize)
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
            }
        }
        endEditing()
    }
}
