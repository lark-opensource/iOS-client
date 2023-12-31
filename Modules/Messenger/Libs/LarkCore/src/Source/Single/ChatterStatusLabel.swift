//
//  ChatterStatusLabel.swift
//  Lark
//
//  Created by lichen on 2018/4/2.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import SnapKit
import RxSwift
import RichLabel
import UniverseDesignColor
import UniverseDesignIcon

public final class ChatterStatusLabelFactory {
    class func label(
        linkBlock: @escaping (URL) -> Void,
        phoneBlock: @escaping (String) -> Void
    ) -> ChatterStatusLabel {
        let label = ChatterStatusLabel()
        label.linkBlock = linkBlock
        label.telBlock = phoneBlock
        return label
    }
}

open class ChatterStatusLabel: UIView {
    public static let iconSize: CGFloat = 14

    public var disposeBag = DisposeBag()

    public var showIfEmpty: Bool = false {
        didSet {
            self.updateUI()
        }
    }

    public var font: UIFont = UIFont.systemFont(ofSize: 12) {
        didSet {
            descriptionView.font = self.font
        }
    }

    public var textColor: UIColor = UIColor.ud.textPlaceholder {
        didSet {
            descriptionView.textColor = textColor
        }
    }

    public var iconColor: UIColor = UIColor.ud.iconN3 {
        didSet {
            descriptionIcon.tintColor = iconColor
        }
    }

    public override var backgroundColor: UIColor? {
        didSet {
            self.descriptionIcon.backgroundColor = backgroundColor
            self.descriptionView.backgroundColor = backgroundColor
        }
    }

    public var preferredMaxLayoutWidth: CGFloat {
        return self.descriptionView.preferredMaxLayoutWidth
    }

    public private(set) var autoDetectLinks: Bool = false {
        didSet {
            self.descriptionView.autoDetectLinks = autoDetectLinks
        }
    }
    public private(set) var showAll: Bool = false

    public private(set) var showIcon: Bool = true {
        didSet {
            descriptionIcon.isHidden = !showIcon
        }
    }

    public private(set) var descriptionIcon: UIImageView = .init(image: nil)
    public private(set) var descriptionView: LKLabel = .init()

    public var linkBlock: (URL) -> Void = { _ in }

    public var telBlock: (String) -> Void = { _ in }

    public var tapBlock: () -> Bool = { true }

    public var attributedDescription: NSAttributedString = NSAttributedString(string: "")
    public var descriptionType: Chatter.DescriptionType = .onDefault

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true

        let descriptionIcon = UIImageView()
        descriptionIcon.isUserInteractionEnabled = false
        descriptionIcon.tintColor = iconColor
        self.addSubview(descriptionIcon)
        descriptionIcon.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.height.equalTo(Self.iconSize)
            make.right.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
        self.descriptionIcon = descriptionIcon

        let descriptionView = LKLabel()
        let attributes: [NSAttributedString.Key: Any] = [.font: self.font, .foregroundColor: textColor]
        descriptionView.backgroundColor = UIColor.clear
        descriptionView.textColor = textColor
        descriptionView.textAlignment = .left
        descriptionView.delegate = self
        descriptionView.font = self.font
        descriptionView.isUserInteractionEnabled = true
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        descriptionView.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        descriptionView.linkAttributes = [
             NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor
        ]
        descriptionView.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.ud.N200
        ]
        descriptionView.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: attributes)
        self.addSubview(descriptionView)

        descriptionView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descriptionView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.descriptionView = descriptionView
    }

    required  public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(
        description: String,
        descriptionType: Chatter.DescriptionType,
        showAll: Bool = false,
        autoDetectLinks: Bool = false,
        preferredMaxLayoutWidth: CGFloat = -1,
        showIcon: Bool = true
    ) {
        self.attributedDescription = NSAttributedString(string: description)
        self.descriptionType = descriptionType
        self.showAll = showAll
        self.autoDetectLinks = autoDetectLinks
        self.descriptionView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        self.showIcon = showIcon
        self.updateUI()
    }

    public func set(
        description: NSAttributedString,
        descriptionType: Chatter.DescriptionType,
        showAll: Bool = false,
        autoDetectLinks: Bool = false,
        preferredMaxLayoutWidth: CGFloat = -1,
        urlRangeMap: [NSRange: URL] = [:],
        textUrlRangeMap: [NSRange: String] = [:],
        showIcon: Bool = true
    ) {
        self.attributedDescription = description
        self.descriptionType = descriptionType
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

    func updateUI() {
        let font = self.font

        isHidden = false

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        // descriptionView本身配置了outOfRangeText，不能再设置byTruncatingTail了，
        // byTruncatingTail会使得绘制文本超出时末尾自动添加「...」
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = self.showAll ? .byWordWrapping : .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2

        let attributedText = NSMutableAttributedString(attributedString: self.attributedDescription)
        attributedText.addAttributes(
            [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ],
            range: NSRange(location: 0, length: attributedText.length)
        )
        // descriptionView本身配置了outOfRangeText，不能再设置byTruncatingTail了，
        // byTruncatingTail会使得绘制文本超出时末尾自动添加「...」
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        // 需要分情况替换，单行展示时不替换，多行展示时可替换
        // swiftlint:disable ban_linebreak_byChar
        self.descriptionView.lineBreakMode = self.showAll ? .byWordWrapping : .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        self.descriptionView.numberOfLines = self.showAll ? 0 : 1
        self.descriptionView.attributedText = attributedText
        var descriptionIcon: UIImage?
        if attributedDescription.string.isEmpty {
            if self.showIfEmpty {
                let attributedText = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Profile_EnterYourSignature)
                attributedText.addAttributes(
                    [
                        .font: font,
                        .foregroundColor: textColor,
                        .paragraphStyle: paragraphStyle
                    ],
                    range: NSRange(location: 0, length: attributedText.length)
                )

                self.descriptionView.attributedText = attributedText
                descriptionIcon = UDIcon.editOutlined.withRenderingMode(.alwaysTemplate)
            } else {
                self.descriptionView.attributedText = NSAttributedString()
                descriptionIcon = nil
                isHidden = true
            }
        } else {
            if self.showAll {
                descriptionIcon = LarkUIKit.Resources.default_description_small.withRenderingMode(.alwaysTemplate)
            } else {
                descriptionIcon = Resources.verticalLineImage
            }
        }

        self.descriptionIcon.image = descriptionIcon
        if self.showIcon {
            self.descriptionIcon.snp.remakeConstraints { (make) in
                make.left.equalToSuperview()
                make.size.equalTo(descriptionIcon?.size ?? CGSize(width: 0, height: 0))
                make.right.bottom.lessThanOrEqualToSuperview()
                if self.showAll {
                    make.top.equalToSuperview().offset(2)
                } else {
                    make.centerY.equalToSuperview()
                }
            }
        }

        descriptionView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            if showIcon {
                make.left.equalTo(self.descriptionIcon.snp.right).offset(8)
            } else {
                make.left.equalToSuperview()
            }
            make.right.equalToSuperview().offset(-4)
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapBlock() {
            super.touchesBegan(touches, with: event)
        }
    }

}

extension ChatterStatusLabel: LKLabelDelegate {
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
