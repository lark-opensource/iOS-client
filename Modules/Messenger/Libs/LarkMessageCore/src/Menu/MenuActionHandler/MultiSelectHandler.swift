//
//  MultiSelectHandler.swift
//  LarkChat
//
//  Created by liuwanlin on 2019/6/19.
//

import UIKit
import Foundation
import RxSwift
import LarkEMM
import LarkCore
import LarkModel
import UniverseDesignToast
import EENavigator
import LarkMessageBase
import LKCommonsLogging
import LarkAlertController
import LarkSDKInterface
import Homeric
import LKCommonsTracker
import LarkMessengerInterface
import LarkFeatureSwitch
import SuiteAppConfig
import LarkFeatureGating
import LarkUIKit
import LarkContainer
import LarkGuide
import LarkGuideUI
import UniverseDesignIcon
import LarkNavigation
import LarkKAFeatureSwitch
import LarkReleaseConfig
import LarkAccountInterface
import LarkSensitivityControl
import ServerPB
import LarkSetting
import LarkOpenChat

public protocol MutiSelectHandlerDependecy {
    func canDisplayCreateWorkItemEntrance(chat: Chat, messages: [Message]?, from: String) -> Bool

    func createWorkItem(
        with chat: Chat,
        messages: [Message]?,
        sourceVc: UIViewController,
        from: String
    )
}

public struct MultiSelectInfo {
    public static let maxSelectedMessageLimitCount: Int = 100 /// 目前限制的消息最大可选择数量
    public static let followingMessageClickKey = "MultiSelectFollowingMessageClickKey" /// 是否点击「选择以下消息」按钮来选择消息，埋点使用
}

