//
//  ChatTabsViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/3/23.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkContainer
import LarkCore
import RustPB
import LarkModel
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import UniverseDesignActionPanel
import UniverseDesignToast
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import Homeric
import UniverseDesignMenu
import UniverseDesignIcon
import LarkTraitCollection
import LarkFeatureGating
import LarkAccountInterface
import LarkBadge
import ByteWebImage
import LarkSetting

final class ChatTabsViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatTabsViewModel.self, category: "Module.IM.ChatTab")
    private let disposeBag = DisposeBag()
    private let chat: BehaviorRelay<Chat>
    private let chatId: Int64
    private let tabModule: ChatTabModule
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var guideService: ChatTabsGuideService?
    private var dataSource: [ChatTabContent] = []
    private let dataProcessQueue = DispatchQueue(label: "messenger.chat.tabs", qos: .userInteractive)
    private var messagesRendered: Bool = false

    private var tabRefreshPublish: PublishSubject<(tabs: [ChatTabContent], isHidden: Bool)> = PublishSubject<(tabs: [ChatTabContent], isHidden: Bool)>()
    lazy var tabRefreshDriver: Driver<Bool> = {
        return tabRefreshPublish
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (tabs, isHidden) -> Observable<Bool> in
                guard let self = self else { return .empty() }
                self.dataSource = tabs
                if self.messagesRendered {
                    self.dataSource.forEach { tab in
                        self.tabModule.preload(metaModel: ChatTabMetaModel(chat: self.chat.value, type: tab.type, content: tab))
                    }
                }
                return .just(isHidden)
            }
            .filter { [weak self] _ in
                guard let self = self else { return false }
                /// 这里先特化处理，pin tab count 未获取前不刷新 UI，防止因为 count 后来导致的 UI 抖动
                /// 后续会将 count 挂到 Tab 实体上
                if self.dataSource.contains(where: { $0.type == .pin }), !self.tabPinService.aleadySetup {
                    return false
                }
                return true
            }
            .asDriver(onErrorRecover: { _ in Driver<Bool>.empty() })
    }()

    private lazy var tabPinService: ChatTabPinService = {
        let tabPinService = ChatTabPinService(userResolver: userResolver, pinBadgePath: self.tabModule.getBadgePath(ChatTabMetaModel(chat: self.chat.value, type: .pin)),
                                              context: self.tabModule.context) { [weak self] in
            guard let self = self else { return }
            let tabs = self.dataSource
            self.tabRefreshPublish.onNext((tabs: tabs, isHidden: tabs.count < 2))
        }
        return tabPinService
    }()
    lazy var canManageTab: BehaviorRelay<(Bool, String?)> = BehaviorRelay<(Bool, String?)>(value: (true, nil))
    private let chatFromWhere: ChatFromWhere

    private weak var targetVC: UIViewController?

    init(userResolver: UserResolver, chat: BehaviorRelay<Chat>, tabModule: ChatTabModule, targetVC: UIViewController, chatFromWhere: ChatFromWhere) {
        self.userResolver = userResolver
        self.targetVC = targetVC
        self.chat = chat
        self.chatId = Int64(chat.value.id) ?? 0
        self.tabModule = tabModule
        tabModule.setup(ChatTabContextModel(chat: chat.value))
        self.chatFromWhere = chatFromWhere
        self.chat
            .observeOn(MainScheduler.instance)
            .map { [weak self] chat -> (Bool, String?) in
                let canManageTab = self?.checkPermissionForManageTab(chat) ?? (false, nil)
                Self.logger.info("check tab permission \(chat.id) \(canManageTab.0) \(chat.chatTabPermissionSetting)")
                return canManageTab
            }
            .bind(to: self.canManageTab).disposed(by: disposeBag)
    }

    func initTabs(tabsObservable: Observable<RustPB.Im_V1_GetChatTabsResponse>,
                  getBufferPushTabs: () -> (tabs: [RustPB.Im_V1_ChatTab], version: Int64)?,
                  pushTabsObservable: Observable<PushChatTabs>) {
        tabsObservable
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                Self.logger.info("init tabs \(res.tabs.count) version: \(res.version) chatId: \(self.chatId)")
                self.handleTabs(res.tabs, newVersion: res.version)
            }, onError: { error in
                Self.logger.error("can not get tabs", error: error)
            }).disposed(by: disposeBag)
        let chatId = self.chatId
        pushTabsObservable
            .filter { $0.chatId == chatId }
            .subscribe(onNext: { [weak self] (push) in
                self?.handleTabs(push.tabs, newVersion: push.version)
            }).disposed(by: self.disposeBag)
        if let pushTabs = getBufferPushTabs() {
            Self.logger.info(" handle buffer push tabs \(pushTabs.tabs.count) version: \(pushTabs.version) chatId: \(self.chatId)")
            self.handleTabs(pushTabs.tabs, newVersion: pushTabs.version)
        }
    }

    private var version: Int64?
    private func handleTabs(_ tabs: [ChatTabContent], newVersion: Int64) {
        dataProcessQueue.async {
            self.adjustTabPinInfo(tabs)
            if let version = self.version, version >= newVersion { return }
            self.version = newVersion
            let chat = self.chat.value
            let visibleTabs = tabs.filter { tab in
                return self.tabModule.checkVisible(metaModel: ChatTabMetaModel(chat: chat, type: tab.type, content: tab))
            }
            self.tabRefreshPublish.onNext((tabs: visibleTabs, isHidden: visibleTabs.count < 2))
        }
    }

    private func adjustTabPinInfo(_ tabs: [ChatTabContent]) {
        guard tabs.contains(where: { $0.type == .pin }) else { return }
        DispatchQueue.main.async {
            self.tabPinService.setupCountAndBadgeIfNeeded(chatId: "\(self.chatId)")
        }
    }

    func findNeedShowGuideTabId() -> Int64? {
        return self.dataSource.first(where: { ChatTabModule.guideWhiteList.contains($0.type) })?.id
    }

    func transformToTabTitleModels() -> [ChatTabTitleModel] {
        return self.dataSource.map { tab -> ChatTabTitleModel in
            let metaModel = ChatTabMetaModel(chat: self.chat.value, type: tab.type, content: tab)
            return ChatTabTitleModel(
                tabId: tab.id,
                title: self.tabModule.getTabTitle(metaModel),
                isSelected: tab.type == .message,
                imageResource: self.tabModule.getImageResource(metaModel),
                badgePath: self.tabModule.getBadgePath(metaModel),
                count: self.getTabCount(metaModel)
            )
        }
    }

    private func getTabCount(_ metaModel: ChatTabMetaModel) -> Int? {
        // 这里先特化处理
        guard metaModel.type == .pin else { return nil }
        if self.tabPinService.pinCount == 0 { return nil }
        return self.tabPinService.pinCount
    }

    private func addTab(result: Result<ChatTabContent, Error>) {
        guard let targetVC = self.targetVC else { return }
        switch result {
        case .success(_):
            break
        case .failure(let error):
            UDToast.showFailure(with: error.localizedDescription, on: targetVC.view)
        }
    }

    private func checkPermissionForManageTab(_ chat: Chat) -> (Bool, String?) {
        if chat.isFrozen {
            return (false, BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast)
        }
        if ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg) {
            return (true, nil)
        } else {
            return (false, BundleI18n.LarkChat.Lark_IM_Tabs_OnlyOwnerAdminCanManageTabsEnabled_Text)
        }
    }
}

