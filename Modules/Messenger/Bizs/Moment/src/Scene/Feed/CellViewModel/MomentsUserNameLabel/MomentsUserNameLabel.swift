//
//  MomentsUserNameLabel.swift
//  Moment
//
//  Created by ByteDance on 2023/1/4.
//

import UIKit
import Foundation
import RichLabel
import UniverseDesignColor

class MomentsUserNameLabel: LKLabel {
    var suggestWidth: CGFloat? {
        if let width = self.attributedText?.componentTextSize(for: .init(width: .max, height: .max), limitedToNumberOfLines: 1).width {
            /// https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
            return width + 2 / UIScreen.main.scale
        }
        return nil
    }

    override var bounds: CGRect {
        didSet {
            preferredMaxLayoutWidth = bounds.width
        }
    }

    var isOfficialUser: Bool = false {
        didSet {
            guard isOfficialUser != oldValue else { return }
            updateContent()
            if isOfficialUser {
                var attrText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
                attrText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
                    LKAttachmentAttributeName: officialUserLabelAttachment
                ]))
                _outOfRangeText = attrText
            } else {
                _outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
            }
        }
    }

    private var _outOfRangeText: NSAttributedString? {
        didSet {
            updateOutOfRange()
        }
    }
    var needOutOfRangeText: Bool = true {
        didSet {
            updateOutOfRange()
        }
    }

    var name: String = "" {
        didSet {
            guard name != oldValue else { return }
            updateContent()
        }
    }
    override var textColor: UIColor! {
        didSet {
            guard textColor != oldValue else { return }
            updateContent()
        }
    }

    override var font: UIFont! {
        didSet {
            guard font != oldValue else { return }
            updateContent()
        }
    }

    private var attributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        return [.font: self.font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
        ]
    }

    private lazy var officialUserLabel = OfficialUserLabel()

    private lazy var officialUserLabelAttachment: LKAsyncAttachment = {
        let attachment = LKAsyncAttachment(viewProvider: { [weak self] () -> UIView in
            return self?.officialUserLabel ?? UIView()
        }, size: OfficialUserLabel.suggestSize)
        attachment.margin = .init(top: 0, left: 6, bottom: 0, right: 0)
        attachment.fontAscent = self.font.ascender
        attachment.fontDescent = self.font.descender
        return attachment
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        autoDetectLinks = false
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        font = UIFont.systemFont(ofSize: 17, weight: .medium)
        _outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        updateOutOfRange()
        preferredMaxLayoutWidth = bounds.width
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateContent() {
        let attrText = NSMutableAttributedString(string: name, attributes: attributes)
        if isOfficialUser {
            var attachmentAttr = self.attributes
            attachmentAttr[LKAttachmentAttributeName] = officialUserLabelAttachment
            attrText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: attachmentAttr))
        }
        self.attributedText = attrText
    }

    private func updateOutOfRange() {
        outOfRangeText = needOutOfRangeText ? _outOfRangeText : nil
    }
}

class OfficialUserLabel: UILabel {
    static var suggestSize: CGSize {
        let textWidth = BundleI18n.Moment.Moments_Official_Label.lu.width(font: .systemFont(ofSize: 12, weight: .medium))
        return .init(width: textWidth + 8, height: 18)
    }
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .ud.udtokenTagBgYellow
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        self.text = BundleI18n.Moment.Moments_Official_Label
        self.textColor = .ud.udtokenTagTextSYellow
        self.textAlignment = .center
        self.font = .systemFont(ofSize: 12, weight: .medium)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
