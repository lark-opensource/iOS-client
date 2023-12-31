//
//  ChatPinOnboardingView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/11/5.
//

import Foundation
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignIcon
import FigmaKit
import LarkSDKInterface
import EENavigator
import LKCommonsLogging
import LarkLocalizations
import LarkModel
import LarkCore

final class ChatPinOnboardingView: UIView {
    private let logger = Logger.log(ChatPinOnboardingView.self, category: "Module.IM.ChatPin")

    static var containerCornerRadius: CGFloat { 8 }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        titleLabel.text = BundleI18n.LarkChat.Lark_IM_NewPin_EnhancedPin_Onboard_Title
        return titleLabel
    }()

    private lazy var tipDot1: UIView = {
        let tipDot1 = UIView()
        tipDot1.backgroundColor = UIColor.ud.O200
        tipDot1.layer.cornerRadius = 3
        return tipDot1
    }()

    private lazy var tipLabel1: UILabel = {
        let tipLabel1 = UILabel()
        tipLabel1.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        tipLabel1.attributedText = NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_NewPin_EnhancedPinCombine_Onboard_Desc1,
                                                       attributes: [.paragraphStyle: paragraphStyle,
                                                                    .foregroundColor: UIColor.ud.textTitle,
                                                                    .font: UIFont.systemFont(ofSize: 14)])
        return tipLabel1
    }()

    private lazy var tipDot2: UIView = {
        let tipDot2 = UIView()
        tipDot2.backgroundColor = UIColor.ud.O200
        tipDot2.layer.cornerRadius = 3
        return tipDot2
    }()

    private lazy var tipLabel2: UILabel = {
        let tipLabel2 = UILabel()
        tipLabel2.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        tipLabel2.attributedText = NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_NewPin_EnhancedPinOldPin_Onboard_Desc2,
                                                       attributes: [.paragraphStyle: paragraphStyle,
                                                                    .foregroundColor: UIColor.ud.textTitle,
                                                                    .font: UIFont.systemFont(ofSize: 14)])
        return tipLabel2
    }()

    private lazy var previewView: ChatPinOnboardingPreviewView = {
        let previewView = ChatPinOnboardingPreviewView()
        previewView.backgroundColor = UIColor.ud.bgBase
        previewView.layer.cornerRadius = 8
        return previewView
    }()

    private lazy var detailButton: UIButton = {
        let detailButton = UIButton()
        detailButton.setTitle(BundleI18n.LarkChat.Lark_IM_NewPin_Onboard_LearnMore_Button, for: .normal)
        detailButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        detailButton.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        detailButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        detailButton.layer.cornerRadius = 6
        detailButton.layer.borderWidth = 1
        detailButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        detailButton.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        detailButton.addTarget(self, action: #selector(clickDetail), for: .touchUpInside)
        return detailButton
    }()

    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setTitle(BundleI18n.LarkChat.Lark_IM_NewPin_Onboard_Close_Button, for: .normal)
        closeButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        closeButton.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        closeButton.layer.cornerRadius = 6
        closeButton.layer.borderWidth = 1
        closeButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        closeButton.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        closeButton.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        return closeButton
    }()

    private var closeHandler: (() -> Void)?
    private var detailLinkConfig: ChatPinOnboardingDetailLinkConfig?
    private weak var targetVC: UIViewController?
    private var nav: Navigatable?
    private let isFromInfo: Bool
    private let showClose: Bool
    private var chat: Chat?

    init(showClose: Bool = false,
         detailLinkConfig: ChatPinOnboardingDetailLinkConfig? = nil,
         targetVC: UIViewController? = nil,
         nav: Navigatable? = nil,
         chat: Chat? = nil,
         isFromInfo: Bool) {
        self.showClose = showClose
        self.detailLinkConfig = detailLinkConfig
        self.targetVC = targetVC
        self.nav = nav
        self.chat = chat
        self.isFromInfo = isFromInfo
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = ChatPinOnboardingView.containerCornerRadius
        self.layer.masksToBounds = true
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: UIColor.ud.colorfulLime, position: .init(absoluteLeft: -55, top: -22, width: 120, height: 100), opacity: 0.06),
            subBlob: .init(color: UIColor.ud.colorfulOrange, position: .init(absoluteLeft: -27, top: -136, width: 219, height: 211), opacity: 0.09),
            reflectionBlob: .init(color: UIColor.ud.L200, position: .init(absoluteLeft: 150, top: -72, width: 145, height: 140), opacity: 0.06)
        ))
        self.addSubview(auroraView)
        auroraView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.addSubview(titleLabel)
        self.addSubview(tipLabel1)
        self.addSubview(tipDot1)
        self.addSubview(previewView)
        self.addSubview(tipLabel2)
        self.addSubview(tipDot2)

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(18)
        }

        tipLabel1.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(28)
            make.right.equalToSuperview().inset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        tipDot1.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(12)
            make.size.equalTo(6)
            make.top.equalTo(tipLabel1.snp.top).offset(5)
        }

        previewView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(28)
            make.right.equalToSuperview().inset(12)
            make.top.equalTo(tipLabel1.snp.bottom).offset(8)
            make.height.equalTo(90)
        }

        tipLabel2.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(28)
            make.right.equalToSuperview().inset(12)
            make.top.equalTo(previewView.snp.bottom).offset(14)
        }

        tipDot2.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(12)
            make.size.equalTo(6)
            make.top.equalTo(tipLabel2.snp.top).offset(5)
        }

        if showClose {
            self.addSubview(detailButton)
            self.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.height.equalTo(28)
                make.right.equalToSuperview().inset(12)
                make.top.equalTo(tipLabel2.snp.bottom).offset(12)
                make.bottom.equalToSuperview().inset(12)
            }

            detailButton.snp.makeConstraints { make in
                make.centerY.equalTo(closeButton)
                make.right.equalTo(closeButton.snp.left).offset(-8)
                make.height.equalTo(28)
            }
        } else {
            self.addSubview(detailButton)
            detailButton.snp.makeConstraints { make in
                make.height.equalTo(28)
                make.right.equalToSuperview().inset(12)
                make.top.equalTo(tipLabel2.snp.bottom).offset(12)
                make.bottom.equalToSuperview().inset(12)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(targetVC: UIViewController?, nav: Navigatable, chat: Chat, detailLinkConfig: ChatPinOnboardingDetailLinkConfig?, closeHandler: @escaping () -> Void) {
        self.nav = nav
        self.chat = chat
        self.targetVC = targetVC
        self.detailLinkConfig = detailLinkConfig
        self.closeHandler = closeHandler
    }

    @objc
    private func clickClose() {
        self.closeHandler?()
    }

    @objc
    private func clickDetail() {
        guard let chat = self.chat else { return }
        IMTracker.Chat.Top.Onboarding.Click.KnowDetails(chat, isFromInfo: self.isFromInfo)
        guard let detailLinkConfig = detailLinkConfig else { return }

        let handler: () -> Void = { [weak self] in
            guard let self = self,
                  let targetVC = targetVC,
                  let nav = self.nav else { return }
            switch LanguageManager.currentLanguage {
            case .zh_CN, .zh_HK, .zh_TW:
                if let url = URL(string: detailLinkConfig.zhLink) {
                    nav.push(url, from: targetVC)
                } else {
                    self.logger.error("click onboarding detail zh link can not find")
                }
            case .en_US:
                if let url = URL(string: detailLinkConfig.enLink) {
                    nav.push(url, from: targetVC)
                } else {
                    self.logger.error("click onboarding detail en link can not find")
                }
            case .ja_JP:
                if let url = URL(string: detailLinkConfig.jaLink) {
                    nav.push(url, from: targetVC)
                } else {
                    self.logger.error("click onboarding detail ja link can not find")
                }
            default:
                if let url = URL(string: detailLinkConfig.otherLink) {
                    nav.push(url, from: targetVC)
                } else {
                    self.logger.error("click onboarding detail other link can not find")
                }
            }
        }

        if let presentedViewController = targetVC?.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                handler()
            }
        } else {
            handler()
        }
    }
}

