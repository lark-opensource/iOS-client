//
//  IconActionLabel.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/17.
//

import Foundation
import RichLabel
import UIKit
import ByteViewCommon

public final class IconActionLabel: LKLabel {

    public var heightBase: CGFloat?

    private var action: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if let base = heightBase {
            size.height = CGFloat(Int(size.height / base)) * base
        }
        return size
    }

    public func configLabel(with content: NSAttributedString,
                            textStyle: VCFontConfig,
                            image: UIImage?,
                            size: CGSize,
                            action: ((UIView?) -> Void)?) {
        let mutable = NSMutableAttributedString(attributedString: content)
        var button = VisualButton(type: .custom)
        button.setImage(image, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.action = { [weak button] in
            action?(button)
        }
        let attachment = LKAttachment(view: button)
        attachment.margin = .init(top: 0, left: 8, bottom: 0, right: 0)
        attachment.verticalAlignment = .middle
        attachment.fontAscent = textStyle.font.ascender
        attachment.fontDescent = textStyle.font.descender
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = textStyle.lineHeight - 1
        paragraphStyle.maximumLineHeight = textStyle.lineHeight - 1
        let attachmentStr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [LKAttachmentAttributeName: attachment, .paragraphStyle: paragraphStyle])
        mutable.append(attachmentStr)
        self.attributedText = mutable
    }

    @objc func didTapButton() {
        action?()
    }

    public func configBasicLabel(with content: NSAttributedString,
                                 textStyle: VCFontConfig) {
        let mutable = NSMutableAttributedString(attributedString: content)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = textStyle.lineHeight - 1
        paragraphStyle.maximumLineHeight = textStyle.lineHeight - 1
        let attachmentStr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.ud.textDisabled])
        mutable.append(attachmentStr)
        self.attributedText = mutable
    }
}
