//
//  ProfileStatusView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/15.
//

import UIKit
import Foundation
import RichLabel
import UniverseDesignIcon
import UniverseDesignToast
import LarkFeatureGating
import LarkEMM

public final class MLabel: LKLabel {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }

    public override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return super.sizeThatFits(size)
    }
}

public final class ProfileStatusView: UIView {

    public weak var delegate: LKLabelDelegate? {
        didSet {
            self.statusLabel.delegate = delegate
        }
    }

    var isSupportUrlPreview: Bool = true

    var pushGesture: UITapGestureRecognizer?

    var pushCallback: (() -> Void)?

    var attributedText: NSAttributedString?
    var originText: String?
    let acronymString = "\u{2026}"

    lazy var statusLabel: MLabel = {
        let label = MLabel()
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 12)]
        label.font = Cons.textFont
        label.textColor = Cons.textColor
        if isSupportUrlPreview {
            label.numberOfLines = 5
            label.lineBreakMode = .byTruncatingTail
        } else {
            label.numberOfLines = 0
        }
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.outOfRangeText = NSAttributedString(string: acronymString, attributes: attributes)
        label.textAlignment = .left
        label.isUserInteractionEnabled = true
        label.lineSpacing = 2
        label.autoDetectLinks = true
        label.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.ud.N200
        ]
        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        label.linkAttributes = [
            .foregroundColor: Cons.linkColor
        ]
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let pushGesture = UITapGestureRecognizer(target: self, action: #selector(push))
        self.addGestureRecognizer(pushGesture)

        self.pushGesture = pushGesture
        pushGesture.cancelsTouchesInView = false
        pushGesture.delaysTouchesEnded = false
        pushGesture.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        statusLabel.preferredMaxLayoutWidth = self.bounds.width
        statusLabel.invalidateIntrinsicContentSize()
    }

    public func setStatus(originText: String,
                          attributedText: NSMutableAttributedString,
                          urlRangeMap: [NSRange: URL] = [:],
                          textUrlRangeMap: [NSRange: String] = [:],
                          pushCallback: (() -> Void)? = nil) {
        self.originText = originText
        self.pushCallback = pushCallback
        let font = Cons.textFont
        var attributedDescription = NSMutableAttributedString(
            string: originText,
            attributes: [
                .font: font,
                .foregroundColor: Cons.textColor
            ]
        )

        if pushCallback != nil {
            // 自己的状态，可以编辑
            attributedDescription = NSMutableAttributedString(
                string: originText,
                attributes: [
                    .font: font,
                    .foregroundColor: Cons.editableTextColor
                ]
            )
            attributedText.append(pushAttachment())
            if let outRangeAttribute = statusLabel.outOfRangeText, outRangeAttribute.length == NSAttributedString(string: acronymString).length {
                var outOfRangeAttributed = NSMutableAttributedString(attributedString: outRangeAttribute)
                outOfRangeAttributed.append(pushAttachment())
                statusLabel.outOfRangeText = outOfRangeAttributed
            }
        }
        statusLabel.rangeLinkMapper = urlRangeMap
        textUrlRangeMap.forEach { range, url in
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { [weak self] (_, _) in
                guard let self = self else { return }
                do {
                    let url = try URL.forceCreateURL(string: url)
                    self.delegate?.attributedLabel(self.statusLabel, didSelectLink: url)
                } catch {}
            }
            self.statusLabel.addLKTextLink(link: textLink)
        }

        self.attributedText = attributedText
        statusLabel.attributedText = attributedText
    }

    private func pushAttachment() -> NSAttributedString {
        let pushIcon = UIImageView(frame: CGRect(origin: .zero, size: Cons.pushIconSize))
        pushIcon.image = UDIcon.rightOutlined.ud.withTintColor(Cons.pushIconColor)
        pushIcon.frame.size = Cons.pushIconSize
        let attachment = LKAttachment(view: pushIcon)
        attachment.size = pushIcon.bounds.size
        attachment.margin = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        attachment.fontAscent = Cons.textFont.ascender
        attachment.fontDescent = Cons.textFont.descender
        attachment.verticalAlignment = .middle
        let attachmentStr = NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [
                LKAttachmentAttributeName: attachment
            ]
        )
        return attachmentStr
    }

    @objc
    func push() {
        self.pushCallback?()
    }
}

extension ProfileStatusView: UIGestureRecognizerDelegate {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if statusLabel.hitTest(gestureRecognizer.location(in: statusLabel), with: nil) != nil {
            return false
        }
        return true
    }
}

extension ProfileStatusView {

    enum Cons {
        static var linkColor: UIColor { UIColor.ud.textLinkNormal }
        static var textColor: UIColor { UIColor.ud.textCaption }
        static var editableTextColor: UIColor { UIColor.ud.textTitle }
        static var emptyTextColor: UIColor { UIColor.ud.textPlaceholder }
        static var pushIconColor: UIColor { UIColor.ud.iconN2 }
        static var textFont: UIFont { .systemFont(ofSize: 14) }
        static var textLineHeight: CGFloat { 20 }
        static var pushIconSize: CGSize { .square(14) }
    }
}
