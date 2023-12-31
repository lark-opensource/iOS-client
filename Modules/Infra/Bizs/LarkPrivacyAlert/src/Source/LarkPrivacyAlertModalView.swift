//
//  LarkAlertModalView.swift
//  LarkLaunchGuide
//
//  Created by tangyunfei.tyf on 2020/2/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFoundation
import LarkExtensions
import LKCommonsLogging
import RichLabel
import UniverseDesignColor

// 个人信息保护指引
final class LarkPrivacyGuidelineView: UIView {
    private static let log = Logger.log(
        LarkPrivacyGuidelineView.self,
        category: "PrivacyAlert"
    )
    // MARK: - 控件初始化
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.ud.textTitle
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.setContentCompressionResistancePriority(.required, for: .vertical)
        return lbl
    }()
    private let contentScroll: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return sv
    }()
    private lazy var contentLabel: LKLabel = {
        let lbl = LKLabel()
        lbl.backgroundColor = UIColor.ud.bgFloat
        lbl.numberOfLines = 0
        lbl.preferredMaxLayoutWidth = contentWidth
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textAlignment = .left
        lbl.delegate = self
        return lbl
    }()
    private lazy var serviceTermPrivacyPolicyLabel: LKLabel = {
        let lbl = LKLabel()
        lbl.backgroundColor = UIColor.ud.bgFloat
        lbl.preferredMaxLayoutWidth = contentWidth
        lbl.numberOfLines = 0
        lbl.delegate = self
        return lbl
    }()
    private lazy var  agreeButton: UIButton = { [weak self] in
        let btn = UIButton()
        if let self = self {
            btn.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        }
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        btn.backgroundColor = UIColor.ud.colorfulBlue
        btn.accessibilityIdentifier = "LarkPrivacyGuidelineView-confirmButton"
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.isEnabled = true
        btn.layer.cornerRadius = 4
        return btn
    }()
    private lazy var disagreeButton: UIButton = { [weak self] in
        let btn = UIButton()
        if let self = self {
            btn.addTarget(self, action: #selector(noAgreeButtonTapped), for: .touchUpInside)
        }
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        btn.accessibilityIdentifier = "LarkPrivacyGuidelineView-disagreeButton"
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
    func setup(config: PrivacyAlertConfigProtocol, availableWidth: CGFloat) {
        contentWidth = calcContentWidth(availableWidth)
        // setup alertView serviceTermPrivacyPolicy content
        let (serviceTermPrivacyPolicy, textLinks) = self.attributedStringForMessage(config: config)
        serviceTermPrivacyPolicyLabel.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.ud.N200
        ]
        for textLink in textLinks {
            serviceTermPrivacyPolicyLabel.addLKTextLink(link: textLink)
        }
        serviceTermPrivacyPolicyLabel.attributedText = serviceTermPrivacyPolicy
        // setup contents
        titleLabel.text = config.privacyNoticeTitleText
        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[.foregroundColor] = UIColor.ud.textTitle
        attributes[.font] = UIFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 22 - 16 - (contentLabel.font.lineHeight - contentLabel.font.pointSize)
        attributes[.paragraphStyle] = paragraphStyle
        contentLabel.attributedText = NSAttributedString(string: config.privacyNoticeText, attributes: attributes)
        agreeButton.setTitle(config.privacyAgreeButtonText, for: .normal)
        disagreeButton.setTitle(config.privacyDisagreeButtonText, for: .normal)
        // setup views
        setupViews()
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 6
        layer.masksToBounds = true

        addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(
            ofSize: CGFloat(calcTitleSize(contentWidth, min: 17, max: 26)), weight: .medium
        )
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(calcTitleSize(contentWidth, min: 24, max: 60))
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualTo(20)
            maker.left.lessThanOrEqualTo(90)
            maker.width.equalTo(contentWidth)
        }

        addSubview(contentScroll)
        contentScroll.addSubview(contentLabel)
        contentScroll.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(calcTitleSize(contentWidth, min: 12, max: 16))
            maker.centerX.equalToSuperview()
            // 宽度靠初始化时 UILabel 提供，所以不需要设定宽度
            // 保证 contentScroll 可以被撑开；low 避免约束冲突
            maker.height.equalTo(contentLabel.snp.height).priority(.low)
            maker.height.lessThanOrEqualTo(370)
        }

        contentLabel.snp.makeConstraints { (maker) in
            // 用于contentSize计算
            maker.edges.width.equalToSuperview()
            // 保证 contentLabel 可以被内容完全撑开显示所有内容
            maker.height.greaterThanOrEqualToSuperview()
        }

        addSubview(serviceTermPrivacyPolicyLabel)
        serviceTermPrivacyPolicyLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentScroll.snp.bottom).offset(16)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(contentWidth)
        }

        addSubview(agreeButton)
        agreeButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(serviceTermPrivacyPolicyLabel.snp.bottom).offset(16)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(42)
            maker.width.equalTo(contentWidth)
        }

        addSubview(disagreeButton)
        disagreeButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(agreeButton.snp.bottom).offset(16)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(24)
            // 确定白底的下边界
            maker.bottom.equalToSuperview().inset(16)
        }
    }

    /// 因为 LKLabel 必须要先指定 preferredMaxLayoutWidth ，所以必须先计算 contentWidth ，再向外撑白底
    private func calcContentWidth(_ availableWidth: CGFloat) -> CGFloat {
        return min(360, availableWidth - 56 * 2)
    }

    /// 用于计算标题字号、标题上下间距
    private func calcTitleSize(_ contentWidth: CGFloat, min: Int, max: Int) -> Int {
        let minContentWidth: CGFloat = 263
        let maxContentWidth: CGFloat = 360
        switch contentWidth {
        case ..<minContentWidth:
            return min
        case maxContentWidth...:
            return max
        default:
            let percentage: Double = Double((contentWidth - minContentWidth) / (maxContentWidth - minContentWidth))
            return Int(round(percentage * Double(max - min)) + Double(min))
        }
    }

    // MARK: - 视图变化
    func onViewTransition(_ availableWidth: CGFloat) {
        contentWidth = calcContentWidth(availableWidth)
        contentLabel.preferredMaxLayoutWidth = contentWidth
        serviceTermPrivacyPolicyLabel.preferredMaxLayoutWidth = contentWidth
        // 重新计算标题字号、上下间距
        titleLabel.font = UIFont.systemFont(
            ofSize: CGFloat(calcTitleSize(contentWidth, min: 17, max: 26)), weight: .medium
        )
        titleLabel.snp.updateConstraints {
            $0.width.equalTo(contentWidth)
            $0.top.equalToSuperview().offset(calcTitleSize(contentWidth, min: 24, max: 60))
        }
        contentScroll.snp.updateConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(calcTitleSize(contentWidth, min: 12, max: 16))
        }
        agreeButton.snp.updateConstraints { $0.width.equalTo(contentWidth) }
        serviceTermPrivacyPolicyLabel.snp.updateConstraints { $0.width.equalTo(contentWidth) }
        // 宽度改变，需要手动调方法更新元素高度
        contentLabel.invalidateIntrinsicContentSize()
        serviceTermPrivacyPolicyLabel.invalidateIntrinsicContentSize()
    }

    // MARK: - misc

    private func attributedStringForMessage(config: PrivacyAlertConfigProtocol) ->
                                    (NSAttributedString, [LKTextLink]) {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res = config.serviceTermPrivacyPolicyText(
            serviceTerm: config.serviceTermLinkText,
            privacy: config.privacyLinkText
        )
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let textAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: para
        ]
        let attributedString = NSMutableAttributedString(string: res, attributes: textAttributed)
        var textLinks: [LKTextLink] = []
        let linkAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.B600
        ]
        if let termsURL = URL(string: config.serviceTermURL) {
            if let range = res.range(of: config.serviceTermLinkText, options: NSString.CompareOptions.backwards) {
                var textLink = LKTextLink(
                    range: res.lf.rangeToNSRange(from: range),
                    type: .link,
                    attributes: linkAttributed
                )
                textLink.url = termsURL
                textLinks.append(textLink)
            }
        } else {
            Self.log.error("serviceTermURL is nil")
        }

        if let privacyURL = URL(string: config.privacyURL) {
            if let range = res.range(of: config.privacyLinkText, options: NSString.CompareOptions.backwards) {
                var textLink = LKTextLink(
                    range: res.lf.rangeToNSRange(from: range),
                    type: .link,
                    attributes: linkAttributed
                )
                textLink.url = privacyURL
                textLinks.append(textLink)
            }
        } else {
            Self.log.error("privacyURL is nil")
        }
        return (attributedString, textLinks)
    }

    init() {
        super.init(frame: .zero)
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

extension LarkPrivacyGuidelineView: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.openLinkHandler?(url)
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }
}

