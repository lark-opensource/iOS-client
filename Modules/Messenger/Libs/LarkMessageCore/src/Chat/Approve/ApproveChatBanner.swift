//
//  ApproveChatBanner.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/4/8.
//

import Foundation
import UIKit
import Homeric
import SnapKit
import LarkButton
import EENavigator
import RxSwift
import LarkModel
import LarkCore
import LKCommonsTracker
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignNotice
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignColor

private struct ApproveChatBannerConfig {
    static var backgroundColor: UIColor {
        UIColor.ud.N00.ud.withOver(UIColor.ud.colorfulBlue.withAlphaComponent(0.15))
    }
}

public final class ApproveChatBanner: UDNotice {
    private let logger = Logger.log(ChatChatterController.self, category: "Module.IM.ApproveChatBanner")

    private let disposeBag = DisposeBag()
    private let chatID: String
    public var chatWrapper: ChatPushWrapper
    private let chatAPI: ChatAPI
    private weak var targetVC: UIViewController?

    private let updateDisplay: ((Bool) -> Void)?
    public override var isHidden: Bool {
        didSet {
            if isHidden != oldValue {
                updateDisplay?(isHidden)
            }
        }
    }
    private let nav: Navigatable
    public init(targetVC: UIViewController?,
                chatWrapper: ChatPushWrapper,
                chatAPI: ChatAPI,
                nav: Navigatable,
                updateDisplay: ((Bool) -> Void)?) {
        let chat = chatWrapper.chat.value
        self.chatWrapper = chatWrapper
        self.chatID = chat.id
        self.chatAPI = chatAPI
        self.targetVC = targetVC
        self.updateDisplay = updateDisplay
        self.nav = nav

        var config = UDNoticeUIConfig(backgroundColor: ApproveChatBannerConfig.backgroundColor,
                                      attributedText: NSAttributedString(string: ""))

        config.leadingIcon = UDIcon.getIconByKey(.infoColorful, size: CGSize(width: 16, height: 16))
        config.trailingButtonIcon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))

        super.init(config: config)

        self.delegate = self
        updateChat(chat)
        subscribeEvent()
    }

    private func updateChat(_ chat: Chat) {
        let count = Int(chat.putChatterApplyCount)
        self.isHidden = !chat.showBanner || count < 1

        let lineHeight = CGFloat(20)
        let string = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Groups_NewNumPendingRequests(count),
                                               attributes: [.foregroundColor: UIColor.ud.textTitle])
        string.append(NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Groups_NewClickToViewPendingRequests,
                                         attributes: [.link: "UDNOTICE://buttonAttr"]))
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        let offset = (lineHeight - self.font.lineHeight) / 4
        string.addAttributes([.paragraphStyle: style,
                              .baselineOffset: offset],
                             range: NSRange(location: 0, length: string.length))

        var config = self.config
        config.attributedText = string
        self.updateConfigAndRefreshUI(config)
    }

    private func subscribeEvent() {
        chatWrapper.chat
            .filter { !$0.isMeeting }
            .distinctUntilChanged {
                $0.showBanner == $1.showBanner && $0.putChatterApplyCount == $1.putChatterApplyCount
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                self?.updateChat(chat)
            }).disposed(by: disposeBag)
    }

    @objc
    private func onTapClose() {
        chatGroupApplicationClose()
        hiddenView()
    }

    private func hiddenView() {
        let chatID = self.chatID
        chatAPI.updateAddChatChatterApply(chatId: chatID, showBanner: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.isHidden = true
            }, onError: { [weak self] error in
                self?.logger.error(
                    "update add chat apply banner hidden",
                    additionalData: ["chatID": chatID],
                    error: error)
            })
            .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func chatGroupApplicationClose() {
        Tracker.post(TeaEvent(Homeric.GROUP_APPLICATION_CLOSE))

    }

    func chatGroupApplicationClick() {
        Tracker.post(TeaEvent(Homeric.GROUP_APPLICATION_CLICK))
    }
}

extension ApproveChatBanner: UDNoticeDelegate {
    public func handleLeadingButtonEvent(_ button: UIButton) { }

    public func handleTrailingButtonEvent(_ button: UIButton) {
        LarkMessageCoreTracker.trackNoticeBarClick(chat: chatWrapper.chat.value, noticeBarType: .mute_noticebar, click: .close)
        onTapClose()
    }

    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        LarkMessageCoreTracker.trackNoticeBarClick(chat: chatWrapper.chat.value, noticeBarType: .mute_noticebar, click: .click_to_process)
        chatGroupApplicationClick()
        let body = ApprovalBody(chatId: chatID)
        if let targetVC = self.targetVC {
            self.nav.push(body: body, from: targetVC)
        }
        // 点击进入也要关闭View
        hiddenView()
    }
}
