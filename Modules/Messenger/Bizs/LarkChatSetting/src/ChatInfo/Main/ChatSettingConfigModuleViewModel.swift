//
//  ChatSettingConfigModuleViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/26.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkMessengerInterface
import LarkOpenFeed
import LKCommonsLogging
import EENavigator
import LarkSDKInterface
import LarkCore
import LarkAlertController
import LarkAccountInterface
import LarkReleaseConfig
import LarkFeatureGating
import LarkKAFeatureSwitch
import SuiteAppConfig
import LarkAccount
import LarkBadge
import UniverseDesignToast
import RustPB
import RxRelay
import LarkUIKit
import LarkActionSheet
import ThreadSafeDataStructure
import UniverseDesignActionPanel
import LarkOpenChat
import LarkOpenIM
import Swinject
import AppContainer
import LKCommonsTracker
import Homeric
import LarkTab
import LarkSetting
import LarkMessageCore

final class ChatSettingConfigModuleViewModel: ChatSettingModuleViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }
    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }
    var isOwner: Bool { return currentUserId == chat.ownerId }
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chat.isGroupAdmin
    }
    private var currentUserId: String {
        return self.userResolver.userID
    }
    var isMe: Bool {
        currentUserId == chat.chatterId
    }
    /// 是否有权限修改群头像
    private var hasAccess: Bool {
        return self.chat.isAllowPost && (isOwner || isGroupAdmin || !self.chat.offEditGroupChatInfo)
    }
    private static let logger = Logger.log(ChatSettingConfigModuleViewModel.self, category: "Module.IM.ChatInfo")
    var reloadSubject = PublishSubject<Void>()
    private(set) var disposeBag = DisposeBag()
    private var chat: Chat {
        get { _chat.value }
        set { _chat.value = newValue }
    }
    private var _chat: SafeAtomic<Chat>
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var chatService: ChatService?
    @ScopedInjectedLazy private var flagAPI: FlagAPI?
    private var pushChat: Observable<Chat>
    weak var targetVC: UIViewController?
    var pushCenter: PushNotificationCenter
    var showAlert: ((_ title: String, _ message: String) -> Void)?
    let hasModifyAccess: Bool
    private var nickname: String {
        get { _nickname.value }
        set { _nickname.value = newValue }
    }
    private lazy var _nickname: SafeAtomic<String> = {
        (currentChatterInChat?.nickName ?? "") + .readWriteLock
    }()
    var isThread: Bool {
        chat.chatMode == .threadV2
    }
    let chatSettingType: P2PChatSettingBody.ChatSettingType
    let hideFeedSetting: Bool
    private let schedulerType: SchedulerType
    private var startMeAtWhereText: String {
        if self.chat.chatMode != .threadV2 {
            return BundleI18n.LarkChatSetting.Lark_Chat_StartMeAtWhereILeftOff
        } else {
            return BundleI18n.LarkChatSetting.Lark_Legacy_StartMeAtTheFirstUnreadMessage
        }
    }
    private var currentChatterInChat: Chatter? {
        get { _currentChatterInChat.value }
        set { _currentChatterInChat.value = newValue }
    }
    private lazy var _currentChatterInChat: SafeAtomic<Chatter?> = {
        self.chatterManager?.currentChatter + .readWriteLock
    }()

    lazy var pushNickname: Observable<PushChannelNickname> = {
        pushCenter.observable(for: PushChannelNickname.self)
    }()
    private var isShowPersonalChatBgImage = false

    let currentChatterInChatOb: Observable<Chatter>
    @ScopedInjectedLazy private var feedAPI: FeedAPI?
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy private var feedMuteConfigService: FeedMuteConfigService?

    private lazy var tabModule: ChatTabModule = {
        let tabContainer = Container(parent: BootLoader.container)
        tabContainer.register(ChatOpenTabService.self) { [weak self] (_) -> ChatOpenTabService in
            return self?.tabsViewModel ?? DefaultChatOpenTabService()
        }
        let tabContext = ChatTabContext(parent: tabContainer, store: Store(),
                                        userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        ChatTabModule.onLoad(context: tabContext)
        ChatTabModule.registGlobalServices(container: tabContainer)
        let module = ChatTabModule(context: tabContext)
        return module
    }()
    private var tabModuleAleadySetup: Bool = false

    private lazy var tabsViewModel: ChatSettingTabsViewModel = {
        let viewModel = ChatSettingTabsViewModel(resolver: self.userResolver, chatId: Int64(self.chat.id) ?? 0)
        return viewModel
    }()

    init(resolver: UserResolver,
         chat: Chat,
         pushChat: Observable<Chat>,
         hasModifyAccess: Bool,
         schedulerType: SchedulerType,
         currentChatterInChatOb: Observable<Chatter>,
         pushCenter: PushNotificationCenter,
         hideFeedSetting: Bool,
         chatSettingType: P2PChatSettingBody.ChatSettingType,
         targetVC: UIViewController?) {
        self._chat = chat + .readWriteLock
        self.pushChat = pushChat
        self.targetVC = targetVC
        self.chatSettingType = chatSettingType
        self.hideFeedSetting = hideFeedSetting
        self.hasModifyAccess = hasModifyAccess
        self.pushCenter = pushCenter
        self.schedulerType = schedulerType
        self.currentChatterInChatOb = currentChatterInChatOb
        self.userResolver = resolver
    }

    func structItems() {
        var items: [CommonCellItemProtocol]
        items = [transferItems(),            // 转让群主
                 chatTabItem(),              // 添加群 tab
                 chatAddPinItem(),              // 添加置顶链接
                 groupSettingItem(),         // 群管理
                 nicknameItem(),             // 群昵称
                 muteItem(),                 // 免打扰
                 chatForbiddenItem(),        // 屏蔽机器人推送
                 chatBoxItem(),              // 会话盒子
                 atAllSilentItem(),          // @所有人不提醒
                 toTopItem(),                // 置顶
                 markForFlagItem(),          // 标记
                 autoTranslateItem(),        // 自动翻译
                 translateSetting(),         // 翻译设置
                 deleteMessagesItem(),       // 清空聊天记录
                 createCryptoGroupItem(),    // 创建密聊群组
                 personalChatBgImage()       // 个人聊天背景
        ].compactMap({ $0 })
        self.items = items
    }

    func startToObserve() {
        let chatId = chat.id
        let currentUserId = self.currentUserId

        let pushNicknameReloadOb = pushNickname
            .filter { $0.chatterId == currentUserId && $0.channelId == chatId }
            .map({ [weak self] push -> Void in
                self?.nickname = push.newNickname
            })

        // 获取当前用户角色
        let currentChatterInChatReloadOb = currentChatterInChatOb
            .map({ [weak self] chatter -> Void in
                self?.currentChatterInChat = chatter
                if let nickName = chatter.nickName {
                    self?.nickname = nickName
                }
            })

        let pushChatReloadOb = pushChat
            .filter { $0.id == chatId }
            .map({ [weak self] chat -> Void in
                self?.chat = chat
            })

        let getChatSwitch = self.chatAPI?.getChatSwitchWithLocalAndServer(chatId: self.chat.id,
                                                                          actionType: .personalChatTheme)
            .catchError({ error -> Observable<Bool?> in
                Self.logger.error("getChatThemeSwitch error", error: error)
                return .just(nil)
            })
            .filter({ [weak self] value -> Bool in
                guard let self = self, let value = value else { return false }
                if value != self.isShowPersonalChatBgImage {
                    self.isShowPersonalChatBgImage = value
                    return true
                }
                return false
            })
            .map({ _ in }) ?? .empty()

        // 100毫秒debounce过滤掉高频信号发射
        Observable.merge(pushNicknameReloadOb,
                         currentChatterInChatReloadOb,
                         pushChatReloadOb,
                         getChatSwitch)
            .debounce(.milliseconds(100), scheduler: schedulerType)
            .subscribe(onNext: { [weak self] _ in
                self?.structItems()
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }
}

// MARK: item方法
extension ChatSettingConfigModuleViewModel {
    // 转让群主的item
    func transferItems() -> CommonCellItemProtocol? {
        guard chat.isCrypto, hasModifyAccess, self.chat.type != .p2P, self.isOwner else { return nil }

        let transferItem = GroupSettingTransferItem(
            type: .transferGroup,
            cellIdentifier: GroupSettingTransferCell.lu.reuseIdentifier,
            style: .auto,
            title:
                BundleI18n.LarkChatSetting.Lark_Legacy_AssignGroupOwner
        ) { [weak self] _ in
            self?.transfer()
        }
        return transferItem
    }

    func deleteMessagesItem() -> CommonCellItemProtocol? {
        guard !isThread,
              !chat.isCrypto,
              !chat.isP2PAi,
              userResolver.fg.staticFeatureGatingValue(with: "messenger.chat.message.clear_history_message") else {
                  return nil
              }
        return GroupSettingDeleteMessagesItem(
            type: .deleteMessages,
            cellIdentifier: GroupSettingDeleteMessagesCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistory_Button
        ) { [weak self] cell in
            guard let targetVC = self?.targetVC, let self = self else {
                assertionFailure("can not find targetVC")
                return
            }
            let sourceView = cell
            let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
            let popSource = UDActionSheetSource(sourceView: sourceView,
                                                sourceRect: sourceRect)
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: popSource))
            actionSheet.setTitle(BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistory_Desc)
            actionSheet.addDestructiveItem(text: BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistory_ClearAllButton) { [weak self] in
                guard let self = self else { return }
                NewChatSettingTracker.imChatSettingDeleteMessagesConfirmClick(chat: self.chat)
                self.deleteMessages()
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistory_CancelButton)
            self.userResolver.navigator.present(actionSheet, from: targetVC)
            NewChatSettingTracker.imChatSettingDeleteMessagesClick(chat: self.chat)
            NewChatSettingTracker.imChatSettingDeleteMessagesConfirmView(chat: self.chat)
        }

    }

    func deleteMessages() {
        guard let view = self.targetVC?.viewIfLoaded else { return }
        let hud = UDToast.showLoading(on: view, disableUserInteraction: true)
        let chatId = self.chat.id
        self.chatAPI?.clearChatMessages(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let view = self?.targetVC?.viewIfLoaded {
                    hud.showSuccess(with: BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistory_SuccessToast, on: view)
                }
            }, onError: { [weak self] error in
                if let view = self?.targetVC?.viewIfLoaded {
                    hud.showFailure(with: BundleI18n.LarkChatSetting.Lark_IM_ClearAllChatHistoryFailed_Toast, on: view, error: error)
                }
                Self.logger.error("clear chat messages fail", additionalData: ["chatId": chatId], error: error)
            }).disposed(by: self.disposeBag)
    }

    func createCryptoGroupItem() -> CommonCellItemProtocol? {
        guard !chat.isCrypto,
              !isThread,
              !chat.isSuper,
              !chat.isPrivateMode,
              chat.type != .p2P,
              userResolver.fg.staticFeatureGatingValue(with: "im.chat.secure.create.from.chat.setting") else { return nil }
        let item = ChatInfoCreateCryptoGroupModel(
            type: .createCryptoGroup,
            cellIdentifier: ChatInfoCreateCryptoGroupCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_CreateSecureGroup_Button,
            tapHandler: { [weak self] _ in
                self?.createCryptoGroup()
            }
        )
        return item
    }

    private func createCryptoGroup() {
        guard let view = self.targetVC?.viewIfLoaded else { return }
        let hud = UDToast.showLoading(with: BundleI18n.LarkChatSetting.Lark_Legacy_CreatingGroup, on: view, disableUserInteraction: true)
        self.chatService?.createGroupChat(name: "",
                                          desc: "",
                                          chatIds: [],
                                          departmentIds: [],
                                          userIds: [],
                                          fromChatId: self.chat.id,
                                          messageIds: [],
                                          messageId2Permissions: [:],
                                          linkPageURL: nil,
                                          isCrypto: true,
                                          isPublic: false,
                                          isPrivateMode: false,
                                          chatMode: .default)
            .observeOn(MainScheduler.instance)
            .map { $0.chat }
            .subscribe(onNext: { [weak self] chat in
                guard let self = self, let targetVC = self.targetVC else { return }
                hud.remove()
                let from = WindowTopMostFrom(vc: targetVC)
                let body = ChatControllerByChatBody(chat: chat)
                var params = NaviParams()
                params.switchTab = Tab.feed.url
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
                ]
                self.userResolver.navigator.showAfterSwitchIfNeeded(
                    tab: Tab.feed.url,
                    body: body,
                    naviParams: params,
                    context: context,
                    wrap: LkNavigationController.self,
                    from: from
                )
            }, onError: { [weak self] error in
                if let view = self?.targetVC?.viewIfLoaded {
                    hud.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_CreateGroupError, on: view, error: error)
                }
                Self.logger.error("create crypto group fail", additionalData: ["chatId": self?.chat.id ?? ""], error: error)
            }).disposed(by: self.disposeBag)

    }

    // 群管理
    func groupSettingItem() -> CommonCellItemProtocol? {
        // 非密聊 & hasModifyAccess && 仅群主或者群管理员有群管理
        guard !chat.isCrypto, !chat.isFrozen, hasModifyAccess, self.isOwner || self.isGroupAdmin else { return nil }

        let chatId = chat.id
        return ChatInfoSettingModel(
            type: .groupManage,
            cellIdentifier: ChatInfoSettingCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupManagementSetting,
            badgePath: self.groupSetting,
            showBadge: !chat.isMeeting && chat.showApplyBadge
        ) { [weak self] _ in
            guard let vc = self?.targetVC, let self = self else {
                assertionFailure("missing targetVC")
                return
            }
            NewChatSettingTracker.imChatSettingClick(chat: self.chat,
                                                     myUserId: self.currentUserId,
                                                     isOwner: self.isOwner,
                                                     isAdmin: self.isGroupAdmin,
                                                     extra: ["click": "group_manage",
                                                             "target": "im_group_manage_view"
                                                     ])
            NewChatSettingTracker.imChatSettingManageClick(chatId: chatId)
            self.userResolver.navigator.push(body: GroupSettingBody(chatId: chatId), from: vc)
        }
    }

    func chatAddPinItem() -> CommonCellItemProtocol? {
        guard !chat.isFrozen,
              ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg) else {
                  return nil
              }

        let cellEnable: Bool = ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg)
        return ChatInfoAddPinModel(
            type: .chatAddPin,
            cellIdentifier: ChatInfoAddPinCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_NewPin_AddPinnedItem_Button,
            cellEnable: cellEnable
        ) { [weak self] _ in
            guard let targetVC = self?.targetVC, let self = self else {
                assertionFailure("can not find targetVC")
                return
            }
            if !cellEnable {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_IM_OnlyOwnerAdminCanManagePinnedItems_Toast, on: targetVC.view)
                return
            }
            let body = ChatAddPinBody(chat: self.chat, completion: nil)
            self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: targetVC)

        }
    }

    func chatTabItem() -> CommonCellItemProtocol? {
        guard !isThread,
              !chat.isOncall,
              !chat.isCrypto,
              !chat.isPrivateMode,
              !chat.isFrozen,
              !ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg),
              userResolver.fg.staticFeatureGatingValue(with: "im.chat.titlebar.tabs.202203") else {
                  return nil
              }
        if !self.tabModuleAleadySetup {
            self.tabModule.setup(ChatTabContextModel(chat: chat))
            self.tabsViewModel.loadData()
            self.tabModuleAleadySetup = true
        }

        let cellEnable: Bool = ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg)
        return ChatInfoAddTabModel(
            type: .chatAddTab,
            cellIdentifier: ChatInfoAddTabCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_AddTab_Button,
            cellEnable: cellEnable
        ) { [weak self] cell in
            guard let targetVC = self?.targetVC, let self = self else {
                assertionFailure("can not find targetVC")
                return
            }
            if !cellEnable {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_IM_Tabs_OnlyOwnerAdminCanManageTabsEnabled_Text, on: targetVC.view)
                return
            }

            let addTabAction = { [weak self] in
                guard let self = self, let targetVC = self.targetVC else { return }
                let body = ChatAddTabBody(
                    chat: self.chat,
                    completion: { [weak self] tabContent in
                        guard let self = self, let targetVC = self.targetVC else { return }
                        targetVC.presentedViewController?.dismiss(animated: true)
                        let nav = targetVC.navigationController
                        /// 产品要求需要从会话页面打开新添加的标签页
                        let body = ChatControllerByChatBody(chat: self.chat)
                        self.userResolver.navigator.push(
                            body: body,
                            from: targetVC,
                            animated: false,
                            completion: { _, _ in
                                guard let nav = nav else { return }
                                self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat, content: tabContent, targetVC: nav))
                            }
                        )
                    }
                )
                self.userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: targetVC,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                )
            }
            let addedTabTypes = Set(self.tabsViewModel.dataSource?.tabs.map { $0.type } ?? [])
            let entrys = self.tabModule.getChatAddTabEntry(ChatTabContextModel(chat: self.chat)).filter { entry in
                !addedTabTypes.contains(entry.type)
            }
            if entrys.isEmpty {
                addTabAction()
                return
            }
            let sourceView = cell
            let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
            let popSource = UDActionSheetSource(sourceView: sourceView,
                                                sourceRect: sourceRect)
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
            entrys.forEach { entry in
                actionSheet.addDefaultItem(text: entry.title) { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    self.tabModule.beginAddTab(metaModel: ChatAddTabMetaModel(chat: self.chat,
                                                                              type: entry.type,
                                                                              targetVC: targetVC,
                                                                              extraInfo: ChatAddTabMetaModel.ExtraInfo(event: Homeric.IM_GROUP_MANAGE_CLICK, params: [:])))
                }
            }
            actionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_IM_AddTab_Button) { [weak self] in
                guard let self = self else { return }
                addTabAction()
                NewChatSettingTracker.imGroupManageClick(
                    chat: self.chat,
                    myUserId: self.currentUserId,
                    isOwner: self.isOwner,
                    isAdmin: self.isGroupAdmin,
                    clickType: "tab_add",
                    extra: ["target": "im_chat_doc_page_add_view",
                            "location": "setting"]
                )
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
            self.userResolver.navigator.present(actionSheet, from: targetVC)
        }
    }

    // 昵称
    func nicknameItem() -> CommonCellItemProtocol? {
        guard self.hasModifyAccess else { return nil }
        // 客服群不支持群昵称
        guard !chat.isOncall, chat.type != .p2P else { return nil }

        //如果是超大群，且fg关闭，屏蔽群昵称
        if self.chat.isSuper, !userResolver.fg.staticFeatureGatingValue(with: "lark.messenger.supergroup.petname") {
             return nil
        }
        let chat = self.chat
        return ChatInfoNickNameModel(
            type: .nickName,
            cellIdentifier: ChatInfoNickNameCell.lu.reuseIdentifier,
            style: .auto,
            title:
                BundleI18n.LarkChatSetting.Lark_Legacy_AliasInGroup,
            name: self.nickname
        ) { [weak self] _ in
            guard let self = self else { return }
            guard let vc = self.targetVC else {
                assertionFailure("missing targetVC")
                return
            }
            NewChatSettingTracker.imChatSettingManageClick(chatId: chat.id)
            NewChatSettingTracker.imChatSettingAliasClick(chat: chat)
            let body = ModifyNicknameBody(
                chat: chat,
                chatId: chat.id,
                oldNickname: self.nickname,
                title:
                    BundleI18n.LarkChatSetting.Lark_Legacy_PersoncardGroupalias,
                saveNickName: { newName in
                    ChatSettingTracker.trackEditNickNameSave(chat: chat, newName: newName)
                }
            )
            self.userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: vc,
                                     prepare: { $0.modalPresentationStyle = .formSheet },
                                     animated: true)
        }
    }

    // 会话盒子
    func chatBoxItem() -> CommonCellItemProtocol? {
        let chat = self.chat
        if chat.isRemind { return nil } // 非消息提醒状态下不展示会话盒子
        let isChatMuteable = chat.muteable
        if chat.type == .p2P {
            if isMe || !isChatMuteable {
                return nil
            }
        } else {
            guard self.hasModifyAccess else { return nil }
            // 客服群不支持CheckBox
            // code_next_line tag CryptChat
            if hideFeedSetting { return nil }
        }
        let title = BundleI18n.LarkChatSetting.Lark_Core_MoveChatsIntoCollapsedChats_Settings
        let descriptionText = BundleI18n.LarkChatSetting.Lark_Core_MoveChatsIntoCollapsedChats_SettingsDesc

        return ChatInfoChatBoxModel(
            type: .chatBox,
            cellIdentifier: ChatInfoChatBoxCell.lu.reuseIdentifier,
            style: .auto,
            title: title,
            descriptionText: descriptionText,
            status: chat.isInBox,
            cellEnable: true
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            NewChatSettingTracker.imChatSettingChatBoxSwitch(isOn: isOn, chat: self.chat, isAdmin: self.isOwner, myUserId: self.currentUserId)
            self.moveToBoxControlDidChanged(state: isOn)
        }
    }

    // 自动翻译
    func autoTranslateItem() -> CommonCellItemProtocol? {
        if userResolver.fg.staticFeatureGatingValue(with: "im.chat.manual_open_translate") {
            //fg开的时候这个item位置有调整
            return nil
        }
        let chat = self.chat
        guard !chat.isCrypto, !chat.isPrivateMode, !isMe, hasModifyAccess, userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else {
            return nil
        }

        var item: CommonCellItemProtocol?
        // 密聊不支持自动翻译
        // code_next_line tag CryptChat
        if !self.chat.isCrypto {
            item = ChatInfoAutoTranslateModel(
                type: .autoTranslate,
                cellIdentifier: ChatInfoAutoTranslateCell.lu.reuseIdentifier,
                style: .auto,
                title: BundleI18n.LarkChatSetting.Lark_Legacy_AutoTranslation,
                descriptionText: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoGroupAutotranslateDescription,
                status: self.chat.isAutoTranslate
            ) { [weak self] (_, isOn) in
                NewChatSettingTracker.imChatSettingAutoTranslationSwitch(isOn: isOn, isAdmin: self?.isOwner ?? false, chat: chat)
                self?.toAutoTranslateControlDidChanged(state: isOn)
            }
        }
        return item
    }

    /// 个人聊天背景设置
    func personalChatBgImage() -> CommonCellItemProtocol? {
        guard isShowPersonalChatBgImage else { return nil }
        // 密聊/密盾聊/话题群 不支持更换聊天背景
        if self.chat.isCrypto || self.chat.isPrivateMode || self.chat.chatMode == .threadV2 { return nil }
        return ChatInfoPersonalChatBgImageItem(
            type: .personalChatBgImage,
            cellIdentifier: ChatInfoPersonalChatBgImageCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_PersonalWallpaper_Button
        ) { [weak self] _ in
            guard let `self` = self else { return }
            guard let vc = self.targetVC else {
                assertionFailure("missing targetVC")
                return
            }
            ChatSettingTracker.imChatSettingClickChatBackground(chat: self.chat)
            let body = ChatThemeBody(chatId: self.chat.id,
                                     title: BundleI18n.LarkChatSetting.Lark_IM_PersonalWallpaper_Button,
                                     scene: .personal)
            self.userResolver.navigator.push(body: body, from: vc)
        }
    }

    func translateSetting() -> CommonCellItemProtocol? {
        guard userResolver.fg.staticFeatureGatingValue(with: "im.chat.manual_open_translate"),
              !chat.isCrypto,
              !chat.isPrivateMode else { return nil }
        let chat = self.chat
        let item = ChatInfoTranslateSettingItem(
            type: .translateSetting,
            cellIdentifier: ChatInfoTranslateSettingCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_TranslationAssistantSettings_Title,
            tapHandler: { [weak self] _ in
                guard let `self` = self else { return }
                guard let vc = self.targetVC else {
                    assertionFailure("missing targetVC")
                    return
                }
                NewChatSettingTracker.trackTranslateSetting(chat: chat)
                let body = ChatTranslateSettingBody(chat: chat, pushChat: self.pushChat)
                self.userResolver.navigator.push(body: body, from: vc)
            }
        )
        return item
    }

    // 免打扰
    func muteItem() -> CommonCellItemProtocol? {
        let chat = self.chat
        let isChatMuteable = chat.muteable
        if chat.type == .p2P {
            guard !isMe, isChatMuteable else { return nil }
        } else {
            guard self.hasModifyAccess, !hideFeedSetting else { return nil }
        }
        return ChatInfoNotificationModel(
            type: .mute,
            cellIdentifier: ChatInfoMuteCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Core_MuteNotifications_ToggleButton,
            descriptionText: userResolver.fg.staticFeatureGatingValue(with: "messager.bot.p2p_chat_mute") ?
            BundleI18n.LarkChatSetting.Lark_Msg_MuteCheckboxDesc : "",
            status: !self.chat.isRemind
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            NewChatSettingTracker.imChatSettingMuteSwitch(isOn: isOn, chat: self.chat, isAdmin: self.isOwner, myUserId: self.currentUserId)
            self.muteControlDidChanged(state: isOn)
        }
    }

    // 标记
    func markForFlagItem() -> CommonCellItemProtocol? {
        if self.chat.isPrivateMode { return nil }
        return ChatInfoMarkForFlagModel(
            type: .flag,
            cellIdentifier: ChatInfoMarkForFlagCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_MarkAChatToArchive_Settings,
            descriptionText: "",
            status: self.chat.isFlaged
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            // 埋点
            let status = isOn ? "on" : "off"
            var params: [AnyHashable: Any] = [ "click": "mark",
                                               "target": "none",
                                               "status": status]
            params += IMTracker.Param.chat(self.chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
            self.flagControlDidChanged(state: isOn)
        }
    }

    // @所有人不提醒
    func atAllSilentItem() -> CommonCellItemProtocol? {
        if self.chat.type != .group { return nil }

        return ChatInfoAtAllSilentModel(
            type: .atAllSilent,
            cellIdentifier: ChatInfoAtAllSilentCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Core_MuteMentionAll_ToggleButton,
            descriptionText: "",
            status: self.chat.isMuteAtAll
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            NewChatSettingTracker.imChatSettingMuteAtAllSwitch(isOn: isOn, chat: self.chat, isAdmin: self.isOwner, myUserId: self.currentUserId)
            self.atAllSilentControlDidChanged(state: isOn)
        }
    }

    // 置顶
    func toTopItem() -> CommonCellItemProtocol? {
        guard Feature.shortcutEnabled else {
            Self.logger.info("[chat setting] shortcut disable")
            return nil
        }
        let chat = self.chat
        if chat.type == .p2P {
        } else {
            guard self.hasModifyAccess, !hideFeedSetting else { return nil }
        }
        return ChatInfoToTopModel(
            type: .toTop,
            cellIdentifier: ChatInfoToTopCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_PinChatToTop_Toggle,
            descriptionText: "",
            status: self.chat.isShortCut
        ) { [weak self] (_, isOn) in
            NewChatSettingTracker.imChatSettingQuickswitcherSwitch(isOn: isOn, isAdmin: self?.isOwner ?? false, chat: chat)
            self?.toTopControlDidChanged(state: isOn)
        }
    }

    //屏蔽机器人
    func chatForbiddenItem() -> CommonCellItemProtocol? {
        guard userResolver.fg.staticFeatureGatingValue(with: "messager.bot.p2p_chat_mute") else { return nil }
        guard chat.type == .p2P && chat.chatter?.type == .bot else { return nil }
        let status = self.chat.chatter?.botForbiddenInfo?.mutedScenes["p2p_chat"] ?? false
        return ChatInfoBotForbiddenModel(
            type: .botForbidden,
            cellIdentifier: ChatInfoBotForbiddenCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_BotMsg_ReceiveMsgCheckbox,
            descriptionText: BundleI18n.LarkChatSetting.Lark_BotMsg_ReceiveMsgCheckboxDesc,
            status: !status
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            self.botForbiddenDidChanged(state: !isOn)
        }
    }
}