extension ChatTabsViewModel: ChatOpenTabService {
    func addTab(type: ChatTabType, name: String, jsonPayload: String?, success: ((ChatTabContent) -> Void)?, failure: ((Error, ChatTabType) -> Void)?) {
        self.chatAPI?.addChatTab(chatId: self.chatId, name: name, type: type, jsonPayload: jsonPayload)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.handleTabs(response.tabs, newVersion: response.version)
                if let newTab = response.tabs.first(where: { $0.id == response.newTabID }) {
                    success?(newTab)
                    self.addTab(result: .success(newTab))
                } else {
                    assertionFailure("can not find new tab")
                }
            }, onError: { [weak self] error in
                Self.logger.error("add tab failed", error: error)
                failure?(error, type)
                self?.addTab(result: .failure(error))
            }).disposed(by: disposeBag)
    }

    func updateChatTabDetail(tab: ChatTabContent, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error) -> Void)?) {
        let updateId = tab.id
        self.chatAPI?.updateChatTabDetail(chatId: self.chatId, tab: tab)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.handleTabs(response.tabs, newVersion: response.version)
                if let updateTab = response.tabs.first(where: { $0.id == updateId }) {
                    success?(updateTab)
                } else {
                    assertionFailure("can not find updated tab")
                }
            }, onError: { error in
                Self.logger.error("update tab failed", error: error)
                failure?(error)
            }).disposed(by: disposeBag)
    }

    func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController) {
        self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tab, targetVC: targetVC))
    }

    func getTab(id: Int64) -> ChatTabContent? {
        return self.dataSource.first(where: { $0.id == id })
    }
}

