//
//  GroupAnnouncementServiceIMP.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/11/22.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import LarkUIKit
import LarkModel
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkSDKInterface
import LarkSendMessage
import LarkAlertController
import LarkContainer
import LKCommonsLogging
import UniverseDesignActionPanel
import LarkSplitViewController
import LarkSetting

final class GroupAnnouncementServiceIMP: GroupAnnouncementService, UserResolverWrapper {
    let userResolver: UserResolver

    private static let logger = Logger.log(GroupAnnouncementServiceIMP.self,
                                           category: "GroupAnnouncementServiceIMP")

    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?

    @ScopedInjectedLazy var topNoticeService: ChatTopNoticeService?

    @ScopedInjectedLazy var sendThreadAPI: SendThreadAPI?

    @ScopedInjectedLazy var chatAPI: ChatAPI?

    @ScopedInjectedLazy var userActionService: TopNoticeUserActionService?

    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func showSendAlertSheetIfNeed(chatId: String,
                                  uiConfig: SendAlertSheetUIConfig,
                                  extra: [String: Any]?,
                                  getInfoHandler: @escaping ( @escaping GetGroupAnnouncementInfoClosure) -> Void,
                                  completion: ((_ isCancel: Bool) -> Void)?) {
        let sourceView = uiConfig.actionView
        let fromVC = uiConfig.fromController
        self.chatAPI?.fetchChat(by: chatId, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC, weak sourceView] chat in
                if let chat = chat {
                    self?.showAlertSheetWidth(chat: chat,
                                              fromVC: fromVC,
                                              sourceView: sourceView,
                                              extra: extra,
                                              getInfoHandler: getInfoHandler,
                                              completion: completion)
                } else {
                    Self.logger.error("本地获取Chat失败")
                }
            }, onError: { error in
                Self.logger.error("fetchChatError \(chatId)", error: error)
            }).disposed(by: disposeBag)
    }

    func showAlertSheetWidth(chat: Chat,
                             fromVC: UIViewController?,
                             sourceView: UIView?,
                             extra: [String: Any]?,
                             getInfoHandler: @escaping (@escaping GetGroupAnnouncementInfoClosure) -> Void,
                             completion: ((_ isCancel: Bool) -> Void)?) {
        guard let fromVC = fromVC else { return }
        TopNoticeTracker.ChatAnnouncementPageClick(chat)
        var hud: UDToast?
        var needTopGroupAnnouncement = false

        var successPushTochat: ((Bool) -> Void)? = { [weak self, weak fromVC, weak hud] success in
            hud?.remove()
            Self.logger.info("从CCM获取群公告信息成功 chatID \(chat.id)")
            completion?(false)
            self?.pushChatVCWithChat(chat, fromVC: fromVC, showSuccess: success)
        }

        let hander: (GetGroupAnnouncementInfoResult) -> Void = { [weak self, weak fromVC] (result) in
            switch result {
            case .success(let chatId, let richText, let title):
                if chat.chatMode == .threadV2 {
                    self?.sendThreadAPI?.sendPost(context: nil,
                                                 to: .threadChat,
                                                 title: title,
                                                 content: richText,
                                                 chatId: chatId,
                                                 isGroupAnnouncement: true,
                                                 preprocessingHandler: nil)
                    if !needTopGroupAnnouncement {
                        successPushTochat?(true)
                    }
                } else {
                    self?.sendMessageAPI?.sendPost(context: nil,
                                                  title: title,
                                                  content: richText,
                                                  parentMessage: nil,
                                                  chatId: chatId,
                                                  threadId: nil,
                                                  isGroupAnnouncement: true,
                                                  scheduleTime: nil,
                                                  preprocessingHandler: nil,
                                                  sendMessageTracker: nil,
                                                  stateHandler: { [weak fromVC] state in
                        DispatchQueue.main.async {
                            if !needTopGroupAnnouncement {
                                switch state {
                                // 消息发送成功
                                case .finishSendMessage(_, _, _, _, _):
                                    successPushTochat?(true)
                                case .errorSendMessage(_, let error):
                                    Self.logger.error("send message error for chatID: \(chatId)", error: error)
                                    hud?.remove()
                                    if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = fromVC?.view {
                                        UDToast.showFailure(with: error.displayMessage, on: view)
                                    } else {
                                        successPushTochat?(false)
                                    }
                                default: break
                                }
                            }
                        }
                    })
                }
                if needTopGroupAnnouncement {
                    self?.topGroupAnnouncementWith(chat: chat,
                                                   hud: hud,
                                                   fromVC: fromVC,
                                                   needShowSender: true,
                                                   completion: completion)
                }
            case .fail(let error, let displayMsg):
                hud?.remove()
                Self.logger.error("从CCM获取群公告信息失败 chatID \(chat.id)", error: error)
                if let view = fromVC?.view {
                    if let error = error {
                        UDToast.showFailure(with: displayMsg, on: view, error: error)
                    } else {
                        UDToast.showFailure(with: displayMsg, on: view)
                    }
                }

                if needTopGroupAnnouncement {
                    /// 有一个请求失败 就不需要push页面了
                    self?.topGroupAnnouncementWith(chat: chat,
                                                   hud: nil,
                                                   fromVC: fromVC,
                                                   pushChatVCOnSuccess: false,
                                                   needShowSender: true,
                                                   completion: nil)
                }
            }
        }

        /// 发送消息置顶
        let onlySendMessageBlock = { [weak fromVC] in
            hud = UDToast.showLoading(with: BundleI18n.LarkMessageCore.Lark_Legacy_Sending, on: fromVC?.view ?? UIView())
            getInfoHandler(hander)
            TopNoticeTracker.GroupAnnouncementSettingClick(chat, type: .sendToChat)
        }

        /// 如果是不支持的群 或者 没有权限的情况下 直接发送群公告
        guard let topNoticeService = self.topNoticeService, topNoticeService.isSupportTopNoticeChat(chat), topNoticeService.canTopNotice(chat: chat) else {
            onlySendMessageBlock()
            return
        }

        /// 置顶通知
        let onlyTopNoticeBlock = { [weak self, weak fromVC] in
            hud = UDToast.showLoading(with: BundleI18n.LarkMessageCore.Lark_Legacy_Sending, on: fromVC?.view ?? UIView())
            self?.topGroupAnnouncementWith(chat: chat,
                                           hud: hud,
                                           fromVC: fromVC,
                                           needShowSender: false,
                                           completion: completion)
            TopNoticeTracker.GroupAnnouncementSettingClick(chat, type: .pinToTop)
        }

        /// 发送消息置顶&置顶通知
        let sendMessageAndTopNoticeBlock = { [weak fromVC] in
            hud = UDToast.showLoading(with: BundleI18n.LarkMessageCore.Lark_Legacy_Sending, on: fromVC?.view ?? UIView())
            needTopGroupAnnouncement = true
            getInfoHandler(hander)
            TopNoticeTracker.GroupAnnouncementSettingClick(chat, type: .sendToChatAndPinToTop)
        }
        self.didShowAlertWith(chat: chat,
                              fromVC: fromVC,
                              onlySendMessageBlock: onlySendMessageBlock,
                              onlyTopNoticeBlock: onlyTopNoticeBlock,
                              sendMessageAndTopNoticeBlock: sendMessageAndTopNoticeBlock,
                              completion: completion)
    }

    /// 展示操作alert
    func didShowAlertWith(chat: Chat,
                          fromVC: UIViewController,
                          onlySendMessageBlock: (() -> Void)?,
                          onlyTopNoticeBlock: (() -> Void)?,
                          sendMessageAndTopNoticeBlock: (() -> Void)?,
                          completion: ((_ isCancel: Bool) -> Void)?) {
        let title = BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettings_PopupTitle
        let onlySendMessageTitle = chat.chatMode == .threadV2 ?
        BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsSendToTopicGroup_Option :
        BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsSendToChat_Option

        let onlyTopNoticeTitle = chat.chatMode == .threadV2 ?
        BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsPinInTopicGroup_Option :
        BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsPinInChat_Option

        var sendMessageAndTopNoticeTitle: String?
        if ChatNewPinConfig.supportPinMessage(chat: chat, self.userResolver.fg) {
            if ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg) {
                sendMessageAndTopNoticeTitle = BundleI18n.LarkMessageCore.Lark_IM_SuperApp_AnnouncementSendPrioritize_Option
            }
        } else if chat.chatMode == .threadV2 {
            sendMessageAndTopNoticeTitle = BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsMobileSendAndPinTopicGroup_Option
        } else {
            sendMessageAndTopNoticeTitle = BundleI18n.LarkMessageCore.Lark_IMChatPin_GroupAnnouncementSettingsMobileSendAndPin_Option
        }

        if Display.phone {
            let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: true) {
                completion?(true)
            }
            let actionsheet = UDActionSheet(config: config)
            actionsheet.setTitle(title)
            actionsheet.addItem(.init(title: onlySendMessageTitle, titleColor: UIColor.ud.textTitle, action: {
                onlySendMessageBlock?()
            }))
            if !ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
                actionsheet.addItem(.init(title: onlyTopNoticeTitle, titleColor: UIColor.ud.textTitle, action: {
                    onlyTopNoticeBlock?()
                }))
            }
            if let sendMessageAndTopNoticeTitle = sendMessageAndTopNoticeTitle {
                actionsheet.addItem(.init(title: sendMessageAndTopNoticeTitle, titleColor: UIColor.ud.textTitle, action: {
                    sendMessageAndTopNoticeBlock?()
                }))
            }
            actionsheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel) {
                completion?(true)
            }
            self.navigator.present(actionsheet, from: fromVC)

        } else {
            let alertController = LarkAlertController()
            alertController.setTitle(text: title)
            alertController.addSecondaryButton(text: onlySendMessageTitle, dismissCompletion: {
                onlySendMessageBlock?()
            })
            if !ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) {
                alertController.addSecondaryButton(text: onlyTopNoticeTitle, dismissCompletion: {
                    onlyTopNoticeBlock?()

                })
            }
            if let sendMessageAndTopNoticeTitle = sendMessageAndTopNoticeTitle {
                alertController.addSecondaryButton(text: sendMessageAndTopNoticeTitle, dismissCompletion: {
                    sendMessageAndTopNoticeBlock?()
                })
            }
            alertController.addCancelButton(dismissCompletion: {
                completion?(true)
            })
            self.navigator.present(alertController, from: fromVC)
        }
        TopNoticeTracker.GroupAnnouncementSettingView(chat)
    }

   private func pushChatVCWithChat(_ chat: Chat, fromVC: UIViewController?, showSuccess: Bool = true) {
        guard let fromVC = fromVC else {
            return
        }
        let rootVC = fromVC.view.window?.rootViewController
        let showSuccessBlock = { [weak self] in
            guard let vc = self?.topMost(of: rootVC) else {
                assertionFailure("找不到topMostVC")
                return
            }
            if showSuccess {
                UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_SentSuccessfully, on: vc.view)
            }
        }
        if chat.chatMode == .threadV2 {
            let byIDbody = ThreadChatByIDBody(chatID: chat.id)
            self.navigator.push(body: byIDbody, from: fromVC) { _, _ in
                showSuccessBlock()
            }
            return
        }
        let body = ChatControllerByIdBody(chatId: chat.id)
        self.navigator.push(body: body, from: fromVC) { _, _ in
            showSuccessBlock()
        }
    }
    /// 群公告置顶
    private func topGroupAnnouncementWith(chat: Chat,
                                          hud: UDToast?,
                                          fromVC: UIViewController?,
                                          pushChatVCOnSuccess: Bool = true,
                                          needShowSender: Bool,
                                          completion: ((_ isCancel: Bool) -> Void)?) {
        let chatID = Int64(chat.id) ?? 0
        let chatterId: Int64? = needShowSender ? Int64(userResolver.userID) : nil
        let observable: Observable<Void>?
        if ChatNewPinConfig.supportPinMessage(chat: chat, self.userResolver.fg) {
            observable = chatAPI?.stickAnnouncementChatPin(chatID: chatID).map { _ in return }
        } else {
            observable = userActionService?.patchChatTopNoticeWithChatID(chatID,
                                                                         type: .topAnnouncement,
                                                                         senderId: chatterId,
                                                                         messageId: nil).map { _ in return }
        }
        observable?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] _ in
                hud?.remove()
                if pushChatVCOnSuccess {
                    completion?(false)
                    self?.pushChatVCWithChat(chat, fromVC: fromVC)
                }
            }, onError: { error in
                hud?.remove()
                if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = fromVC?.view {
                    UDToast.showFailure(with: error.displayMessage, on: view)
                }
                Self.logger.error("发布群公告置顶失败 chatId: \(chatID)", error: error)
            }).disposed(by: disposeBag)
    }

    /// CCM线上方法
    func topMost(of viewController: UIViewController?) -> UIViewController? {

        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }

        // LKSplitViewController
        if let svc = viewController as? SplitViewController {
            return self.topMost(of: svc.topMost)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        return viewController
    }

}