public final class MultiSelectHandler: UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver

    static let logger = Logger.log(MultiSelectHandler.self, category: "Module.MultiSelectHandler")

    private weak var chatPageAPI: ChatPageAPI?
    private let scene: ContextScene
    private weak var pageContainer: PageContainer?

    private var deleteMessageService: DeleteMessageService? {
        return pageContainer?.resolve(DeleteMessageService.self)
    }
    private weak var chatDeleteMessageService: DeleteMessageService?

    private let currentChatter: Chatter
    @ScopedInjectedLazy private var favoritesAPI: FavoritesAPI?
    private let disposeBag = DisposeBag()
    private let takeActionV2: ((String, [String]) -> Void)?
    @ScopedInjectedLazy private var todoDependency: MessageCoreTodoDependency?
    @ScopedInjectedLazy private var dependency: MutiSelectHandlerDependecy?
    @ScopedInjectedLazy private var navigationService: NavigationService?
    @ScopedInjectedLazy private var appConfigService: AppConfigService?
    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var newGuideManager: NewGuideService?
    @ScopedInjectedLazy private var passportService: PassportUserService?
    private let openMenuItemFactory = OpenMessageMenuItemFactory()

    static let singleFowardGuideKey = "im_msg_one_by_one_forward"

    public init(
        userResolver: UserResolver,
        currentChatter: Chatter,
        scene: ContextScene,
        pageContainer: PageContainer,
        chatPageAPI: ChatPageAPI?,
        takeActionV2: ((String, [String]) -> Void)?
    ) {
        self.userResolver = userResolver
        self.currentChatter = currentChatter
        self.scene = scene
        self.pageContainer = pageContainer
        self.chatPageAPI = chatPageAPI
        self.takeActionV2 = takeActionV2
    }

    public init(
        userResolver: UserResolver,
        currentChatter: Chatter,
        scene: ContextScene,
        chatPageAPI: ChatPageAPI?,
        chatDeleteMessageService: DeleteMessageService?,
        takeActionV2: ((String, [String]) -> Void)?
    ) {
        self.userResolver = userResolver
        self.currentChatter = currentChatter
        self.scene = scene
        self.chatDeleteMessageService = chatDeleteMessageService
        self.chatPageAPI = chatPageAPI
        self.takeActionV2 = takeActionV2
    }

    /// 红包开关校验
    private lazy var redPacketEnable: Bool = {
        let fg = self.userResolver.fg
        let featureSwitchEnable = fg.staticFeatureGatingValue(with: .init(switch: .ttPay))
        let featureGatingEnable = fg.staticFeatureGatingValue(with: .init(key: .redPacket))
        let isFeishu = ReleaseConfig.isFeishu
        let isByteDancer = passportService?.userTenant.isByteDancer ?? false

        let redPacketEnable: Bool = featureSwitchEnable
            && isFeishu
            && ((passportService?.isFeishuBrand ?? false) || isByteDancer || featureGatingEnable)
            && appConfigService?.feature(for: "chat.hongbao").isOn ?? false
        return redPacketEnable
    }()

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        var items = [BottomMenuItem]()
        let messages = chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? []

        // 合并转发
        if !chat.isPrivateMode {
            let mergeForwardItem = BottomMenuItem(
                type: .mergeFoward,
                name: BundleI18n.LarkMessageCore.Lark_Legacy_MenuMergeForward,
                image: UDIcon.getIconByKey(.forwardComOutlined),
                action: { [weak self] in
                    guard let `self` = self else { return }
                    if !self.checkMultiselectEnable() { return }
                    if self.mergeForward(chat: chat) {
                        IMTracker.Msg.MultiSelect.Click.MergeForward(chat, messages)
                        MultiSelectHandler.logger.info("click multi forward suceess")
                    } else {
                        MultiSelectHandler.logger.info("click multi forward failed")
                    }
                }
            )
            items.append(mergeForwardItem)
        }

        //逐条转发 统一PC使用 batch transmit
        var supportBatchTransmit = chat.chatMode != .threadV2 || scene == .threadPostForwardDetail
        if scene == .replyInThread {
            supportBatchTransmit = false
        }
        if supportBatchTransmit {
            let singleForwardItem = BottomMenuItem(
                type: .singleForward,
                name: BundleI18n.LarkMessageCore.Lark_Chat_OneByOneForwardButton,
                image: UDIcon.getIconByKey(.forwardOutlined),
                action: { [weak self] in
                    guard let `self` = self else { return }
                    // 单聊选中超过100条 需要给用户提示：最多只能选择100条消息
                    if !self.checkMultiselectEnable() { return }
                    if self.singleItemsForward(chat: chat) {
                        IMTracker.Msg.MultiSelect.Click.OnebyoneForward(chat, self.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])
                        MultiSelectHandler.logger.info("click batch transmit forward suceess")
                    } else {
                        MultiSelectHandler.logger.info("click batch transmit forward failed")
                    }
                }
            )
            items.append(singleForwardItem)
        }

        // 消息链接化
        if MessageLinkMessageActionSubModule.canCopyMessageLink(scene: scene, chat: chat, fg: self.userResolver.fg) {
            let messageLinkItem = BottomMenuItem(
                type: .messageLink,
                name: BundleI18n.LarkMessageCore.Lark_IM_CopyMessageLink_Button,
                image: UDIcon.getIconByKey(.blocklinkOutlined),
                action: { [weak self] in
                    self?.copyMessageLink(chat: chat)
                    IMTracker.Msg.MultiSelect.Click.CopyMessageLink(chat, self?.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])
                })
            items.append(messageLinkItem)
        }

        if navigationService?.checkInTabs(for: .todo) ?? false,
           !chat.isCrossWithKa,
           !chat.isSuper,
           !chat.isP2PAi,
           !chat.isPrivateMode {
            let createTodoItem = BottomMenuItem(
                type: .createTodo,
                name: BundleI18n.LarkMessageCore.Todo_Task_CreateATask,
                image: UDIcon.getIconByKey(.tabTodoOutlined),
                action: { [weak self] in
                    guard let self = self, let viewController = self.chatPageAPI else {
                        MultiSelectHandler.logger.info("click create todo failed")
                        return
                    }
                    if !self.checkMultiselectEnable() { return }
                    IMTracker.Msg.MultiSelect.Click.CreateTodo(chat, self.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])

                    let createTodo = { [weak self] in
                        guard let self = self else { return }
                        var messageIDs = [String]()
                        if let chatPageAPI = self.chatPageAPI {
                            messageIDs = chatPageAPI.selectedMessages.value.map(\.id)
                        }
                        self.clearMultiSelectStatus()
                        MultiSelectHandler.logger.info("click create todo succeed")

                        var threadId = ""
                        if self.scene == .threadDetail || self.scene == .threadPostForwardDetail || self.scene == .replyInThread {
                            threadId = message.threadId
                        }

                        var extra: [String: Any]?
                        if self.scene == .threadDetail || self.scene == .replyInThread {
                            extra = ["source": "topic", "sub_source": "topic_muilt_remmend"]
                        }
                        self.todoDependency?.createTodo(
                            from: viewController,
                            chat: chat,
                            threadId: threadId,
                            messageIDs: messageIDs,
                            extra: extra
                        )
                    }

                    DispatchQueue.main.async {
                        createTodo()
                    }

                }
            )
            items.append(createTodoItem)
        }

        // 创建 meego 工作项
        if dependency?.canDisplayCreateWorkItemEntrance(chat: chat, messages: messages, from: "muti_select") ?? false, !chat.isP2PAi {
            let createWorkItemInMeegoItem = BottomMenuItem(
                type: .createWorkItemInMeego,
                name: BundleI18n.LarkMessageCore.Lark_Project_Projects,
                image: BundleResources.meego) { [weak self] in
                guard let sourceVc = self?.chatPageAPI else { return }
                let selectedMessages = sourceVc.selectedMessages.value.compactMap({ $0.message }) ?? []
                self?.dependency?.createWorkItem(
                    with: chat,
                    messages: selectedMessages,
                    sourceVc: sourceVc,
                    from: "muti_select"
                )
            }
            items.append(createWorkItemInMeegoItem)
        }

        if !chat.isPrivateMode, !chat.isP2PAi {
            let mergeFavoriteItem = BottomMenuItem(
                type: .mergeFavorite,
                name: BundleI18n.LarkMessageCore.Lark_Legacy_CombineFavorite,
                image: UDIcon.getIconByKey(.collectionOutlined),
                action: { [weak self] in
                    guard let `self` = self else { return }
                    if !self.checkMultiselectEnable() { return }
                    if self.mergeFavorite(chat: chat) {
                        MultiSelectHandler.logger.info("click multi save suceess")
                        IMTracker.Msg.MultiSelect.Click.MultiSelectFavorite(chat, self.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])
                        self.clearMultiSelectStatus()
                    } else {
                        MultiSelectHandler.logger.info("click multi save failed")
                    }
                }
            )
            items.append(mergeFavoriteItem)
        }

        // KA菜单
        if !chat.isPrivateMode, !chat.isCrypto {
            let openMenuContext = OpenMessageMenuContext(chat: chat, menuType: .multi, messageInfos: [])
            let openMenuItems = openMenuItemFactory.getMenuItems(context: openMenuContext).filter({ $0.canInitialize(openMenuContext) })
            openMenuItems.forEach { item in
                let bottomItem = BottomMenuItem(type: .ka, name: item.text, image: item.icon) { [weak self] in
                    guard let self = self else { return }
                    guard !chat.enableRestricted(.copy), !chat.enableRestricted(.download), !chat.enableRestricted(.forward) else {
                        if let targetVC = self.chatPageAPI {
                            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_DownloadImagesVideosFilesNotAllow_Toast, on: targetVC.view)
                        }
                        return
                    }
                    let messageInfos = self.chatPageAPI?.selectedMessages.value.compactMap({ MessageInfo(id: $0.id, type: $0.type) }) ?? []
                    item.tapAction(OpenMessageMenuContext(chat: chat, menuType: .multi, messageInfos: messageInfos))
                    // 退出选中状态
                    self.clearMultiSelectStatus()
                }
                items.append(bottomItem)
            }
        }

        if AppConfigManager.shared.feature(for: .messageAction).isOn, !chat.isPrivateMode, !chat.isP2PAi {
            if scene == .newChat {
                let takeActionV2Item = BottomMenuItem(
                    type: .takeAction,
                    name: BundleI18n.LarkMessageCore.Lark_OpenPlatform_MsgScBttn,
                    image: UDIcon.getIconByKey(.keyboardOutlined),
                    action: { [weak self] in
                        guard let `self` = self else { return }
                        if !self.checkMultiselectEnable() { return }
                        guard let messages = self.chatPageAPI?.selectedMessages.value else { return }
                        let containsOnTimeDelMessage = messages.contains { $0.message?.isOnTimeDel ?? false }
                        guard !containsOnTimeDelMessage else {
                            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ActionFailedSelfDestructMessagesContained_Toast, on: self.chatPageAPI?.view ?? UIView())
                            return
                        }
                        IMTracker.Msg.MultiSelect.Click.FastAction(chat, self.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])
                        self.takeActionV2?(chat.id, messages.map { $0.id })
                    }
                )
                items.append(takeActionV2Item)
            }
        }

        if scene != .threadDetail, scene != .replyInThread, !chat.isP2PAi {
            // 删除
            let deleteItem = BottomMenuItem(
                type: .delete,
                name: BundleI18n.LarkMessageCore.Lark_Legacy_MenuDelete,
                image: UDIcon.getIconByKey(.deleteTrashOutlined),
                action: { [weak self] in
                    guard let `self` = self else { return }
                    if !self.checkMultiselectEnable() { return }
                    self.deleteMessages(chat: chat)
                }
            )
            items.append(deleteItem)
        }

        /// 如果是threadPostForwardDetail, 只需要[.mergeFoward, .singleForward, .mergeFavorite]
        if scene == .threadPostForwardDetail {
            let supportScene: [BottomMenuItemType] = [.mergeFoward, .singleForward, .mergeFavorite]
            items.removeAll { (item) -> Bool in
                return !supportScene.contains(item.type)
            }
        }
        let bottomView = BottomMenuBar(frame: CGRect.zero)
        bottomView.items = items

        if let superView = chatPageAPI?.view {
            superView.addSubview(bottomView)
            bottomView.snp.makeConstraints { (make) in
                make.bottom.left.right.equalToSuperview()
            }
            superView.layoutIfNeeded()
        }

        // 逐条转发按钮添加引导
        if let item = bottomView.getItemByType(.singleForward) {
            self.checkShowSingleForwardGuideIfNeeded(cutoutView: item)
        }

        // 退出多选模式时，删除bottomView，跳过第一个false
        var bag = DisposeBag()
        chatPageAPI?.inSelectMode
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak bottomView] inSelectMode in
                if !inSelectMode {
                    bag = DisposeBag()
                    bottomView?.removeFromSuperview()
                }
            })
            .disposed(by: bag)

        MenuTracker.trackMultiSelectEnter()
        IMTracker.Msg.MultiSelect.View(chat)
        chatPageAPI?.startMultiSelect(by: message.id)
    }

    private func checkShowSingleForwardGuideIfNeeded(cutoutView: UIView) {
        let item = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(cutoutView), arrowDirection: .down),
            textConfig: TextInfoConfig(
                detail: BundleI18n.LarkMessageCore.Lark_Chat_OneByOneForwardOnboardTip)
        )
        // 创建单个气泡的配置
        let singleBubbleConfig = SingleBubbleConfig(delegate: nil, bubbleConfig: item)
        newGuideManager?.showBubbleGuideIfNeeded(guideKey: Self.singleFowardGuideKey,
                                                 bubbleType: .single(singleBubbleConfig),
                                                 dismissHandler: nil)
     }

    private func checkMultiselectEnable() -> Bool {
        guard let chatPageAPI = self.chatPageAPI else { return false }

        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty {
            self.showMultiSelectAlert(message: BundleI18n.LarkMessageCore.Lark_Legacy_MultiSelectCountMinLimit)
            return false
        } else if messages.count > MultiSelectInfo.maxSelectedMessageLimitCount {
            self.showMultiSelectAlert(message: BundleI18n.LarkMessageCore.Lark_Legacy_MultiSelectTooManyMessagesTips)
            return false
        }
        return true
    }

    private func singleItemsForward(chat: Chat) -> Bool {
        // 图片和key
        guard let chatPageAPI = self.chatPageAPI else { return false }
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: chatPageAPI.view)
            return false
        }
        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty { return false }
        let pickedMessageIds = messages.map({ $0.id })
        let containBurnMessage = messages.contains(where: { $0.message?.isOnTimeDel == true })
        MenuTracker.trackMultiSelectQuickForwardClick(batchSelect: messages.contains(where: { ($0.extraInfo[MultiSelectInfo.followingMessageClickKey] as? Bool) ?? false }))
        //这里需要采用很合并转发一样的文案
        let title = self.gernateMergeMessageTitle(chat: chat)
        let body = BatchTransmitMessageBody(
            fromChannelId: chat.id,
            originMergeForwardId: chatPageAPI.originMergeForwardId(),
            messageIds: pickedMessageIds,
            title: title,
            traceChatType: self.getForwardAppReciableTrackChatType(chat: chat),
            supportToMsgThread: true,
            containBurnMessage: containBurnMessage,
            finishCallback: { [weak self] in
                self?.clearMultiSelectStatus()
            }
        )

        self.navigator.present(
            body: body,
            from: chatPageAPI,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
            completion: { _, res in
                guard let vc = res.resource as? UIViewController else {
                    return
                }
                if messages.contains(where: {
                    return $0.type == .audio
                }) {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_AudioMessagesCanBePlayedWhenForwarded_Toast,
                                        on: vc.view)
                }
            })
        return true
    }

    private func mergeForward(chat: Chat) -> Bool {
        guard let chatPageAPI = self.chatPageAPI else { return false }
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: chatPageAPI.view)
            return false
        }

        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty { return false }
        let pickedMessageIds = messages.map({ $0.id })
        let containBurnMessage = messages.contains(where: { $0.message?.isOnTimeDel == true })
        MenuTracker.trackMultiSelectForwardClick(batchSelect: messages.contains(where: { ($0.extraInfo[MultiSelectInfo.followingMessageClickKey] as? Bool) ?? false }))

        let title = self.gernateMergeMessageTitle(chat: chat)
        let body = MergeForwardMessageBody(
            originMergeForwardId: chatPageAPI.originMergeForwardId(),
            fromChannelId: chat.id,
            messageIds: pickedMessageIds,
            title: title,
            traceChatType: self.getForwardAppReciableTrackChatType(chat: chat),
            finishCallback: { [weak self] in
                self?.clearMultiSelectStatus()
            },
            needQuasiMessage: !messages.contains(where: { $0.message == nil }),
            supportToMsgThread: true,
            containBurnMessage: containBurnMessage
        )
        self.navigator.present(
            body: body,
            from: chatPageAPI,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        return true
    }

    private func copyMessageLink(chat: Chat) {
        guard let chatPageAPI = self.chatPageAPI, let targetView = chatPageAPI.view else { return }
        guard !chat.enableRestricted(.copy) else {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetView)
            return
        }
        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty { return }
        let copiedMessageIDs = messages.map({ $0.id })
        let fromID = MessageLinkMessageActionSubModule.getFromID(scene: scene, messages: chatPageAPI.selectedMessages.value.compactMap({ $0.message }), chat: chat)
        let from = MessageLinkMessageActionSubModule.getLinkFrom(scene: scene)

        UDToast.showLoading(on: targetView, disableUserInteraction: true)
        messageAPI?.putMessageLink(fromID: fromID, from: from, copiedIDs: copiedMessageIDs)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetView] response in
                guard let self = self else { return }
                // 成功之后退出选中状态
                self.clearMultiSelectStatus()
                let config = PasteboardConfig(token: Token("LARK-PSDA-messenger-chat-multiSelect-copyMessageLink-permission"))
                do {
                    try SCPasteboard.generalUnsafe(config).string = response.tokenURL
                    Self.logger.info("putMessageLink success: \(response.token)")
                    if let view = targetView {
                        UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkCopied_Toast, on: view)
                    }
                } catch {
                    // 复制失败兜底逻辑
                    Self.logger.error("PasteboardConfig init fail")
                    if let view = targetView {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkUnableCopy_Toast, on: view)
                    }
                }
            }, onError: { [weak targetView] error in
                Self.logger.error("putMessageLink failed", error: error)
                if let view = targetView {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkUnableCopy_Toast, on: view, error: error)
                }
            }).disposed(by: disposeBag)
    }

    private func gernateMergeMessageTitle(chat: Chat) -> String {
        switch chat.type {
        case .p2P:
            if chat.chatter?.id == self.currentChatter.id {
                return BundleI18n.LarkMessageCore.Lark_Legacy_ChatMergeforwardtitlebyoneside(chat.chatter?.displayName ?? "")
            } else {
                let myName = self.currentChatter.displayName
                let otherName = chat.chatter?.displayName ?? ""
                return BundleI18n.LarkMessageCore.Lark_Legacy_ChatMergeforwardtitlebytwoside(myName, otherName)
            }
        case .group, .topicGroup:
            return BundleI18n.LarkMessageCore.Lark_Legacy_ForwardGroupChatHistory
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkMessageCore.Lark_Legacy_ForwardGroupChatHistory
        }
    }

    private func mergeFavorite(chat: Chat) -> Bool {
        guard let chatPageAPI = self.chatPageAPI, let targetView = chatPageAPI.view else { return false }

        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty { return false }
        MenuTracker.trackMultiSelectFavoriteClick(batchSelect: messages.contains(where: { ($0.extraInfo[MultiSelectInfo.followingMessageClickKey] as? Bool) ?? false }))

        let supportType: [Message.TypeEnum] = [.post, .file, .folder, .text, .image, .sticker, .audio, .media, .location]
        if !messages.filter({ (message) -> Bool in
            return !supportType.contains(message.type)
        }).isEmpty {
            let tips = self.redPacketEnable ? BundleI18n.LarkMessageCore.Lark_Legacy_MultiMergeSaveAlert :
                BundleI18n.LarkMessageCore.Lark_IM_MultiMergeSaveAlert_NoRedPacket
            self.showMultiSelectAlert(message: tips)
            return false
        }

        let pickedMessageIds = messages.map({ $0.id })
        let chatId = chat.id

        UDToast.showLoading(on: targetView, disableUserInteraction: true)
        favoritesAPI?.mergeFavorites(chatId: chatId,
                                    originMergeForwardId: chatPageAPI.originMergeForwardId(),
                                    messageIds: pickedMessageIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak targetView] _ in
                guard let targetView = targetView else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_CombineFavoriteSuccess, on: targetView)
            }, onError: { [weak targetView] error in
                guard let targetView = targetView else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Legacy_SaveFavoriteFail,
                    on: targetView,
                    error: error
                )
            }).disposed(by: disposeBag)
        return true
    }

    private func deleteMessages(chat: Chat) {
        guard let chatPageAPI = self.chatPageAPI else { return }

        let messages = chatPageAPI.selectedMessages.value
        if messages.isEmpty { return }
        let pickedMessageIds = messages.map { $0.id }
        MenuTracker.trackMultiSelectDeleteClick(batchSelect: messages.contains(where: { ($0.extraInfo[MultiSelectInfo.followingMessageClickKey] as? Bool) ?? false }))
        let msgInfos = messages.map { ($0.id, $0.type) }
        IMTracker.Msg.DeleteConfirm.View(chat, msgInfos)
        guard let deleteMessageService = chatDeleteMessageService ?? self.deleteMessageService else { return }
        deleteMessageService.delete(messageIds: pickedMessageIds) { [weak self] (deleted) in
            guard let `self` = self else { return }
            if deleted {
                IMTracker.Msg.DeleteConfirm.Click(chat, msgInfos)
                IMTracker.Msg.MultiSelect.Click.Delete(chat, self.chatPageAPI?.selectedMessages.value.compactMap({ $0.message }) ?? [])
                self.clearMultiSelectStatus()
                MultiSelectHandler.logger.info("delete multi message")
            } else {
                MultiSelectHandler.logger.info("cancel delete multi message")
            }
        }
    }

    private func showMultiSelectAlert(message: String) {
        let alertController = LarkAlertController()
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Group_RevokeIKnow)
        chatPageAPI?.present(alertController, animated: true)
    }

    private func clearMultiSelectStatus() {
        MultiSelectHandler.logger.info("取消chatvc多选状态")
        chatPageAPI?.endMultiSelect()
    }

    private func getForwardAppReciableTrackChatType(chat: Chat) -> ForwardAppReciableTrackChatType {
        var traceChatType: ForwardAppReciableTrackChatType = .unknown
        switch scene {
        case .newChat:
            traceChatType = chat.type == .p2P ? .single : .group
        case .messageDetail:
            traceChatType = .threadDetail
        case .threadChat:
            traceChatType = .thread
        case .threadDetail, .replyInThread:
            traceChatType = .threadDetail
        case .mergeForwardDetail, .pin, .threadPostForwardDetail:
            break
        @unknown default:
            assert(false, "new value")
        }
        return traceChatType
    }
}