extension ChatTabsViewModel: AfterFirstScreenMessagesRenderDelegate {
    func afterMessagesRender() {
        messagesRendered = true
        self.dataSource.forEach { tab in
            self.tabModule.preload(metaModel: ChatTabMetaModel(chat: self.chat.value, type: tab.type, content: tab))
        }
    }

    var viewParams: [AnyHashable: Any] {
        return ["have_tab": self.dataSource.count > 1 ? "true" : "false",
                "is_enabled_red_dot": self.tabPinService.trackShowBadge]
    }
}

extension ChatTabsViewModel: ChatTabsTitleRouter {
    func clickAdd(_ button: UIButton) {
        guard let targetVC = self.targetVC else { return }
        if !self.canManageTab.value.0 {
            UDToast.showTips(with: self.canManageTab.value.1 ?? "", on: targetVC.view)
            return
        }
        let sourceView = button
        let sourceRect: CGRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        let popSource = UDActionSheetSource(sourceView: sourceView,
                                            sourceRect: sourceRect)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))

        var addedTabTypes: Set<ChatTabType> = Set(self.dataSource.map { $0.type })
        let entrys = self.tabModule.getChatAddTabEntry(ChatTabContextModel(chat: self.chat.value)).filter { entry in
            !addedTabTypes.contains(entry.type)
        }
        entrys.forEach { entry in
            actionSheet.addDefaultItem(text: entry.title) { [weak self] in
                guard let self = self, let targetVC = self.targetVC else { return }
                self.tabModule.beginAddTab(metaModel: ChatAddTabMetaModel(chat: self.chat.value,
                                                                          type: entry.type,
                                                                          targetVC: targetVC,
                                                                          extraInfo: ChatAddTabMetaModel.ExtraInfo(event: Homeric.IM_CHAT_MAIN_CLICK,
                                                                                                                   params: ["location": "tab_more"])))
            }
        }
        actionSheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_IM_AddTab_Button) { [weak self] in
            guard let self = self, let targetVC = self.targetVC else { return }
            IMTracker.Chat.Main.Click.TabAdd(self.chat.value, self.chatFromWhere)
            let body = ChatAddTabBody(
                chat: self.chat.value,
                completion: { [weak self] tabContent in
                    self?.targetVC?.presentedViewController?.dismiss(animated: true) { [weak self] in
                        guard let self = self, let targetVC = self.targetVC else { return }
                        self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tabContent, targetVC: targetVC))
                    }
                }
            )
            self.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        }
        actionSheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_Groups_ManageTabs) { [weak self] in
            guard let self = self else { return }
            self.presentTabsManagementController(false)
            IMTracker.Chat.Main.Click.TabManagement(self.chat.value, self.chatFromWhere)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: targetVC)
        IMTracker.Chat.Main.Click.TabMore(self.chat.value, self.chatFromWhere)
    }

    func clickManage(_ button: UIButton, displayCount: Int) {
        IMTracker.Chat.Main.Click.TabMore(self.chat.value, self.chatFromWhere)
        if !Display.pad ||
            targetVC?.view.window?.traitCollection.horizontalSizeClass == .compact ||
            !userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.tab.ipad.menu")) {
            self.presentTabsManagementController(true)
            return
        }
        showTabMenu(sourceView: button, displayCount: displayCount)
    }

    private func showTabMenu(sourceView: UIView, displayCount: Int) {
        guard let targetVC = self.targetVC else { return }
        var actions: [UDMenuAction] = []
        var displayTabs: [ChatTabContent] = []
        if displayCount < self.dataSource.count {
            displayTabs = Array(self.dataSource.suffix(from: displayCount))
        }
        for (index, tab) in displayTabs.enumerated() {
            let metaModel = ChatTabMetaModel(chat: self.chat.value, type: tab.type, content: tab)
            let imageResource = self.tabModule.getImageResource(metaModel)
            var tabTitle = self.tabModule.getTabTitle(metaModel)
            let maxTitleLength: Int = 16
            if self.getLength(forText: tabTitle) > maxTitleLength {
                tabTitle = self.getPrefix(maxTitleLength, forText: tabTitle) + "..."
            }
            var action = UDMenuAction(
                title: tabTitle,
                icon: UIImage(),
                showBottomBorder: index == displayTabs.count - 1,
                tapHandler: { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tab, targetVC: targetVC))
                }
            )
            action.customIconHandler = { imageView in
                switch imageResource {
                case .image(let image):
                    imageView.bt.setLarkImage(with: .default(key: ""))
                    imageView.image = image
                case .key(key: let key, config: let config):
                    var passThrough: ImagePassThrough?
                    if let pbModel = config?.imageSetPassThrough {
                        passThrough = ImagePassThrough.transform(passthrough: pbModel)
                    }
                    imageView.bt.setLarkImage(with: .default(key: key),
                                              placeholder: config?.placeholder,
                                              passThrough: passThrough) { [weak imageView] res in
                        guard let imageView = imageView else { return }
                        switch res {
                        case .success(let imageResult):
                            guard let image = imageResult.image else { return }
                            if let tintColor = config?.tintColor {
                                imageView.image = image.ud.withTintColor(tintColor)
                            } else {
                                imageView.image = image
                            }
                        case .failure(let error):
                            Self.logger.error("set image fail", error: error)
                        }
                    }
                }
            }
            actions.append(action)
        }

        let canBdAddedTabTypes: Set<ChatTabType> = Set(self.dataSource.map { $0.type })
        let entrys = self.tabModule.getChatAddTabEntry(ChatTabContextModel(chat: self.chat.value)).filter { entry in
            !canBdAddedTabTypes.contains(entry.type)
        }
        entrys.forEach { entry in
            let tabType = entry.type
            let icon = entry.icon
            var action = UDMenuAction(
                title: entry.title,
                icon: UIImage(),
                tapHandler: { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    self.tabModule.beginAddTab(metaModel: ChatAddTabMetaModel(chat: self.chat.value,
                                                                              type: tabType,
                                                                              targetVC: targetVC))
                }
            )
            action.customIconHandler = { imageView in
                imageView.bt.setLarkImage(with: .default(key: ""))
                imageView.image = icon
            }
            actions.append(action)
        }

        var addAction = UDMenuAction(
            title: BundleI18n.LarkChat.Lark_IM_AddTab_Button,
            icon: UIImage(),
            tapHandler: { [weak self] in
                guard let self = self, let targetVC = self.targetVC else { return }
                let body = ChatAddTabBody(
                    chat: self.chat.value,
                    completion: { [weak self] tabContent in
                        self?.targetVC?.presentedViewController?.dismiss(animated: true) { [weak self] in
                            guard let self = self, let targetVC = self.targetVC else { return }
                            self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tabContent, targetVC: targetVC))
                        }
                    }
                )
                self.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: targetVC,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                )
            }
        )
        let addDisabled = !self.canManageTab.value.0
        addAction.isDisabled = addDisabled
        addAction.customIconHandler = { imageView in
            imageView.bt.setLarkImage(with: .default(key: ""))
            imageView.image = UDIcon.getIconByKey(.addTagOutlined, iconColor: addDisabled ? UIColor.ud.textDisabled : UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
        }
        actions.append(addAction)

        var manageAction = UDMenuAction(
            title: BundleI18n.LarkChat.Lark_Groups_ManageTabs,
            icon: UIImage(),
            tapHandler: { [weak self] in
                self?.presentTabsManagementController(false)
            }
        )
        let manageDisabled = !self.canManageTab.value.0
        manageAction.isDisabled = manageDisabled
        manageAction.customIconHandler = { imageView in
            imageView.bt.setLarkImage(with: .default(key: ""))
            imageView.image = UDIcon.getIconByKey(.adminOutlined, iconColor: manageDisabled ? UIColor.ud.textDisabled : UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
        }
        actions.append(manageAction)

        let config = UDMenuConfig(position: .bottomAuto)
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuColor = UIColor.ud.bgFloat
        style.menuMaxWidth = CGFloat.greatestFiniteMagnitude
        style.menuItemTitleColor = UIColor.ud.textTitle
        style.menuItemSelectedBackgroundColor = UIColor.ud.fillHover
        style.menuItemSeperatorColor = UIColor.ud.lineDividerDefault
        let menu = UDMenu(actions: actions, config: config, style: style)
        menu.showMenu(sourceView: sourceView, sourceVC: targetVC)
    }

    func clickTab(_ tabId: Int64) {
        self.guideService?.triggerGuide(self.chat.value.id)
        if let params = self.getClickParams(tabId) {
            IMTracker.Chat.Main.Click.TabClick(self.chat.value, params: params, self.chatFromWhere)
        }
        guard let tab = self.getTab(id: tabId), let targetVC = self.targetVC else { return }
        self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tab, targetVC: targetVC))
    }

    private func getClickParams(_ tabId: Int64) -> [AnyHashable: Any]? {
        guard let content = self.dataSource.first(where: { $0.id == tabId }) else { return nil }
        let metaModel = ChatTabMetaModel(chat: self.chat.value, type: content.type, content: content)
        return self.tabModule.getClickParams(metaModel)
    }

    private func transformToManageItem() -> [ChatTabManageItem] {
        return self.dataSource.compactMap {
            return self.tabModule.getTabManageItem(ChatTabMetaModel(chat: self.chat.value, type: $0.type, content: $0))
        }
    }

    func presentTabsManagementController(_ displayAddEntry: Bool) {
        let manageItems = self.transformToManageItem()
        if manageItems.isEmpty { return }
        let chat = self.chat.value
        var addedTabTypes: Set<ChatTabType> = Set(self.dataSource.map { $0.type })
        let entrys = self.tabModule.getChatAddTabEntry(ChatTabContextModel(chat: self.chat.value)).filter { entry in
            !addedTabTypes.contains(entry.type)
        }
        let viewModel = TabManagementViewModel(
            userResolver: userResolver,
            manageItems: manageItems,
            canManageTab: self.canManageTab,
            getTab: { [weak self] tabId in
                return self?.getTab(id: tabId)
            },
            getChat: { [weak self] in
                return self?.chat.value ?? chat
            }
        )
        let tabManagementVC = TabManagementController(
            viewModel: viewModel,
            tabModule: self.tabModule,
            displayAddEntry: displayAddEntry,
            addEntrys: displayAddEntry ? entrys : [],
            jumpTab: { [weak self] (tabContent, tabId) in
                self?.targetVC?.presentedViewController?.dismiss(animated: true) { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    if let tabContent = tabContent {
                        self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tabContent, targetVC: targetVC))
                        return
                    }
                    if let tab = self.getTab(id: tabId) {
                        self.tabModule.jumpTab(model: ChatJumpTabModel(chat: self.chat.value, content: tab, targetVC: targetVC))
                    }
                }
            },
            addTab: { [weak self] (tabType) in
                guard let self = self, let targetVC = self.targetVC else { return }
                targetVC.presentedViewController?.dismiss(animated: true)
                self.tabModule.beginAddTab(metaModel: ChatAddTabMetaModel(chat: self.chat.value,
                                                                          type: tabType,
                                                                          targetVC: targetVC,
                                                                          extraInfo: ChatAddTabMetaModel.ExtraInfo(event: Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                                                                                                   params: ["location": "tab_more"])))
            }
        )
        guard let targetVC = self.targetVC else { return }
        var viewControllerHeight: CGFloat = tabManagementVC.calculateHeight(bottomInset: targetVC.view.safeAreaInsets.bottom)
        let actionPanel = UDActionPanel(
            customViewController: tabManagementVC,
            config: UDActionPanelUIConfig(originY: max(UIScreen.main.bounds.height - viewControllerHeight, UIApplication.shared.statusBarFrame.height))
        )
        navigator.present(actionPanel, from: targetVC)
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }
}