// MARK: 工具方法
extension ChatSettingConfigModuleViewModel {
    func transfer() {
        ChatSettingTracker.newTrackTransferClick(source: .manageGroup, chatId: chat.id, chat: self.chat)

        if chat.chatterCount <= 1 {
            let title = BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner
            let content = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoTransferOnlyownerContent
            self.showAlert?(title, content)
            return
        }
        var body = TransferGroupOwnerBody(chatId: self.chat.id,
                                          mode: .assign,
                                          isThread: self.isThread)
        let chat = self.chat
        body.lifeCycleCallback = { [weak self] res in
            ChatSettingTracker.trackTransmitChatOwner(chat: chat, source: .chatExit)
            switch res {
            case .before:
                ChatSettingTracker.trackTransmitChatOwner(chat: chat, source: .chatManage)
            case .success:
                if let view = self?.targetVC?.viewIfLoaded {
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwnerSuccess, on: view)
                }
            case .failure(let error, let newOwnerId):
                if let error = error.underlyingError as? APIError, let window = self?.targetVC?.currentWindow() {
                    switch error.type {
                    case .transferGroupOwnerFailed(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        if !error.displayMessage.isEmpty {
                            UDToast.showFailure(with: error.displayMessage, on: window)
                        } else {
                            UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwnerFailed,
                                                   on: window,
                                                   error: error)
                        }
                    }
                }
                Self.logger.error(
                    "transfer group owner failed!",
                    additionalData: ["chatId": chat.id, "newOwnerId": newOwnerId],
                    error: error
                )
            }
        }