// 拒绝政策后的二次弹窗
final class LarkPrivacyAlertView: UIView {

    private let viewSpcaing: CGFloat = 36.0
    private let labelSpcaing: CGFloat = 20.0
    private let buttonHeight: CGFloat = 50.0

    private static let log = Logger.log(
        LarkPrivacyAlertView.self,
        category: "PrivacyAlert"
    )
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
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.accessibilityIdentifier = "LarkPrivacyAlertView-confirmButton"
        btn.isEnabled = true
        let acceptText = I18N.Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_AcceptButton()
        btn.setTitle(acceptText, for: .normal)
        return btn
    }()
    private lazy var disagreeButton: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.accessibilityIdentifier = "LarkPrivacyAlertView-disagreeButton"
        btn.isEnabled = true
        let declineText = I18N.Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_DeclineButton()
        btn.setTitle(declineText, for: .normal)
        return btn
    }()

    // MARK: - 属性初始化
    private var contentWidth: CGFloat = .zero

    var rightHandler: (() -> Void)?
    var leftHandler: (() -> Void)?
    var openLinkHandler: ((URL) -> Void)?

    // MARK: - 布局、内容初始化
    func setup(config: PrivacyAlertConfigProtocol, availableWidth: CGFloat) {
        contentWidth = calcContentWidth(availableWidth)
        disagreeButton.addTarget(self, action: #selector(noAgreeButtonTapped), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        servicePrivacyPolicyLabel.delegate = self
        let (attributedStr, textLinks) = getAttributedStringAndLink(config: config)
        for textLink in textLinks {
            servicePrivacyPolicyLabel.addLKTextLink(link: textLink)
        }
        servicePrivacyPolicyLabel.attributedText = attributedStr
        setupViews()
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 6
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

    private func calcContentWidth(_ availableWidth: CGFloat) -> CGFloat {
        return min(360, availableWidth - viewSpcaing * 2) // alertView距离左右各36
    }

    // MARK: - 视图变化
    func onViewTransition(_ availableWidth: CGFloat) {
        contentWidth = calcContentWidth(availableWidth)
        self.snp.updateConstraints { $0.width.equalTo(contentWidth) }
        servicePrivacyPolicyLabel.preferredMaxLayoutWidth = contentWidth - labelSpcaing * 2
        servicePrivacyPolicyLabel.invalidateIntrinsicContentSize()
    }

    // MARK: - misc
    private func getAttributedStringAndLink(config: PrivacyAlertConfigProtocol) ->
                                    (NSAttributedString, [LKTextLink]) {
        let font: UIFont = UIFont.systemFont(ofSize: 16)
        let privacyPolicyText = I18N.Lark_Guide_V3_PrivacyPolicy
        let termText = I18N.Lark_Guide_V3_serviceterms()
        let contentText = I18N.Lark_PrivacyPolicy_AgreeToPrivacyPolicyToUse_PopupText(termText, privacyPolicyText)
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
        var textLinks: [LKTextLink] = []
        let linkAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.B600
        ]
        if let privacyURL = URL(string: config.privacyURL),
           let range = contentText.range(of: privacyPolicyText,
                                         options: NSString.CompareOptions.backwards) {
            var textLink = LKTextLink(
                range: contentText.lf.rangeToNSRange(from: range),
                type: .link,
                attributes: linkAttributed
            )
            textLink.url = privacyURL
            textLinks.append(textLink)
        } else {
            Self.log.error("generate privacyURL(\(config.privacyURL) failed")
        }
        if let termsURL = URL(string: config.serviceTermURL) {
            if let range = contentText.range(of: termText,
                                             options: NSString.CompareOptions.backwards) {
                var textLink = LKTextLink(
                    range: contentText.lf.rangeToNSRange(from: range),
                    type: .link,
                    attributes: linkAttributed
                )
                textLink.url = termsURL
                textLinks.append(textLink)
            }
        } else {
            Self.log.error("generate serviceTermURL(\(config.serviceTermURL) failed")
        }
        return (attributedString, textLinks)
    }

    init() {
        super.init(frame: .zero)
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

extension LarkPrivacyAlertView: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.openLinkHandler?(url)
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }
}
