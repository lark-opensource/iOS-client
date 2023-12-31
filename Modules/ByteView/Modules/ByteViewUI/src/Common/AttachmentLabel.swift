//
//  AttachmentLabel.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2022/11/11.
//

import Foundation
import RichLabel

open class AttachmentLabel: LKLabel {

    enum Element {
        case attributedString(NSAttributedString)
        case mutableAttributedString(NSMutableAttributedString)
        case attachment(LKAttachment)
    }

    public var contentFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    public var contentParagraphStyle = NSParagraphStyle()
    public var shouldSetOutRangeString: Bool = true

    private var elements: [Element] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func addAttributedString(_ attributedString: NSAttributedString) {
        elements.append(.attributedString(attributedString))
    }

    public func removeAttributedString(_ attributedString: NSAttributedString) {
        elements.removeAll { element in
            if case .attributedString(let str) = element {
                return str === attributedString
            } else {
                return false
            }
        }
    }

    public func addAttributedString(_ attributedString: NSMutableAttributedString) {
        elements.append(.mutableAttributedString(attributedString))
    }

    public func removeAttributedString(_ attributedString: NSMutableAttributedString) {
        elements.removeAll { element in
            if case .mutableAttributedString(let str) = element {
                return str === attributedString
            } else {
                return false
            }
        }
    }

    public func addArrangedSubview(_ view: UIView, configer: ((LKAttachment) -> Void)? = nil) {
        let attachment = LKAttachment(view: view)
        attachment.fontAscent = contentFont.ascender
        attachment.fontDescent = contentFont.descender
        configer?(attachment)
        elements.append(.attachment(attachment))
    }

    public func removeArrangedSubview(_ view: UIView) {
        elements.removeAll { element in
            if case .attachment(let attachment) = element {
                return attachment.view === view
            } else {
                return false
            }
        }
    }

    public func updateArrangedSubview(_ view: UIView, configer: ((LKAttachment) -> Void)? = nil) {
        guard case .attachment(let attachment) = elements.first(where: {
            if case .attachment(let attachment) = $0 {
                return attachment.view === view
            } else {
                return false
            }
        }) else { return }
        configer?(attachment)
    }

    public func reload() {
        let attributedString = NSMutableAttributedString()
        let outOfRangeString = NSMutableAttributedString()

        for element in elements {
            switch element {
            case .attributedString(let str):
                attributedString.append(str)
            case .mutableAttributedString(let str):
                attributedString.append(str)
            case .attachment(let attachment):
                if attachment.view.isHidden { continue }
                let attachmentString = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                                          attributes: [LKAttachmentAttributeName: attachment, .paragraphStyle: contentParagraphStyle])
                attributedString.append(attachmentString)
                outOfRangeString.append(attachmentString)
            }
        }
        self.attributedText = attributedString
        if shouldSetOutRangeString {
            outOfRangeString.insert(.init(string: "\u{2026}", attributes: attributedString.attributes(at: 0, effectiveRange: nil)), at: 0)
            self.outOfRangeText = outOfRangeString
        }
    }

    public func reset() {
        elements.removeAll()
        attributedText = nil
        outOfRangeText = nil
    }
}