        guard let vc = self.targetVC else {
            Self.logger.info("missing jump targetVC")
            assertionFailure("missing jump targetVC")
            return
        }
        if Display.phone {
            self.userResolver.navigator.push(body: body, from: vc)
        } else {
            self.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { vc in
                    vc.modalPresentationStyle = LarkCoreUtils.formSheetStyle()
                }
            )
        }
    }

    // rusult parse
    func parsingUserOperation<T>(
        _ result: Observable<T>,
        logMessage: String,
        succeedMessage: String? = nil,
        errorMessage: String? = nil,
        errorHandler: (() -> Void)? = nil
    ) {
        let chatId = self.chat.id
        result.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            if let succeedMessage = succeedMessage, let view = self.targetVC?.viewIfLoaded {
                UDToast.showSuccess(with: succeedMessage, on: view)
            }
        }, onError: { [weak self] (error) in
            Self.logger.error(
                logMessage,
                additionalData: ["chatId": chatId],
                error: error)
            errorHandler?()
            guard let view = self?.targetVC?.viewIfLoaded else { return }
            if let errorMessage = errorMessage {
                UDToast.showFailure(with: errorMessage, on: view, error: error)
            } else {
                UDToast.showFailureIfNeeded(on: view, error: error)
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - 置顶
    func toTopControlDidChanged(state: Bool) {
        guard let feedAPI = feedAPI else {
            return
        }
        let chatId = chat.id
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chatId
        channel.type = .chat

        var shortcut = RustPB.Feed_V1_Shortcut()
        shortcut.channel = channel
        if state {
            ChatSettingTracker.trackAddShortCut(chatId: chatId, isThread: isThread)
            ChatSettingTracker.trackTopSet(true)
            parsingUserOperation(
                feedAPI.createShortcuts([shortcut]),
                logMessage: "modify shortcut failed",
                errorMessage: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoSetShortcutFailed) { [weak self] in
                    self?.reloadSubject.onNext(())
            }
        } else {
            ChatSettingTracker.trackRemoveShortCut(chatId: chatId)
            ChatSettingTracker.trackTopSet(false)
            parsingUserOperation(
                feedAPI.deleteShortcuts([shortcut]),
                logMessage: "modify shortcut failed",
                errorMessage: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoSetShortcutFailed) { [weak self] in
                    self?.reloadSubject.onNext(())
            }
        }
    }

    // MARK: - 会话盒子
    func moveToBoxControlDidChanged(state: Bool) {
        guard let feedAPI = feedAPI, let feedMuteConfigService = self.feedMuteConfigService else {
            return
        }
        let chatId = chat.id
        if state {
            ChatSettingTracker.trackSetFeedCardsIntoBox(
                type: "group",
                from: "group_setting",
                chatId: chatId,
                isMute: !chat.isRemind
            )
            var succeedMessage: String?
            if feedMuteConfigService.addMuteGroupEnable(), feedMuteConfigService.getShowMute() {
                succeedMessage = BundleI18n.LarkChatSetting.Lark_Core_MoveChatsIntoCollapsedChats_Settings
            }
            parsingUserOperation(
                feedAPI.setFeedCardsIntoBox(feedCardId: chatId),
                logMessage: "setFeedCardsIntoBox failed",
                succeedMessage: succeedMessage) { [weak self] in
                    self?.reloadSubject.onNext(())
            }
        } else {
            ChatSettingTracker.trackDeleteFeedCardsFromBox(
                type: "group",
                from: "group_setting",
                notification: false,
                chatId: chatId
            )
            parsingUserOperation(
                feedAPI.deleteFeedCardsFromBox(feedCardId: chatId, isRemind: false),
                logMessage: "deleteFeedCardsFromBox failed") { [weak self] in
                    self?.reloadSubject.onNext(())
            }
        }
    }

    // MARK: - 免打扰
    func muteControlDidChanged(state: Bool) {
        guard let chatAPI = self.chatAPI, let feedMuteConfigService = self.feedMuteConfigService else {
            return
        }
        ChatSettingTracker.trackChat(mute: state, chat: chat)
        var succeedMessage: String?
        if feedMuteConfigService.addMuteGroupEnable(), state, feedMuteConfigService.getShowMute() {
            succeedMessage = BundleI18n.LarkChatSetting.Lark_Feed_MovedToMutedToast
        }
        parsingUserOperation(
            chatAPI.updateChat(chatId: self.chat.id, isRemind: !state),
            logMessage: "modify group notification failed",
            succeedMessage: succeedMessage,
            errorMessage: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoSetReminderFailed) { [weak self] in
                self?.structItems()
                self?.reloadSubject.onNext(())
        }
    }

    // MARK: - 标记
    func flagControlDidChanged(state: Bool) {
        guard let flagAPI = self.flagAPI else {
            return
        }
        parsingUserOperation(
            flagAPI.updateChat(isFlaged: state, chatId: self.chat.id),
            logMessage: "mark for flag failed") { [weak self] in
                self?.reloadSubject.onNext(())
        }
    }

    // MARK: - @所有人不提醒
    func atAllSilentControlDidChanged(state: Bool) {
        guard let chatAPI = self.chatAPI else {
            return
        }
        parsingUserOperation(
            chatAPI.updateChat(chatId: self.chat.id, isMuteAtAll: state),
            logMessage: "at all silent failed") { [weak self] in
                self?.reloadSubject.onNext(())
        }
    }

    // MARK: - 自动翻译
    func toAutoTranslateControlDidChanged(state: Bool) {
        let chatId = chat.id
        self.chatAPI?.updateChat(chatId: chatId, isAutoTranslate: state)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                self?.chat = chat
            }, onError: { [weak self](error) in
                /// 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkChatSetting.Lark_Setting_PrivacySetupFailed
                if let view = self?.targetVC?.viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }

                Self.logger.error("", additionalData: ["chatId": chatId], error: error)
                self?.reloadSubject.onNext(())
            }).disposed(by: self.disposeBag)
    }

    func changeEnterMessagePoistion(_ position: LarkModel.Chat.MessagePosition.Enum) {
        guard let chatAPI = self.chatAPI else {
            return
        }
        NewChatSettingTracker.imChatSettingStartFromMsgSetting(position: position, isAdmin: self.isOwner, chat: chat)
        parsingUserOperation(
            chatAPI.updateChat(chatId: chat.id, messagePosition: position),
            logMessage: "change enter chat 'Message position' failed")
    }

    // MARK: - 屏蔽机器人消息
    private func botForbiddenDidChanged(state: Bool) {
        let chatter = self.chat.chatter
        var botMutedInfo = Basic_V1_Chatter.BotMutedInfo()
        botMutedInfo.mutedScenes = ["p2p_chat": state]
        self.chatterAPI?.updateBotForbiddenState(chatterId: chatter?.id ?? "", botMuteInfo: botMutedInfo)
            .subscribe().disposed(by: self.disposeBag)
    }
}

extension ChatSettingConfigModuleViewModel {
    // LarkBadg 显示Badge
    private var setting: Path {
        return Path().prefix(Path().chat_id, with: chat.id).chat_more.setting
    }

    private var groupSetting: Path { return setting.group_setting }
}

// 精简模式
extension Feature {
    static var shortcutEnabled: Bool {
        getConfigValueWithLog("feed.shortcut")
    }
}

extension Feature {
    static func getConfigValueWithLog(_ key: String) -> Bool {
        let enable = AppConfigManager.shared.feature(for: key).isOn
        return enable
    }
}
