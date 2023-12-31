//
//  StatusLabel.swift
//  LarkListItem
//
//  Created by 姚启灏 on 2020/7/12.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import RichLabel
import UniverseDesignColor
import UniverseDesignTheme
import LarkFoundation

open class StatusLabel: UIView {

    /// StatusLabel UI Config
    public struct UIConfig {
        public var linkColor: UIColor = UIColor.ud.colorfulBlue
        public var activeLinkBackgroundColor: UIColor = UIColor.ud.N200
        public var textColor: UIColor = UIColor.ud.textPlaceholder
        public var font: UIFont = UIFont.systemFont(ofSize: 12)
        public var backgroundColor: UIColor? = UIColor.clear

        public init(linkColor: UIColor = UIColor.ud.colorfulBlue,
                    activeLinkBackgroundColor: UIColor = UIColor.ud.N200,
                    textColor: UIColor = UIColor.ud.N500,
                    font: UIFont = UIFont.systemFont(ofSize: 12),
                    backgroundColor: UIColor? = UIColor.clear) {
            self.linkColor = linkColor
            self.activeLinkBackgroundColor = activeLinkBackgroundColor
            self.textColor = textColor
            self.font = font
            self.backgroundColor = backgroundColor
        }
    }

    public var textChangedCallback: ((String?, NSAttributedString?) -> Void)?
    public var disposeBag = DisposeBag()

    /// StatusLabel UI Config
    public private(set) var config: UIConfig = UIConfig()

    /// StatusLabel Max Layout Width
    public var preferredMaxLayoutWidth: CGFloat {
        return self.descriptionView.preferredMaxLayoutWidth
    }

    /// Whether to automatically detect links
    public private(set) var autoDetectLinks: Bool = false

    /// Whether it exceeds the preferredMaxLayoutWidth to display the entire content
    public private(set) var showAll: Bool = false

    /// Whether to show descriptionIcon
    public private(set) var showIcon: Bool = true {
        didSet {
            descriptionIconView.isHidden = !showIcon
        }
    }

    /// Check text
    public private(set) var textCheckingDetecotor: NSDataDetector?

    public private(set) var descriptionIcon: UIImage?

    public private(set) var descriptionIconView: UIImageView = .init(image: nil)
    public private(set) var descriptionView: LKLabel = .init()

    /// Click the link block
    public var linkBlock: (URL) -> Void = { _ in }

    /// Click the telephone block
    public var telBlock: (String) -> Void = { _ in }

    /// Tap view block
    public var tapBlock: () -> Bool = { true }

    public var attributedDescription: NSAttributedString = NSAttributedString(string: "")

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true

        let descriptionIconView = UIImageView()
        descriptionIconView.contentMode = .center
        descriptionIconView.isUserInteractionEnabled = false
        self.addSubview(descriptionIconView)
        self.descriptionIconView = descriptionIconView

