//
//  LarkPrivacyOverseaAlertView.swift
//  LarkPrivacyAlert
//
//  Created by panbinghua on 2022/2/22.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import LarkExtensions
import LKCommonsLogging
import RichLabel
import UniverseDesignColor

final class PrivacyAlertView: UIView {

    private let viewSpcaing: CGFloat = 36.0
    private let labelSpcaing: CGFloat = 20.0
    private let buttonHeight: CGFloat = 48.0

    private static let logger = Logger.log(PrivacyAlertView.self, category: "PrivacyAlert")

    private lazy var servicePrivacyPolicyLabel: LKLabel = {
        let lbl = LKLabel()
        lbl.backgroundColor = UIColor.ud.bgFloat
        lbl.preferredMaxLayoutWidth = contentWidth - labelSpcaing * 2
        lbl.numberOfLines = 0
        lbl.activeLinkAttributes = [LKBackgroundColorAttributeName: UIColor.ud.N200]
        return lbl
    }()
    private lazy var  agreeButton: UIButton = {
        let btn = UIButton()
        btn.accessibilityIdentifier = "PrivacyAlertView-confirmButton"
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.isEnabled = true
        return btn
    }()
    private lazy var disagreeButton: UIButton = {
        let btn = UIButton()
        btn.accessibilityIdentifier = "PrivacyAlertView-disagreeButton"
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.isEnabled = true
        return btn
    }()

    // MARK: - 属性初始化
    private var contentWidth: CGFloat = .zero

    var rightHandler: (() -> Void)?
    var leftHandler: (() -> Void)?
    var openLinkHandler: ((URL) -> Void)?

    // MARK: - 布局、内容初始化
    func setup(availableWidth: CGFloat,
               contentText: String, privacyText: String, termText: String,
               privacyURL: String, termURL: String,
               acceptText: String, declineText: String) {
        contentWidth = calcContentWidth(availableWidth)
        agreeButton.setTitle(acceptText, for: .normal)
        disagreeButton.setTitle(declineText, for: .normal)
        servicePrivacyPolicyLabel.delegate = self
        let (attributedStr, textLinks) = getAttributedStringAndLink(
            contentText: contentText, privacyText: privacyText, termText: termText,
            privacyURL: privacyURL, termURL: termURL)
        for textLink in textLinks {
            servicePrivacyPolicyLabel.addLKTextLink(link: textLink)
        }
        servicePrivacyPolicyLabel.attributedText = attributedStr
        setupViews()
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 8
        layer.masksToBounds = true
        self.snp.makeConstraints {
            $0.width.equalTo(contentWidth)
        }
        addSubview(servicePrivacyPolicyLabel)
        servicePrivacyPolicyLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(24)
            maker.leading.equalToSuperview().offset(labelSpcaing)
            maker.trailing.equalToSuperview().offset(-labelSpcaing)
        }

        let horizontalLine = UIView()
        horizontalLine.backgroundColor = UIColor.ud.N300
        addSubview(horizontalLine)
        horizontalLine.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(servicePrivacyPolicyLabel.snp.bottom).offset(16)
            $0.height.equalTo(1)
        }
        let verticalLine = UIView()
        verticalLine.backgroundColor = UIColor.ud.N300
        addSubview(verticalLine)
        verticalLine.snp.makeConstraints {
            $0.top.equalTo(horizontalLine.snp.bottom)
            $0.width.equalTo(1)
            $0.height.equalTo(buttonHeight)
            $0.centerX.equalTo(horizontalLine)
            $0.bottom.equalToSuperview()
        }

        addSubview(agreeButton)
        agreeButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(horizontalLine.snp.bottom)
            maker.leading.equalTo(verticalLine.snp.trailing)
            maker.trailing.equalTo(horizontalLine)
            maker.height.equalTo(verticalLine)
        }

        addSubview(disagreeButton)
        disagreeButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(agreeButton)
            maker.leading.equalTo(horizontalLine)
            maker.height.equalTo(verticalLine)
            maker.trailing.equalTo(verticalLine.snp.leading)
        }
    }

    // MARK: - 视图变化
    private func calcContentWidth(_ availableWidth: CGFloat) -> CGFloat {
        return min(360, availableWidth - viewSpcaing * 2) // alertView距离左右各36
    }

    func onViewTransition(_ availableWidth: CGFloat) {
        contentWidth = calcContentWidth(availableWidth)
        self.snp.updateConstraints { $0.width.equalTo(contentWidth) }
        servicePrivacyPolicyLabel.preferredMaxLayoutWidth = contentWidth - labelSpcaing * 2
        servicePrivacyPolicyLabel.invalidateIntrinsicContentSize()
    }

    // MARK: - misc
    private func getAttributedStringAndLink(contentText: String, privacyText: String, termText: String,
                                            privacyURL: String, termURL: String) ->
                                    (NSAttributedString, [LKTextLink]) {
        let font: UIFont = UIFont.systemFont(ofSize: 16)
        let attributedString: NSMutableAttributedString = {
            let para = NSMutableParagraphStyle()
            para.alignment = .left
            let textAttributed: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.ud.textTitle,
                .paragraphStyle: para
            ]
            let attributedString = NSMutableAttributedString(string: contentText, attributes: textAttributed)
            return attributedString
        }()
        let textLinks: [LKTextLink] = [(privacyURL, privacyText), (termURL, termText)].compactMap { urlStr, text in
            guard let url = URL(string: urlStr) else {
                Self.logger.error("textLinkFailed: generate \(urlStr) failed")
                return nil
            }
            guard let range = contentText.range(of: text, options: NSString.CompareOptions.backwards) else {
                Self.logger.error("textLinkFailed: could not find proper range. all: \(contentText) sub: \(text)")
                return nil
            }
            var textLink = LKTextLink(
                range: contentText.lf.rangeToNSRange(from: range),
                type: .link,
                attributes: [
                    .font: font,
                    .foregroundColor: UIColor.ud.B600
                ]
            )
            textLink.url = url
            return textLink
        }
        return (attributedString, textLinks)
    }

    init() {
        super.init(frame: .zero)
        disagreeButton.addTarget(self, action: #selector(noAgreeButtonTapped), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func agreeButtonTapped() {
        self.rightHandler?()
    }

    @objc
    func noAgreeButtonTapped() {
        self.leftHandler?()
    }
}

extension PrivacyAlertView: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.openLinkHandler?(url)
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }
}
