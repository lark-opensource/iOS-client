//
//  TopNoticeMenuAction.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/12/2.
//

import Foundation
import UIKit
import RustPB
import LarkModel
import LarkCore
import RxSwift
import EENavigator
import LarkSDKInterface
import UniverseDesignToast
import LarkAlertController
import LarkMessengerInterface
import LarkUIKit
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkContainer
import LarkSetting

public final class TopMessageMenuAction {
    public static func topMessage(chat: Chat,
                           message: Message,
                           userActionService: TopNoticeUserActionService,
                           hasNotice: Bool,
                           targetVC: UIViewController?,
                           disposeBag: DisposeBag,
                           chatFromWhere: String?) {
        guard let chatID = Int64(chat.id), let messageID = Int64(message.id) else {
            return
        }
        var type = RustPB.Im_V1_PatchChatTopNoticeRequest.ActionType.topMsg
        if let content = message.content as? PostContent, content.isGroupAnnouncement {
            type = .topAnnouncement
            let chaterIdString: String? = message.fromChatter?.id
            let chatterId: Int64? = chaterIdString.flatMap(Int64.init)
            userActionService.patchChatTopNoticeWithChatID(chatID,
                                                           type: type,
                                                           senderId: chatterId,
                                                           messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak targetVC] error in
                    if let error = error.underlyingError as? APIError,
                       !error.displayMessage.isEmpty, let view = targetVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                }).disposed(by: disposeBag)
        } else {
            userActionService.patchChatTopNoticeWithChatID(chatID,
                                                           type: type, senderId: nil,
                                                      messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak targetVC] error in
                    if let error = error.underlyingError as? APIError,
                       !error.displayMessage.isEmpty, let view = targetVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                }).disposed(by: disposeBag)
        }
    }

    // swiftlint:disable function_parameter_count
    public static func cancelTopMessage(chat: Chat,
                           message: Message,
                           userActionService: TopNoticeUserActionService,
                           topNotice: ChatTopNotice?,
                           currentUserID: String,
                           nav: Navigatable,
                           targetVC: UIViewController?,
                           disposeBag: DisposeBag,
                           featureGatingService: FeatureGatingService,
                           chatFromWhere: String?) {
    // swiftlint:enable function_parameter_count
        guard let chatID = Int64(chat.id),
              let messageID = Int64(message.id),
              let targetVC = targetVC  else {
            assertionFailure("类型转换失败")
            return
        }
        let pbOperator = topNotice?.operator.chatChatters[chat.id]?.chatters.first?.value
        guard let pbOperator = pbOperator else {
            return
        }
        let operateChatter: Chatter? = try Chatter.transform(pb: pbOperator)
        guard let operateChatter = operateChatter else {
            assertionFailure("OperateChatterNotObtained")
            return
        }
        let fromUserID = operateChatter.id ?? ""
        let p2pRemove = {
                userActionService.patchChatTopNoticeWithChatID(chatID,
                                                               type: .remove, senderId: nil,
                                                          messageId: messageID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        TopNoticeTracker.TopNoticeDidRemove(chat,
                                                            message,
                                                            isTopNoticeOwner: fromUserID == currentUserID,
                                                            action: .p2pRemove
                                                            )
                    }, onError: { [weak targetVC] error in
                        if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = targetVC?.view {
                            UDToast.showFailure(with: error.displayMessage, on: view)
                        }
                    }).disposed(by: disposeBag)
            }
        let groupClose = {
            userActionService.patchChatTopNoticeWithChatID(chatID,
                                                           type: .close, senderId: nil,
                                                      messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    TopNoticeTracker.TopNoticeDidRemove(chat,
                                                        message,
                                                        isTopNoticeOwner: fromUserID == currentUserID,
                                                        action: .close
                                                        )
                }, onError: { [weak targetVC] error in
                    if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = targetVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                }).disposed(by: disposeBag)
        }
        let groupRemove = {
            userActionService.patchChatTopNoticeWithChatID(chatID,
                                                           type: .remove, senderId: nil,
                                                      messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    TopNoticeTracker.TopNoticeDidRemove(chat,
                                                        message,
                                                        isTopNoticeOwner: fromUserID == currentUserID,
                                                        action: .remove
                                                        )
                }, onError: { [weak targetVC] error in
                    if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = targetVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                }).disposed(by: disposeBag)
        }
        TopNoticeTracker.TopNoticeCancelAlertView(chat,
                                                  message,
                                                  isTopNoticeOwner: fromUserID == currentUserID)
        if chat.type == .p2P {
            // 单聊模式不存在权限问题,直接关
            p2pRemove()
        } else {
            if !ChatPinPermissionUtils.checkTopNoticePermission(chat: chat, userID: currentUserID, featureGatingService: featureGatingService) {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyUnclipSelfClip_PopUpTitle)
                alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Cancel, dismissCompletion: nil)
                alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Confirm, dismissCompletion: groupClose)
                nav.present(alertController, from: targetVC)
            } else {
                /// 群聊下若状态为{关闭了自己的置顶},则弹出旧版提示框
                if let topNotice = topNotice, topNotice.closed {
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                    alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_UnclipForAll_GroupOwnerPerspective_PopUpTitle)
                    alertController.addCancelButton()
                    alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IMChatPin_RemovePinItemRemove_PopupButton, dismissCompletion: groupRemove)
                    nav.present(alertController, from: targetVC)
                /// iPhone使用ActionSheet
                } else {
                    removeAction(nav: nav)
                }
            }
        }

        func removeAction(nav: Navigatable) {
            if Display.phone {
                let source = UDActionSheetSource(sourceView: targetVC.view, sourceRect: targetVC.view.bounds, arrowDirection: .up)
                let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
                actionsheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                actionsheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyForMe, action: groupClose)
                actionsheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_ForAllMembers, action: groupRemove)
                actionsheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Cancel)
                nav.present(actionsheet, from: targetVC)
            /// iPad使用LarkAlertController
            } else {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyForMe, dismissCompletion: groupClose)
                alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_ForAllMembers, dismissCompletion: groupRemove)
                alertController.addCancelButton()
                nav.present(alertController, from: targetVC)
            }
        }
    }
}
