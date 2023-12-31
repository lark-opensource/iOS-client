//
//  FlagListViewController+Action.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/21.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkCore
import RxRelay
import LarkSDKInterface
import TangramService
import RustPB
import ServerPB
import LarkAccountInterface
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignActionPanel
import LarkMessengerInterface
import LKCommonsTracker
import Homeric
import EENavigator
import LarkOpenFeed
import LarkUIKit

extension FlagListViewController {
    // 长按或者左滑：标记/取消标记
    public func markForFlag(flagItem: FlagItem, isFlaged: Bool) {
        if flagItem.type == .feed, let feedVM = flagItem.feedVM {
            // feed类型：如果是话题消息（msgThread）的话要特殊处理下
            var entityType = feedVM.feedPreview.basicMeta.feedPreviewPBType
            let threadType = feedVM.feedPreview.preview.threadData.entityType
            if entityType == .thread, threadType == .msgThread {
                entityType = .msgThread
            }
            self.viewModel.dataDependency.flagAPI?.updateFeed(isFlaged: isFlaged, feedId: flagItem.flagId, entityType: entityType)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    // 埋点
                    let title = isFlaged ? "mark" : "unmark"
                    let chatId = flagItem.feedVM?.feedPreview.id ?? ""
                    let params: [AnyHashable: Any] = [ "click": title, "target": "none", "chat_id": chatId]
                    Tracker.post(TeaEvent(Homeric.FEED_LEFTSLIDE_DETAIL_CLICK, params: params))
                    FlagListViewController.logger.info("LarkFlag: [FlagFeed] isFlag = \(isFlaged), flagId = \(flagItem.flagId), entityType = \(entityType)")
                    guard let self = self, let window = self.view.window else { return }
                    UDToast.showTips(with: isFlaged ? BundleI18n.LarkFlag.Lark_IM_Marked_Toast : BundleI18n.LarkFlag.Lark_IM_Marked_Unmakred_Toast,
                                     on: window)
                }, onError: { [weak self] error in
                    guard let self = self, let window = self.view.window else { return }
                    let title = BundleI18n.LarkFlag.Lark_Core_Label_ActionFailed_Toast
                    UDToast.showFailure(with: title, on: window, error: error)
                    FlagListViewController.logger.error("LarkFlag: [FlagFeed] isFlag = \(isFlaged), flagId = \(flagItem.flagId), entityType = \(entityType)", error: error)
                }).disposed(by: self.disposeBag)
        } else if flagItem.type == .message, let messageVM = flagItem.messageVM {
            // message类型
            guard let chat = messageVM.chat, chat.role == .member, !chat.isDissolved else {
                let config = UDActionSheetUIConfig(isShowTitle: true)
                let actionSheet = UDActionSheet(config: config)
                actionSheet.setTitle(BundleI18n.LarkFlag.Lark_IM_Marked_CancelMarked_Desc)
                let item = UDActionSheetItem(
                    title: BundleI18n.LarkFlag.Lark_IM_MarkAMessageToArchive_CancelButton,
                    titleColor: UIColor.ud.functionDangerContentDefault,
                    style: .default,
                    isEnable: true,
                    action: { [weak self] in
                        guard let self = self, let window = self.view.window else { return }
                        self.flagMessage(flagItem, isFlaged: isFlaged)
                        UDToast.showTips(with: isFlaged ? BundleI18n.LarkFlag.Lark_IM_Marked_Toast : BundleI18n.LarkFlag.Lark_IM_Marked_Unmakred_Toast,
                                         on: window)
                    })
                actionSheet.addItem(item)
                actionSheet.setCancelItem(text: BundleI18n.LarkFlag.Lark_IM_Marked_CancelMarked_HoldForNow_Button)
                viewModel.userResolver.navigator.present(actionSheet, from: self)
                return
            }
            // 还在当前会话内
            self.flagMessage(flagItem, isFlaged: isFlaged)
        }
    }

    private func flagMessage(_ flagItem: FlagItem, isFlaged: Bool) {
        self.viewModel.dataDependency.flagAPI?.updateMessage(isFlaged: isFlaged, messageId: flagItem.flagId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                // 埋点
                let title = isFlaged ? "mark" : "unmark"
                var params: [AnyHashable: Any] = [ "click": title, "target": "none"]
                if let chat = flagItem.messageVM?.chat, let message = flagItem.messageVM?.message {
                    params += IMTracker.Param.chat(chat)
                    params += IMTracker.Param.message(message)
                }
                Tracker.post(TeaEvent(Homeric.FEED_LEFTSLIDE_MSG_DETAIL_CLICK, params: params))
                FlagListViewController.logger.info("LarkFlag: [FlagMessage] isFlag = \(isFlaged), flagId = \(flagItem.flagId)")
            }, onError: { [weak self] error in
                guard let self = self, let window = self.view.window else { return }
                let title = BundleI18n.LarkFlag.Lark_Core_Label_ActionFailed_Toast
                UDToast.showFailure(with: title, on: window, error: error)
                FlagListViewController.logger.error("LarkFlag: [FlagMessage] isFlag = \(isFlaged), flagId = \(flagItem.flagId)", error: error)
            }).disposed(by: self.disposeBag)
    }

    // 长按或者左滑：置顶/取消置顶
    public func markForShortcut(flagItem: FlagItem) {
        // 只有feed才能被置顶
        guard flagItem.type == .feed, let feedVM = flagItem.feedVM else {
            return
        }
        let channel = feedVM.bizData.shortcutChannel
        var shortcut = Feed_V1_Shortcut()
        shortcut.channel = channel
        if feedVM.feedPreview.basicMeta.isShortcut {
            self.deleteShortcuts([shortcut], feedPreview: feedVM.feedPreview)
        } else {
            self.createShortcuts([shortcut], feedPreview: feedVM.feedPreview)
        }
    }

    // 置顶操作
    private func createShortcuts(_ shortcuts: [Feed_V1_Shortcut], feedPreview: FeedPreview) {
        self.viewModel.dataDependency.feedAPI?.createShortcuts(shortcuts)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self, let window = self.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkFlag.Lark_Chat_QuickswitcherPinClickToasts, on: window)
            }, onError: { [weak self] (error) in
                guard let error = error.underlyingError as? APIError else {
                    if let window = self?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkFlag.Lark_Feed_AddQuickSwitcherFail, on: window, error: error)
                    }
                    return
                }
                guard let window = self?.view.window else { return }
                var channel = Basic_V1_Channel()
                channel.type = .chat
                channel.id = feedPreview.id
                if Int(error.errorCode) == 111_001 {
                    self?.removeFeedCard(channel: channel, feedPreviewPBType: feedPreview.basicMeta.feedPreviewPBType)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkFlag.Lark_Feed_AddQuickSwitcherFail, on: window, error: error)
                }
            }).disposed(by: disposeBag)
    }

    // 取消置顶操作
    private func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut], feedPreview: FeedPreview) {
        self.viewModel.dataDependency.feedAPI?.deleteShortcuts(shortcuts)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                if let window = self?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkFlag.Lark_Chat_QuickswitcherUnpinClickToasts, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let error = error.underlyingError as? APIError else {
                    if let window = self?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkFlag.Lark_Feed_RemoveQuickSwitcherFail, on: window, error: error)
                    }
                    return
                }
                guard let window = self?.view.window else { return }
                var channel = Basic_V1_Channel()
                channel.type = .chat
                channel.id = feedPreview.id
                if Int(error.errorCode) == 111_001 {
                    self?.removeFeedCard(channel: channel, feedPreviewPBType: feedPreview.basicMeta.feedPreviewPBType)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkFlag.Lark_Feed_RemoveQuickSwitcherFail, on: window, error: error)
                }
            }).disposed(by: disposeBag)
    }

    private func removeFeedCard(channel: Basic_V1_Channel,
                             feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?) {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkFlag.Lark_IM_YouAreNotInThisChat_Text, numberOfLines: 0)
        dialog.addPrimaryButton(text: BundleI18n.LarkFlag.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.viewModel.dataDependency.feedAPI?.removeFeedCard(channel: channel, feedType: feedPreviewPBType)
                .subscribe(onNext: { _ in
                    FlagListViewController.logger.debug("Flag request hide channel id\(channel.id) success")
                })
                .disposed(by: self.disposeBag)
        })
        self.present(dialog, animated: true, completion: nil)
    }

    // 长按或者左滑：转发消息
    public func markForForward(flagItem: FlagItem) {
        guard let messageVM = flagItem.messageVM, let chat = messageVM.chat else {
            return
        }
        let from: ForwardMessageBody.From = .flag
        var traceChatType: ForwardAppReciableTrackChatType = .unknown
        if chat.type == .p2P {
            traceChatType = .single
        } else if chat.type == .group {
            traceChatType = .group
        } else if chat.type == .topicGroup {
            traceChatType = .topic
        }
        var params: [AnyHashable: Any] = [ "click": "forward", "target": "none"]
        if let chat = flagItem.messageVM?.chat, let message = flagItem.messageVM?.message {
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(message)
        }
        Tracker.post(TeaEvent(Homeric.FEED_LEFTSLIDE_MSG_DETAIL_CLICK, params: params))
        if let disableBehavior = flagItem.message?.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
            let errorMessage: String
            switch disableBehavior.code {
            case 311_150:
                errorMessage = BundleI18n.LarkFlag.Lark_IM_MessageRestrictedCantForward_Hover
            default:
                errorMessage = BundleI18n.LarkFlag.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
            }
            DispatchQueue.main.async {
                guard let window = WindowTopMostFrom(vc: self).fromViewController?.view else { return }
                UDToast.showFailure(with: errorMessage, on: window)
            }
            return
        }
        /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
        /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
