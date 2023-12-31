//
//  MessengerChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zc09v on 2021/10/25.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkUIKit
import UniverseDesignColor
import LarkMessengerInterface
import LarkInteraction
import EENavigator
import RxSwift
import RxCocoa
import LarkCore
import LarkAccountInterface
import LarkContainer
import LarkBadge
import LarkSDKInterface
import LarkSetting
import UniverseDesignToast
import RustPB
import LarkModel
import LKCommonsLogging
import LarkAIInfra
import UniverseDesignMenu

///密聊场景下使用独立MessengerCryptoChatNavigationBarSubModule，请注意修改是否需要同步调整
///https://bytedance.feishu.cn/wiki/wikcn1VprnQ1YOuaYpJFLRRplxb

public protocol NavigationBarSubModuleDependency {
    func preloadDocFeed(_ url: String, from source: String)
}

public final class ChatNavigationBarRightSubModule: BaseNavigationBarItemSubModule {
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }
    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    private static let logger = Logger.log(ChatNavigationBarRightSubModule.self, category: "Module.IM.AddMemberItem")
    private let disposeBag: DisposeBag = DisposeBag()
    private var isPadWideScreen: Bool = false
    private lazy var chatMorePath: Path = {
        return self.context.chatRootPath.chat_more
    }()
    @ScopedInjectedLazy private var dependency: NavigationBarSubModuleDependency?

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        var needToRefresh = false
        if self.metaModel?.chat.isFrozen != model.chat.isFrozen {
            needToRefresh = true
        }
        self.metaModel = model
        if needToRefresh {
            self._rightItems = self.buildRigthItems(metaModel: model, isPadWideScreen: self.isPadWideScreen)
            self.context.refreshRightItems()
        }
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        if self.context.currentSelectMode() == .multiSelecting {
            self._rightItems = []
            return
        }
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self.isPadWideScreen = self.isPadWideScreen(targetViewWidth: self.context.chatVC().view.bounds.width)
        self._rightItems = self.buildRigthItems(metaModel: metaModel, isPadWideScreen: isPadWideScreen)
    }

    public override func viewWillAppear() {
        self.updateSearchAndAddmemberIfNeeded(targetViewWidth: self.context.chatVC().view.bounds.width)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.updateSearchAndAddmemberIfNeeded(targetViewWidth: size.width)
    }

    public override func splitSplitModeChange() {
        self.updateSearchAndAddmemberIfNeeded(targetViewWidth: self.context.chatVC().view.bounds.width)
    }

    public override func splitDisplayModeChange() {
        self.updateSearchAndAddmemberIfNeeded(targetViewWidth: self.context.chatVC().view.bounds.width)
    }

    private func isPadWideScreen(targetViewWidth: CGFloat?) -> Bool {
        if Display.pad {
            return targetViewWidth ?? 0 >= 500
        }
        return false
    }

    private func canShowMyAIModeItem() -> Bool {
        guard self.context.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_header"),
              let myAIService = try? self.context.userResolver.resolve(type: MyAIService.self),
              myAIService.enable.value == true,
              let metaModel = self.metaModel,
              metaModel.chat.supportMyAIInlineMode else { return false }
        return true
    }

    private func updateSearchAndAddmemberIfNeeded(targetViewWidth: CGFloat?) {
        guard let metaModel = metaModel else {
            return
        }
        let newValue = self.isPadWideScreen(targetViewWidth: targetViewWidth)
        if newValue != self.isPadWideScreen {
            self.isPadWideScreen = newValue
            self._rightItems = self.buildRigthItems(metaModel: metaModel, isPadWideScreen: isPadWideScreen)
            self.context.refreshRightItems()
        }
    }

    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel, isPadWideScreen: Bool) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let chat = metaModel.chat
        if isPadWideScreen {
            items.insert(self.searchItem, at: 0)
            if chat.type == .p2P {
                if let chatter = chat.chatter, chatter.type == .user {
                    items.append(self.p2PcreateGroupItem)
                }
            } else {
                if !chat.isFrozen {
                    items.append(self.addNewMemberItem)
                }
            }
        }
        items.append(contentsOf: self.addAIAndFoldItem(isPadWideScreen: isPadWideScreen))
        /// 临时入会用户
        if chat.isInMeetingTemporary {
            let isInMeetingTemporaryBlackList: [ChatNavigationExtendItemType] = [.searchItem, .addNewMember, .moreItem, .myAIChatMode, .foldItem]
            items = items.filter { !isInMeetingTemporaryBlackList.contains($0.type) }
        }
        /// my ai 分会话
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
            let isInMyAIChatModeBlackList: [ChatNavigationExtendItemType] = [.searchItem, .addNewMember, .moreItem, .myAIChatMode, .foldItem]
            items = items.filter { !isInMyAIChatModeBlackList.contains($0.type) }
        }
        return items
    }

    private lazy var searchButton: UIButton = {
        let searchButton = UIButton()
        searchButton.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.search_outlined,
                                                                style: self.context.navigationBarDisplayStyle())
        searchButton.setImage(image, for: .normal)
        searchButton.addTarget(self, action: #selector(searchItemClicked(sender:)), for: .touchUpInside)
        return searchButton
    }()
    private lazy var searchItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .searchItem, view: self.searchButton)
    }()

    @objc
    private func searchItemClicked(sender: UIButton) {
        guard let metaModel = self.metaModel else { return }
        let targetVC = self.context.chatVC()
        LarkMessageCoreTracker.trackNewChatSearchButton()
        let chat = metaModel.chat
        let body = SearchInChatBody(chatId: chat.id, chatType: chat.type, isMeetingChat: chat.isMeeting)
        self.context.nav.push(body: body, from: targetVC)
    }

    private lazy var addNewMemberButton: UIButton = {
        let addNewBtn = UIButton()
        addNewBtn.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.add_member_icon,
                                                                style: self.context.navigationBarDisplayStyle())
        addNewBtn.setImage(image, for: .normal)
        addNewBtn.addTarget(self, action: #selector(onTapAddNewMember(sender:)), for: .touchUpInside)
        return addNewBtn
    }()
    private lazy var addNewMemberItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .addNewMember, view: addNewMemberButton)
    }()

    private lazy var p2PcreateGroupButton: UIButton = {
        let addNewBtn = UIButton()
        addNewBtn.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.add_member_icon,
                                                                style: self.context.navigationBarDisplayStyle())
        addNewBtn.setImage(image, for: .normal)
        addNewBtn.addTarget(self, action: #selector(onTapCreateGroup(sender:)), for: .touchUpInside)
        return addNewBtn
    }()
    private lazy var p2PcreateGroupItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .p2pCreateGroup, view: p2PcreateGroupButton)
    }()

    @objc
    private func onTapAddNewMember(sender: UIButton) {
        guard let metaModel = self.metaModel else {
            return
        }
        let vc = self.context.chatVC()
        let chat = metaModel.chat
        var isOwner: Bool { return context.userID == chat.ownerId }
        var isGroupAdmin: Bool { return chat.isGroupAdmin }
        // 添加群成员
        guard isOwner || isGroupAdmin || chat.addMemberPermission == .allMembers else {
            if let view = vc.viewIfLoaded {
                let text = BundleI18n.LarkMessageCore.Lark_Group_OnlyGroupOwnerAdminInviteMembers
                UDToast.showTips(with: text, on: view)
            }
            return
        }
        if chat.isCrossTenant {
        // 外部群 && 非密聊，可以使用二维码和链接邀请
            let body = ExternalGroupAddMemberBody(chatId: chat.id)
            self.context.nav.open(body: body, from: vc)
        } else {
        // 内部群加群界面
            let body = AddGroupMemberBody(chatId: chat.id)
            self.context.nav.open(body: body, from: vc)
        }
    }

    @objc
    func onTapCreateGroup(sender: UIButton) {
        // 单聊加第三人变群聊
        guard let metaModel = self.metaModel else {
            return
        }
        let vc = self.context.chatVC()
        let chat = metaModel.chat
        // 判断是否离职
        if chat.chatterHasResign, let view = vc.viewIfLoaded {
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatWindowP2pChatterDeactiviedCreateGroupTip, on: view)
            return
        }
        let chatId = chat.id
        self.fetchP2PChatterAuthAndHandle { [weak self] in
            guard let vc = self?.context.chatVC() else {
                return
            }
            self?.context.nav.open(body: CreateGroupWithRecordBody(p2pChatId: chatId), from: vc)
        }
    }

    func fetchP2PChatterAuthAndHandle(handler: @escaping () -> Void) {
        guard let metaModel = self.metaModel else {
            return
        }
        let chat = metaModel.chat
        let businessType = AddContactBusinessType.groupConfirm
        let displayName = chat.chatter?.displayName ?? ""
        let chatId = chat.id
        let userId = chat.chatter?.id ?? ""
        DelayLoadingObservableWraper.wraper(observable: self.fetchP2PChatterAuth(chat: chat),
                                            showLoadingIn: self.context.chatVC().view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] deniedReason in
                guard let metaModel = self?.metaModel,
                      let vc = self?.context.chatVC() else {
                          return
                }
                if deniedReason == .beBlocked {
                    if let view = vc.viewIfLoaded {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_CantAddToGroupBlocked_Hover, on: view)
                    }
                } else if deniedReason == .blocked {
                    if let view = vc.viewIfLoaded {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_NewContacts_BlockedOthersUnableToXToastGeneral, on: view)
                    }
                } else if deniedReason == .noFriendship {
                    // 如果不是好友，引导到添加好友的弹窗
                    var source = Source()
                    source.sourceType = .chat
                    source.sourceID = chatId
                    let addContactBody = AddContactApplicationAlertBody(userId: userId,
                                                                        chatId: chatId,
                                                                        source: source,
                                                                        displayName: displayName,
                                                                        targetVC: vc,
                                                                        businessType: businessType)
                    self?.context.nav.present(body: addContactBody, from: vc)
                } else {
                    handler()
                }
            }, onError: { [weak self] (error) in
                Self.logger.error("The user blocked the request, collaboration permission settings failed to be pulled\(String(describing: self?.metaModel?.chat.chatterId))", error: error)
            }).disposed(by: disposeBag)
    }

    @ScopedInjectedLazy private var contactAPI: ContactAPI?
    func fetchP2PChatterAuth(chat: Chat) -> Observable<RustPB.Basic_V1_Auth_DeniedReason> {
        var actionType: Basic_V1_Auth_ActionType
        if chat.isCrossTenant {
            actionType = .inviteSameCrossTenantChat
        } else {
            actionType = .inviteSameChat
        }
        return self.contactAPI?
            .fetchAuthChattersRequest(actionType: actionType,
                                      isFromServer: true,
                                      chattersAuthInfo: [chat.chatterId: chat.id])
            .map { [weak self] (response) -> RustPB.Basic_V1_Auth_DeniedReason in
                guard let chat = self?.metaModel?.chat else {
                    return .unknownReason
                }
                let chatterID = chat.chatterId
                let deniedReason = response.authResult.deniedReasons[chatterID]
                return deniedReason ?? .unknownReason
            } ?? .empty()
    }

    private lazy var moreInfoButton: UIButton = {
        let button = UIButton()
        button.addPointerStyle()
        let defaultIcon: UIImage = Resources.navibar_more
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: defaultIcon,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        button.badge.observe(for: self.context.chatRootPath.chat_more)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.moreInfoItemClick()
            })
            .disposed(by: disposeBag)
        return button
    }()
    private lazy var moreInfoItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .moreItem, view: self.moreInfoButton)
    }()

    private lazy var myAIChatModeButton: UIButton = {
        let myAIButton = UIButton()
        myAIButton.addPointerStyle()
        let image = Resources.myai_coloful
        myAIButton.setImage(image, for: .normal)
        myAIButton.addTarget(self, action: #selector(myAIItemClicked(sender:)), for: .touchUpInside)
        return myAIButton
    }()

    private lazy var myAIChatModeItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .myAIChatMode, view: self.myAIChatModeButton)
    }()

    // pageService
    @objc
    private func myAIItemClicked(sender: UIButton) {
        guard let myAIChatModeOpenService = try? self.context.container.resolve(type: IMMyAIChatModeOpenService.self) else {
            return
        }
        myAIChatModeOpenService.handleMyAIChatModeAndQuickAction(quickAction: nil,
                                                                 sceneCardClose: false,
                                                                 fromVC: self.context.chatVC(),
                                                                 trackParams: [:])
    }

    private lazy var foldButton: UIButton = {
        let button = UIButton()
        button.addPointerStyle()
        let defaultIcon: UIImage = Resources.navibar_more
        let image = ChatNavigationBarItemTintColor.tintColorFor(
            image: defaultIcon,
            style: self.context.navigationBarDisplayStyle()
        )
        button.setImage(image, for: .normal)
        button.badge.observe(for: self.context.chatRootPath.chat_more)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.foldItemClick()
            })
            .disposed(by: disposeBag)
        return button
    }()
    private lazy var foldItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .foldItem, view: self.foldButton)
    }()

    public override func barStyleDidChange() {
        let buttons: [UIButton] = [moreInfoButton, searchButton, addNewMemberButton, p2PcreateGroupButton, foldButton]
        buttons.forEach { button in
            if let image = button.imageView?.image {
                button.setImage(ChatNavigationBarItemTintColor.tintColorFor(image: image,
                                                                            style: self.context.navigationBarDisplayStyle()), for: .normal)
            }
        }
    }

    private func foldItemClick() {
        guard let aiInfoService = try? self.context.userResolver.resolve(type: MyAIInfoService.self) else {
            return
        }
        let fromVC = self.context.chatVC()
        var actions: [UDMenuAction] = []
        var myAIAction = UDMenuAction(
            title: aiInfoService.info.value.name,
            icon: Resources.myai_coloful,
            tapHandler: { [weak self] in
                guard let self = self else { return }
                self.myAIItemClicked(sender: self.myAIChatModeButton)
            }
        )
        // 设置彩色icon
        myAIAction.customIconHandler = { imageView in
            imageView.image = Resources.myai_coloful
        }
        let moreInfoAction = UDMenuAction(
            title: BundleI18n.LarkMessageCore.Lark_Legacy_MessageSetting,
            icon: Resources.setting_outlined,
            tapHandler: { [weak self] in
                self?.moreInfoItemClick()
            }
        )
        actions.append(myAIAction)
        actions.append(moreInfoAction)
        var style = UDMenuStyleConfig.defaultConfig()
        style.showArrowInPopover = false
        style.menuOffsetFromSourceView = 9
        style.menuColor = UIColor.ud.bgFloat
        style.maskColor = .clear
        style.menuMaxWidth = CGFloat.greatestFiniteMagnitude
        style.menuItemTitleColor = UIColor.ud.textTitle
        style.menuItemSelectedBackgroundColor = UIColor.ud.fillHover
        let menu = UDMenu(actions: actions, style: style)
        menu.showMenu(sourceView: self.foldButton, sourceVC: fromVC)
    }
    private func moreInfoItemClick() {
        guard let metaModel = self.metaModel else { return }
        let targetVC = self.context.chatVC()
        let chat = metaModel.chat
        let currentChatterID = self.context.userID
        let isGroupOwner = self.context.userID == chat.ownerId
        LarkMessageCoreTracker.trackChatSetting(chat: chat,
                                                isGroupOwner: isGroupOwner,
                                                source: "more")
        IMTracker.Chat.Main.Click.Sidebar(chat, self.context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))

        if let url = URL(string: chat.announcement.docURL) {
            self.dependency?.preloadDocFeed(url.absoluteString, from: chat.trackType + "_announcemenut")
        }
        let body = ChatInfoBody(chat: chat, action: .chatMoreMobile, type: .ignore)
        self.context.nav.push(body: body, from: targetVC)
        LarkMessageCoreTracker.trackNewChatSetting(chat: chat,
                                                   isGroupOwner: isGroupOwner,
                                                   source: .chatMoreMobile)
        self.badgeShow(for: self.context.chatRootPath.chat_more, show: false)
    }

    private func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }

    private func addAIAndFoldItem(isPadWideScreen: Bool) -> [ChatNavigationExtendItem] {
        if Display.pad {
            return self.padStyleFor(isPadWideScreen: isPadWideScreen)
        } else {
            return self.phoneStyle()
        }
    }

    private func phoneStyle() -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        if canShowMyAIModeItem() {
            items.append(self.myAIChatModeItem)
            items.append(self.moreInfoItem)
        } else {
            items.append(self.moreInfoItem)
        }
        return items
    }

    private func padStyleFor(isPadWideScreen: Bool) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        if canShowMyAIModeItem(), isPadWideScreen {
            items.append(self.myAIChatModeItem)
            items.append(self.moreInfoItem)
        } else if canShowMyAIModeItem(), !isPadWideScreen {
            items.append(self.foldItem)
        } else {
            items.append(self.moreInfoItem)
        }
        return items
    }
}