final class ChatTabsDataSourceImp: ChatTabsDataSourceService, UserResolverWrapper {
    let userResolver: UserResolver
    var tabs: [RustPB.Im_V1_ChatTab] {
        return self.dataSource
    }
    var addedTabTypes: Set<ChatTabType> { return Set(self.dataSource.map { $0.type }) }
    private let chatId: Int64
    private let chatAPI: ChatAPI
    private var version: Int64?
    private let disposeBag = DisposeBag()
    private var dataSource: [ChatTabContent] = []
    init(userResolver: UserResolver, chatId: Int64) throws {
        self.userResolver = userResolver
        self.chatId = chatId
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let tabsPushObservable = try userResolver.userPushCenter.observable(for: PushChatTabs.self)

        tabsPushObservable
            .filter { $0.chatId == chatId }
            .subscribe(onNext: { [weak self] (push) in
                self?.handleTabs(push.tabs, newVersion: push.version)
            }).disposed(by: self.disposeBag)
        self.chatAPI
            .fetchChatTab(chatId: chatId, fromLocal: true)
            .flatMap { [weak self] (res) -> Observable<RustPB.Im_V1_GetChatTabsResponse> in
                guard let self = self else { return .empty() }
                self.handleTabs(res.tabs, newVersion: res.version)
                return self.chatAPI.fetchChatTab(chatId: chatId, fromLocal: false)
            }
            .subscribe(onNext: { [weak self] (res) in
                self?.handleTabs(res.tabs, newVersion: res.version)
            }, onError: { error in
                print(error)
            }).disposed(by: self.disposeBag)
    }