//        let originMergeForwardId: String?
        let body = ForwardMessageBody(originMergeForwardId: nil,
                                      message: messageVM.message,
                                      type: .message(messageVM.message.id),
                                      from: from,
                                      traceChatType: traceChatType)
        viewModel.userResolver.navigator.present(
            body: body,
            from: self,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    // 长按或者左滑：消息免打扰/允许消息通知
    func markForMute(flagItem: FlagItem, isRemind: Bool) {
        guard let feedVM = flagItem.feedVM, let cellViewModel = feedVM as? BaseFeedTableCellMute else {
            return
        }
        let id = feedVM.feedPreview.id
        let feedPreviewPBType = feedVM.feedPreview.basicMeta.feedPreviewPBType
        cellViewModel.setMute()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                if let window = self?.view.window {
                    let message = isRemind ? BundleI18n.LarkFlag.Lark_Core_TouchAndHold_MuteChats_MutedToast : BundleI18n.LarkFlag.Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast
                    UDToast.showTips(with: message, on: window)
                }
            } onError: { [weak self] error in
                guard let window = self?.view.window,
                      let error = error.underlyingError as? APIError else { return }
                let message = isRemind ? BundleI18n.LarkFlag.Lark_Core_UnableToMuteNotificationsTryLater_Toast : BundleI18n.LarkFlag.Lark_Core_UnableToUnmuteNotificationsTryLater_Toast
                if Int(error.errorCode) == 111_001 {
                    var channel = Basic_V1_Channel()
                    channel.type = .chat
                    channel.id = id
                    self?.removeFeedCard(channel: channel, feedPreviewPBType: feedPreviewPBType)
                } else {
                    UDToast.showFailure(with: message, on: window, error: error)
                }
            }.disposed(by: self.disposeBag)
    }
    public func markForLabel(flagItem: FlagItem) {
        // 只有feed才能被置顶
        guard flagItem.type == .feed,
              let feedVM = flagItem.feedVM,
              let feedId = Int64(feedVM.feedPreview.id) else {
            return
        }
        let body = AddItemInToLabelBody(feedId: feedId, infoCallback: { (mode, hasRelation) in
            switch mode {
            case .create:
                // 点击 Feed 长按标签(用户没有创建标签)
                let params = ["click": "create_label_mobile",
                              "target": "feed_create_label_view"]
                Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
            case .edit:
                if hasRelation {
                    // 点击 Feed 长按标签(有标签，feed也关联了标签)
                    let params = ["click": "label_mobile",
                                  "target": "feed_mobile_label_setting_view"]
                    Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK,
                                          params: params))
                } else {
                    // 点击 Feed 长按标签(有标签，feed没有关联任何标签)
                    let params = ["click": "edit_label_mobile",
                                  "target": "feed_mobile_label_setting_view"]
                    Tracker.post(TeaEvent(Homeric.FEED_PRESS_CLICK, params: params))
                }
            @unknown default: break
            }
        })
        viewModel.userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }

    // 快捷加入团队
    func joinToTeam(feedPreview: FeedPreview) {
        let body = EasilyJoinTeamBody(feedpreview: feedPreview)
        viewModel.userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }

    // 清未读
    func clearSingleBadge(feedPreview: FeedPreview) {
        viewModel.dataDependency
            .clearSingleBadge(feedID: feedPreview.id, feedEntityPBType: feedPreview.basicMeta.feedPreviewPBType)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