        let descriptionView = LKLabel()
        descriptionView.backgroundColor = UIColor.clear
        descriptionView.textColor = config.textColor
        descriptionView.textAlignment = .left
        descriptionView.delegate = self
        descriptionView.font = config.font
        descriptionView.isUserInteractionEnabled = true
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.textCheckingDetecotor = textCheckingDetecotor
        descriptionView.linkAttributes = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): config.linkColor.cgColor
        ]
        descriptionView.activeLinkAttributes = [
            LKBackgroundColorAttributeName: config.activeLinkBackgroundColor
        ]
        descriptionView.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: [.font: config.font, .foregroundColor: config.textColor])
        self.addSubview(descriptionView)

        descriptionView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descriptionView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.descriptionView = descriptionView
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set StatusLabel UI Config
    /// - Parameter config: UI Config
    public func setUIConfig(_ config: StatusLabel.UIConfig) {
        self.config = config
        self.updateUI()
    }

    public func set(
        description: NSAttributedString?,
        descriptionIcon: UIImage?,
        showAll: Bool = false,
        autoDetectLinks: Bool = false,
        preferredMaxLayoutWidth: CGFloat = -1,
        textCheckingDetecotor: NSDataDetector? = nil,
        showIcon: Bool = true
    ) {
        self.set(
            description: description,
            descriptionIcon: descriptionIcon,
            urlRangeMap: [:],
            textUrlRangeMap: [:],
            showAll: showAll,
            autoDetectLinks: autoDetectLinks,
            preferredMaxLayoutWidth: preferredMaxLayoutWidth,
            textCheckingDetecotor: textCheckingDetecotor,
            showIcon: showIcon
        )
    }

    /// Set description and other properties
    /// - Parameters:
    ///   - description: Status description
    ///   - descriptionIcon: Status description Icon
    ///   - showAll: Whether it exceeds the preferredMaxLayoutWidth to display the entire content
    ///   - autoDetectLinks: Whether to automatically detect links
    ///   - preferredMaxLayoutWidth: StatusLabel Max Layout Width
    ///   - textCheckingDetecotor: Check text
    ///   - showIcon: Whether to show descriptionIcon
    public func set(
        description: NSAttributedString?,
        descriptionIcon: UIImage?,
        urlRangeMap: [NSRange: URL],
        textUrlRangeMap: [NSRange: String],
        showAll: Bool = false,
        autoDetectLinks: Bool = false,
        preferredMaxLayoutWidth: CGFloat = -1,
        textCheckingDetecotor: NSDataDetector? = nil,
        showIcon: Bool = true
    ) {
        self.attributedDescription = description ?? NSAttributedString(string: "")
        self.descriptionIcon = descriptionIcon
        self.descriptionIconView.image = descriptionIcon
        self.showAll = showAll
        self.autoDetectLinks = autoDetectLinks
        self.descriptionView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        self.descriptionView.rangeLinkMapper = urlRangeMap
        textUrlRangeMap.forEach { range, url in
            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { [weak self] (_, _) in
                do {
                    let url = try URL.forceCreateURL(string: url)
                    self?.linkBlock(url)
                } catch {}
            }
            self.descriptionView.addLKTextLink(link: textLink)
        }
        self.showIcon = showIcon

        self.updateUI()
    }

    /// Update StatusLabel UI
    func updateUI() {
        let font = config.font

        self.isHidden = attributedDescription.string.isEmpty
        self.descriptionIconView.isHidden = self.descriptionIcon == nil

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = self.showAll ? .byWordWrapping : .byTruncatingTail
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2

        let attributedText = NSMutableAttributedString(attributedString: self.attributedDescription)
        attributedText.addAttributes(
            [
                .font: font,
                .foregroundColor: config.textColor,
                .paragraphStyle: paragraphStyle
            ],
            range: NSRange(location: 0, length: attributedText.length)
        )
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        self.descriptionView.lineBreakMode = self.showAll ? .byWordWrapping : .byTruncatingTail
        self.descriptionView.numberOfLines = self.showAll ? 0 : 1
        self.descriptionView.autoDetectLinks = autoDetectLinks
        self.descriptionView.attributedText = attributedText
        self.descriptionView.textColor = config.textColor
        self.descriptionView.font = config.font
        self.descriptionIconView.backgroundColor = config.backgroundColor
        self.descriptionView.backgroundColor = config.backgroundColor
        self.descriptionView.textCheckingDetecotor = textCheckingDetecotor

        descriptionView.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        descriptionView.linkAttributes = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): config.linkColor.cgColor
        ]
        descriptionView.activeLinkAttributes = [
            LKBackgroundColorAttributeName: config.activeLinkBackgroundColor
        ]

        if self.showIcon {
            self.descriptionIconView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview()
                make.size.equalTo(self.descriptionIcon?.size ?? CGSize(width: 0, height: 0))
                make.right.bottom.lessThanOrEqualToSuperview()
                if self.showAll {
                    make.top.equalToSuperview()
                } else {
                    make.centerY.equalToSuperview()
                }
            }
        }
        
        self.textChangedCallback?(attributedText.string, attributedText)

        descriptionView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            if showIcon {
                make.left.equalTo(self.descriptionIconView.snp.right).offset(8)
            } else {
                make.left.equalToSuperview()
            }
            make.right.lessThanOrEqualToSuperview()
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapBlock() {
            super.touchesBegan(touches, with: event)
        }
    }

}

extension StatusLabel: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.linkBlock(url)
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        self.telBlock(phoneNumber)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return false
    }

    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {}
    public func tapShowMore(_ label: LKLabel) {}
    public func showFirstAtRect(_ rect: CGRect) {}
}