    private func handleTabs(_ tabs: [ChatTabContent], newVersion: Int64) {
        DispatchQueue.main.async {
            if let version = self.version, version >= newVersion { return }
            self.version = newVersion
            self.dataSource = tabs
        }
    }
}

/// pin tab count & badge 处理逻辑
/// 目前 count 和 badge 都是通过接口异步获取，后续会将这些数据挂在 Tab 实体上
final class ChatTabPinService: UserResolverWrapper {
    let userResolver: UserResolver
    static private let logger = Logger.log(ChatTabPinService.self, category: "Module.IM.ChatTab")
    static let pinBadgeShowKey: String = "ChatTabPinModuleBadgeShowKey"
    static let pinCountKey: String = "ChatTabPinModuleCountKey"

    private let context: ChatTabContext
    private let refreshBlock: () -> Void
    @ScopedInjectedLazy private var pinAPI: PinAPI?
    private let disposeBag = DisposeBag()
    private let pinBadgePath: Path?

    private lazy var enableCount: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.tabs.pin.count"))
    }()

    var pinCount: Int? {
        didSet {
            guard pinCount != oldValue else { return }
            self.context.store.setValue(pinCount, for: Self.pinCountKey)
            self.refreshBlock()
        }
    }

    // 埋点
    var trackShowBadge: Bool = false {
        didSet {
            guard trackShowBadge != oldValue else { return }
            self.context.store.setValue(trackShowBadge, for: Self.pinBadgeShowKey)
        }
    }

    var aleadySetup: Bool {
        guard enableCount else { return true }
        return pinCount != nil
    }

    init(userResolver: UserResolver, pinBadgePath: Path?, context: ChatTabContext, refreshBlock: @escaping () -> Void) {
        self.userResolver = userResolver
        self.pinBadgePath = pinBadgePath
        self.context = context
        self.refreshBlock = refreshBlock
    }

    func setupCountAndBadgeIfNeeded(chatId: String) {
        self.setupPinBadge(chatId: chatId)
        self.setupPinCount(chatId: chatId)
    }

    private func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
            trackShowBadge = true
        } else {
            BadgeManager.clearBadge(path)
            trackShowBadge = false
        }
    }

    private var pinBadgeAleadySetup: Bool = false
    private func setupPinBadge(chatId: String) {
        guard !pinBadgeAleadySetup,
              let pinBadgePath = pinBadgePath else { return }
        self.pinBadgeAleadySetup = true
        try? self.context.resolver.userPushCenter.observable(for: PushChatPinReadStatus.self)
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.badgeShow(for: pinBadgePath, show: !push.hasRead)
                Self.logger.info("chat tab pin PushChatPinReadStatus \(push.hasRead) chatId: \(chatId)")
            }).disposed(by: self.disposeBag)
        self.pinAPI?
            .getPinReadStatus(chatId: chatId).subscribe(onNext: { [weak self] (hasRead) in
                guard let `self` = self else { return }
                self.badgeShow(for: pinBadgePath, show: !hasRead)
                Self.logger.info("chat tab pin getPinReadStatus \(hasRead) chatId: \(chatId)")
            }).disposed(by: self.disposeBag)
    }

    private var pinCountAleadySetup: Bool = false
    private func setupPinCount(chatId: String) {
        guard enableCount else { return }
        let chatID = Int64(chatId) ?? 0
        guard !pinCountAleadySetup else { return }
        self.pinCountAleadySetup = true
        try? self.context.resolver.userPushCenter.observable(for: PushChatPinCount.self)
            .filter { $0.chatId == chatID }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                self?.pinCount = Int(push.count)
                Self.logger.info("chat tab pin PushChatPinCount \(push.count) chatId: \(chatId)")
        }).disposed(by: self.disposeBag)

        self.pinAPI?.getChatPinCount(chatId: chatID, useLocal: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.pinCount = Int(count)
                Self.logger.info("chat tab pin getChatPinCount Local \(count) chatId: \(chatId)")
        }).disposed(by: self.disposeBag)
        self.pinAPI?.getChatPinCount(chatId: chatID, useLocal: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.pinCount = Int(count)
                Self.logger.info("chat tab pin getChatPinCount Server \(count) chatId: \(chatId)")
        }).disposed(by: self.disposeBag)
    }
}