final class ChatPinOnboardingPreviewView: UIView {

    private lazy var cardBgView: UIView = {
        let cardBgView = UIView()
        cardBgView.backgroundColor = UIColor.ud.bgFloat
        cardBgView.layer.cornerRadius = 5.76
        return cardBgView
    }()

    private lazy var announcementIconView: UIImageView = {
        let announcementIconView = UIImageView()
        announcementIconView.image = UDIcon.getIconByKey(.announceFilled, iconColor: UIColor.ud.colorfulOrange, size: CGSize(width: 11.5, height: 11.5))
        return announcementIconView
    }()

    private lazy var announcementTitleLabel: UILabel = {
        let announcementTitleLabel = UILabel()
        announcementTitleLabel.font = UIFont.systemFont(ofSize: 10)
        announcementTitleLabel.textColor = UIColor.ud.textCaption
        announcementTitleLabel.text = BundleI18n.LarkChat.Lark_Groups_Announcement
        return announcementTitleLabel
    }()

    private lazy var moreIconView: UIImageView = {
        let moreIconView = UIImageView()
        moreIconView.image = UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 11.5, height: 11.5))
        moreIconView.contentMode = .center
        moreIconView.backgroundColor = UIColor.ud.fillHover
        moreIconView.layer.cornerRadius = 4.32
        return moreIconView
    }()

    private lazy var contentBgView: UIView = {
        let contentBgView = UIView()
        contentBgView.backgroundColor = UIColor.ud.bgFloat
        contentBgView.layer.borderWidth = 0.48
        contentBgView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        contentBgView.layer.cornerRadius = 5.76
        return contentBgView
    }()

    private lazy var contentLine1: UIView = {
        let contentLine1 = UIView()
        contentLine1.backgroundColor = UIColor.ud.bgFloatOverlay
        contentLine1.layer.cornerRadius = 5.04
        return contentLine1
    }()

    private lazy var contentLine2: UIView = {
        let contentLine2 = UIView()
        contentLine2.backgroundColor = UIColor.ud.bgFloatOverlay
        contentLine2.layer.cornerRadius = 5.04
        return contentLine2
    }()

    private lazy var menuView: ChatPinOnboardingMenuActionView = {
        let menuView = ChatPinOnboardingMenuActionView()
        menuView.backgroundColor = UIColor.ud.bgFloat
        menuView.layer.borderWidth = 0.48
        menuView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        menuView.layer.ud.setShadow(type: .s3Down)
        menuView.layer.cornerRadius = 4.32
        return menuView
    }()

    init() {
        super.init(frame: .zero)

        self.clipsToBounds = true
        self.addSubview(cardBgView)
        cardBgView.addSubview(announcementIconView)
        cardBgView.addSubview(announcementTitleLabel)
        cardBgView.addSubview(moreIconView)
        cardBgView.addSubview(contentBgView)
        contentBgView.addSubview(contentLine1)
        contentBgView.addSubview(contentLine2)
        cardBgView.addSubview(menuView)

        cardBgView.snp.makeConstraints { make in
            make.right.top.left.equalToSuperview().inset(13)
            make.height.equalTo(90)
        }

        announcementIconView.snp.makeConstraints { make in
            make.size.equalTo(11.5)
            make.left.equalToSuperview().inset(8.64)
            make.top.equalToSuperview().inset(10.88)
        }
        announcementTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(announcementIconView.snp.right).offset(3.84)
            make.centerY.equalTo(announcementIconView)
        }
        moreIconView.snp.makeConstraints { make in
            make.size.equalTo(15.83)
            make.right.equalToSuperview().inset(15.06)
            make.centerY.equalTo(announcementIconView)
        }

        contentBgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8.64)
            make.top.equalToSuperview().inset(30.47)
            make.height.equalTo(66)
        }

        contentLine1.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8.64)
            make.top.equalToSuperview().inset(8.64)
            make.height.equalTo(8.64)
        }

        contentLine2.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8.64)
            make.top.equalTo(contentLine1.snp.bottom).offset(11.51)
            make.height.equalTo(8.64)
        }

        menuView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(14.52)
            make.top.equalToSuperview().inset(28.91)
            make.height.equalTo(79.16)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChatPinOnboardingMenuActionView: UIView {

    private lazy var stickIcon: UIImageView = {
        let stickIcon = UIImageView()
        stickIcon.image = UDIcon.getIconByKey(.topAlignOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 11.51, height: 11.51))
        return stickIcon
    }()

    private lazy var stickLable: UILabel = {
        let stickLable = UILabel()
        stickLable.font = UIFont.systemFont(ofSize: 10)
        stickLable.textColor = UIColor.ud.textTitle
        stickLable.text = BundleI18n.LarkChat.Lark_IM_SuperApp_Prioritize_Button
        return stickLable
    }()

    private lazy var unpinIcon: UIImageView = {
        let stickIcon = UIImageView()
        stickIcon.image = UDIcon.getIconByKey(.unpinOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 11.51, height: 11.51))
        return stickIcon
    }()

    private lazy var unpinLable: UILabel = {
        let stickLable = UILabel()
        stickLable.font = UIFont.systemFont(ofSize: 10)
        stickLable.textColor = UIColor.ud.textTitle
        stickLable.text = BundleI18n.LarkChat.Lark_IM_NewPin_Remove_Button
        return stickLable
    }()

    init() {
        super.init(frame: .zero)

        self.addSubview(stickIcon)
        self.addSubview(stickLable)
        self.addSubview(unpinIcon)
        self.addSubview(unpinLable)
        stickIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.top.equalToSuperview().inset(7)
        }
        stickLable.snp.makeConstraints { make in
            make.left.equalTo(stickIcon.snp.right).offset(5.76)
            make.centerY.equalTo(stickIcon)
            make.right.lessThanOrEqualToSuperview().inset(18)
        }
        unpinIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.top.equalTo(stickIcon.snp.bottom).offset(9)
        }
        unpinLable.snp.makeConstraints { make in
            make.left.equalTo(unpinIcon.snp.right).offset(5.76)
            make.centerY.equalTo(unpinIcon)
            make.right.lessThanOrEqualToSuperview().inset(18)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
