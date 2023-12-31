//
//  MessengerCryptoChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zc09v on 2021/10/28.
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
import UniverseDesignToast
import RustPB
import LarkModel
import LKCommonsLogging

final public class MessengerCryptoChatNavigationBarSubModule: BaseNavigationBarItemSubModule {
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }
    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    // 是否需要展示加人按钮(iPad宽间距时展示,iPhone或iPad分小屏时不展示)
    private var needShowAddmember: Bool = false
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var chatMorePath: Path = {
        return self.context.chatRootPath.chat_more
    }()
    private static let logger = Logger.log(MessengerCryptoChatNavigationBarSubModule.self, category: "Module.IM.AddMemberItem")

    @ScopedInjectedLazy private var docSDKAPI: ChatDocDependency?

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return model.chat.isCrypto
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func viewWillAppear() {
        self.updateAddmemberIfNeeded(targetViewWidth: self.context.chatVC().view.bounds.width)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let metaModel = metaModel else {
            return
        }
        self.updateAddmemberIfNeeded(targetViewWidth: size.width)
    }

    private func needShowAddmember(targetViewWidth: CGFloat?) -> Bool {
        if Display.pad {
            return targetViewWidth ?? 0 >= 500
        }
        return false
    }

    private func updateAddmemberIfNeeded(targetViewWidth: CGFloat?) {
        guard let metaModel = metaModel else {
            return
        }
        let newValue = self.needShowAddmember(targetViewWidth: targetViewWidth)
        if newValue != self.needShowAddmember {
            self.needShowAddmember = newValue
            self._rightItems = self.buildRigthItems(metaModel: metaModel)
            self.context.refreshRightItems()
        }
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.metaModel = model
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        if self.context.currentSelectMode() == .multiSelecting {
            self._rightItems = []
            return
        }
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self._rightItems = self.buildRigthItems(metaModel: metaModel)
    }
    @ScopedInjectedLazy private var secretChatService: SecretChatService?
    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let chat = metaModel.chat
        if self.needShowAddmember && secretChatService?.secretChatEnable ?? false {
            if chat.type == .p2P {
                // 单聊为加第三人新建群聊
                items.append(self.p2PcreateGroupItem)
            } else {
                // 群聊为直接加人按钮
                items.append(self.addNewMemberItem)
            }
        }
        items.append(self.moreInfoItem)
        return items
    }

    private lazy var addNewMemberItem: ChatNavigationExtendItem = {
        let addNewBtn = UIButton()
        Self.addPointerStyle(addNewBtn)
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.add_member_icon,
                                                                style: self.context.navigationBarDisplayStyle())
        addNewBtn.setImage(image, for: .normal)
        addNewBtn.addTarget(self, action: #selector(addNewMemberItemClicked(sender:)), for: .touchUpInside)
        return ChatNavigationExtendItem(type: .addNewMember, view: addNewBtn)
    }()

    private lazy var p2PcreateGroupItem: ChatNavigationExtendItem = {
        let addNewBtn = UIButton()
        Self.addPointerStyle(addNewBtn)
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.add_member_icon,
                                                                style: self.context.navigationBarDisplayStyle())
        addNewBtn.setImage(image, for: .normal)
        addNewBtn.addTarget(self, action: #selector(onTapCreateGroup(sender:)), for: .touchUpInside)
        return ChatNavigationExtendItem(type: .p2pCreateGroup, view: addNewBtn)
    }()

    @objc
    private func addNewMemberItemClicked(sender: UIButton) {
        guard let metaModel = self.metaModel else {
            return
        }
        let vc = self.context.chatVC()
        let chat = metaModel.chat
        var isOwner: Bool { return userResolver.userID == chat.ownerId }
        guard isOwner || chat.addMemberPermission == .allMembers else {
            // 添加群成员
            if let view = vc.viewIfLoaded {
                let text = BundleI18n.LarkChat.Lark_Group_OnlyGroupOwnerAdminInviteMembers
                UDToast.showTips(with: text, on: view)
            }
            return
        }
        let body = AddGroupMemberBody(chatId: chat.id)
        navigator.open(body: body, from: vc)
    }

    @objc
    private func onTapCreateGroup(sender: UIButton) {
        guard let metaModel = self.metaModel else {
            return
        }
        let vc = self.context.chatVC()
        let chat = metaModel.chat
        // 单聊加第三人变群聊
        if chat.chatterHasResign, let view = vc.viewIfLoaded {
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ChatWindowP2pChatterDeactiviedCreateGroupTip, on: view)
            return
        }
        let chatId = chat.id
        self.fetchP2PChatterAuthAndHandle { [weak self] in
            guard let vc = self?.context.chatVC() else {
                return
            }
            self?.navigator.open(body: CreateGroupWithRecordBody(p2pChatId: chatId), from: vc)
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
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_CantAddToGroupBlocked_Hover, on: view)
                    }
                } else if deniedReason == .blocked {
                    if let view = vc.viewIfLoaded {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_NewContacts_BlockedOthersUnableToXToastGeneral, on: view)
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
                    self?.navigator.present(body: addContactBody, from: vc)
                } else {
                    handler()
                }
            }, onError: { [weak self] (error) in
                Self.logger.error("The user blocked the request, collaboration permission settings failed to be pulled\(String(describing: self?.metaModel?.chat.chatterId))", error: error)
            }).disposed(by: disposeBag)
    }

    @ScopedInjectedLazy private var contactAPI: ContactAPI?
    func fetchP2PChatterAuth(chat: Chat) -> Observable<RustPB.Basic_V1_Auth_DeniedReason> {
        let actionType = Basic_V1_Auth_ActionType.inviteSameCryptoChat
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
            } ?? .error(UserScopeError.disposed)
    }

    private lazy var moreInfoItem: ChatNavigationExtendItem = {
        let button = UIButton()
        Self.addPointerStyle(button)
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
        return ChatNavigationExtendItem(type: .moreItem, view: button)
    }()

    func moreInfoItemClick() {
        guard let metaModel = self.metaModel else { return }
        let chat = metaModel.chat
        let targetVC = self.context.chatVC()
        let currentChatterID = userResolver.userID
        let isGroupOwner = userResolver.userID == chat.ownerId
        ChatTracker.trackChatSetting(chat: chat,
                                     isGroupOwner: isGroupOwner,
                                     source: "more")
        IMTracker.Chat.Main.Click.Sidebar(chat, self.context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))

        if !chat.announcement.docURL.isEmpty {
            self.docSDKAPI?.preloadDocFeed(chat.announcement.docURL, from: chat.trackType + "_announcement")
        }
        let body = ChatInfoBody(chat: chat, action: .chatMoreMobile, type: .ignore)
        navigator.push(body: body, from: targetVC)
        ChatTracker.trackNewChatSetting(chat: chat,
                                        isGroupOwner: isGroupOwner,
                                        source: .chatMoreMobile)
        self.badgeShow(for: self.context.chatRootPath.chat_more, show: false)
    }

    private static func addPointerStyle(_ button: UIButton) {
        if #available(iOS 13.4, *) {
            button.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let view = interaction.view else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: view.bounds.width + 20, height: 36), 8)
                }))
        }
    }

    private func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