final class ChatTabsGuideServiceImp: ChatTabsGuideService {

    private var _currentShowGuideChatIds: Set<String> = []
    var currentShowGuideChatIds: Set<String> {
        return _currentShowGuideChatIds
    }

    func triggerGuide(_ chatId: String) {
        _currentShowGuideChatIds.insert(chatId)
    }
}

final class ChatDocsServiceImp: ChatDocsService {
    private let docSDKAPI: ChatDocDependency
    init(userResolver: UserResolver) throws {
        self.docSDKAPI = try userResolver.resolve(assert: ChatDocDependency.self)
    }
    func preloadDocs(_ url: String, from source: String) {
        self.docSDKAPI.preloadDocFeed(url, from: source)
    }
}

final class ChatWAContainerServiceImp: ChatWAContainerService {
    private let waSDKAPI: ChatWAContainerDependency
    init(userResolver: UserResolver) throws {
        self.waSDKAPI = try userResolver.resolve(assert: ChatWAContainerDependency.self)
    }
    func preloadWebAppIfNeed(appId: String) {
        self.waSDKAPI.preloadWebAppIfNeed(appId: appId)
    }
}

final class ChatTabGuideCellLifeCycleObserver: CellLifeCycleObsever, UserResolverWrapper {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    @ScopedInjectedLazy private var guideService: ChatTabsGuideService?
    func willDisplay(metaModel: CellMetaModel, context: PageContext) {
        let message = metaModel.message
        var richText: Basic_V1_RichText?
        if message.type == .text, let content = message.content as? TextContent {
          richText = content.richText
        } else if message.type == .post, let content = message.content as? PostContent {
          richText = content.richText
        }
        guard let richText = richText else { return }
        if richText.elements.contains(where: { (_, element) in
            return element.tag == .a
        }) {
            /// 查看过包含链接的消息
            self.guideService?.triggerGuide(metaModel.getChat().id)
        }
    }
}

