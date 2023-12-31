//
//  ProfileExpandableLabel.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/7.
//

import UIKit
import Foundation
import RichLabel
import LarkLocalizations
import UniverseDesignIcon
import LarkExtensions

typealias ItemTappedCallback = () -> Void

public enum ExpandStatus: Equatable {
    case folded // 禁用折叠/展开
    case expandable(expanding: Bool) // 可折叠/展开：Bool表示当前状态是否展开
    case expanded // 只展开

    // 当前是否展开
    func isExpand() -> Bool {
        return self == .expandable(expanding: true) || self == .expanded || self == .folded
    }

    var isLabelExpanded: Bool {
        switch self {
        case .expandable(let expanding):
            return expanding
        case .expanded:
            return true
        case .folded:
            return false
        }
    }
}

// 点击可展开的Label
final class ProfileExpandableLabel: UIControl {

    var font: UIFont = UIFont.systemFont(ofSize: 16) {
        didSet {
            descLabel.font = font
        }
    }

    var textColor: UIColor = UIColor.ud.textPlaceholder {
        didSet {
            descLabel.textColor = textColor
        }
    }

    var textAlignment: NSTextAlignment {
        get { descLabel.textAlignment }
        set { descLabel.textAlignment = newValue }
    }

    override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor == nil {
                self.descLabel.backgroundColor = .clear
            } else {
                self.descLabel.backgroundColor = backgroundColor
            }
        }
    }

    var preferredMaxLayoutWidth: CGFloat {
        return self.descLabel.preferredMaxLayoutWidth
    }

    private var canShowAll: Bool {
        return self.content.lu.width(font: font) <= preferredMaxLayoutWidth
    }

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Cons.iconSpacing
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        return stack
    }()

    private(set) lazy var descLabel: LKLabel = {
        let label = LKLabel()
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 12)]
        label.font = font
        label.textColor = textColor
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.autoDetectLinks = false
        label.linkAttributes = [
            .foregroundColor: UIColor.ud.textLinkNormal
        ]
        label.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.ud.N200
        ]
        label.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: attributes)
        // swiftlint:disable all
        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        // swiftlint:enable all
        label.delegate = self
        return label
    }()

    private lazy var expandIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.downOutlined
            .ud.withTintColor(UIColor.ud.iconN2)
        return imageView
    }()

    private lazy var foldIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.upOutlined
            .ud.withTintColor(UIColor.ud.iconN2)
        imageView.frame = CGRect(origin: .zero, size: Cons.iconSize)
        return imageView
    }()

    private var content: String = ""
    var attributedDescription: NSAttributedString = NSAttributedString(string: "")

    private var tappedCallback: ItemTappedCallback?

    private var expandStatus: ExpandStatus = .folded

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        expandIcon.isHidden = true
        addSubview(stackView)
        stackView.addArrangedSubview(descLabel)
        stackView.addArrangedSubview(expandIcon)
        stackView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.lessThanOrEqualToSuperview()
        }
        expandIcon.snp.makeConstraints { make in
            make.size.equalTo(Cons.iconSize)
        }
        self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(
        expandStatus: ExpandStatus,
        content: String,
        preferredMaxLayoutWidth: CGFloat = .infinity,
        tappedCallback: ItemTappedCallback? = nil
    ) {
        self.expandStatus = expandStatus
        self.content = content
        self.tappedCallback = tappedCallback
        self.attributedDescription = NSAttributedString(string: content)
        let notExpandPreferredMaxLayoutWidth = !expandStatus.isExpand() ? (preferredMaxLayoutWidth - Cons.iconSize.width - Cons.iconSpacing) : (preferredMaxLayoutWidth - 4)
        let isExpand = content.lu.width(font: font) > notExpandPreferredMaxLayoutWidth && expandStatus.isExpand()
        self.descLabel.preferredMaxLayoutWidth = isExpand
            ? preferredMaxLayoutWidth - 4
            : min(notExpandPreferredMaxLayoutWidth, content.lu.width(font: font))
        if !isExpand {
            stackView.snp.remakeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.width.equalTo(descLabel.preferredMaxLayoutWidth)
            }
            self.layoutIfNeeded()
        }
        self.updateUI()
    }

    private func updateUI() {
        let font = self.font

        switch expandStatus {
        case .folded:
            self.expandIcon.isHidden = true
        case .expandable(let expanding):
            if canShowAll {
                self.expandIcon.isHidden = true
            } else if expanding {
                self.expandIcon.isHidden = true
                let attri = NSMutableAttributedString(string: self.content)
                let attachment = LKAttachment(view: foldIcon)
                attachment.fontDescent = self.descLabel.font.descender
                attachment.fontAscent = self.descLabel.font.ascender
                attachment.verticalAlignment = .middle
                let attachmentStr = NSAttributedString(
                    string: LKLabelAttachmentPlaceHolderStr,
                    attributes: [LKAttachmentAttributeName: attachment])
                attri.append(NSAttributedString(string: " "))
                attri.append(attachmentStr)
                self.attributedDescription = attri
            } else {
                self.expandIcon.isHidden = false
            }
        case .expanded:
            self.expandIcon.isHidden = true
            self.attributedDescription = NSAttributedString(string: self.content)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = isExpand() ? .byWordWrapping : .byTruncatingTail
        let attributedText = NSMutableAttributedString(attributedString: self.attributedDescription)
        attributedText.addAttributes(
            [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ],
            range: NSRange(location: 0, length: attributedText.length)
        )
        self.descLabel.lineBreakMode = isExpand() ? .byWordWrapping : .byTruncatingTail
        self.descLabel.numberOfLines = isExpand() ? 0 : 1
        self.descLabel.attributedText = attributedText
    }

    @objc
    func tapped() {
        tappedCallback?()
    }

    private func isExpand() -> Bool {
        return (expandStatus.isExpand() && !canShowAll) || canShowAll
    }
}

extension ProfileExpandableLabel: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {}

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {}

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return false
    }

    func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {}
    func tapShowMore(_ label: LKLabel) {}
    func showFirstAtRect(_ rect: CGRect) {}
}

extension ProfileExpandableLabel {

    enum Cons {
        static var iconSize: CGSize { .square(13) }
        static var iconSpacing: CGFloat { 5 }
    }
}