final class ChatDocsCellLifeCycleObserver: CellLifeCycleObsever, UserResolverWrapper {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    @ScopedInjectedLazy private var docsService: ChatDocsService?
    private lazy var loadConfig: [Int] = {
        if let settings = try? userResolver.settings.setting(with: .make(userKeyLiteral: "preload_doc_chat_types")) {
            return settings["supportTypes"] as? [Int] ?? []
        }
        return []
    }()

    func willDisplay(metaModel: CellMetaModel, context: PageContext) {
        let message = metaModel.message
        let chat = metaModel.getChat()
        if self.loadConfig.contains(chat.type.rawValue) {
            message.urlPreviewHangPointMap.values.forEach({ hangPoint in
                docsService?.preloadDocs(hangPoint.url, from: chat.trackType + "_message")
            })
        }
    }
}

final class ChatWAContainerLiftCycleObserver: CellLifeCycleObsever, UserResolverWrapper {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    @ScopedInjectedLazy private var waContainerService: ChatWAContainerService?
    func willDisplay(metaModel: CellMetaModel, context: PageContext) {
        let message = metaModel.message

        guard message.type == .card, let content = message.content as? CardContent else {
            return
        }
        content.extraInfo.gadgetConfig.cliIds.forEach { waContainerService?.preloadWebAppIfNeed(appId: $0) }
    }
}
