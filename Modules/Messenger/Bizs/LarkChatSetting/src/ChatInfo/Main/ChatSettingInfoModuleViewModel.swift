//
//  ChatSettingInfoModuleViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/4.
//

import UIKit
import RustPB
import RxSwift
import RxRelay
import LarkTag
import LarkCore
import LarkModel
import LarkUIKit
import Foundation
import EENavigator
import LarkOpenChat
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkFeatureGating
import UniverseDesignToast
import LarkAccountInterface
import UniverseDesignDialog
import LarkMessengerInterface
import ThreadSafeDataStructure
import LarkSetting

final class ChatSettingInfoModuleViewModel: ChatSettingModuleViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(ChatSettingInfoModuleViewModel.self, category: "Module.IM.ChatInfo")

    // 是否为默认首字母排序
    private var isDefaultAlphabetical: Bool {
        // imChatMemberListFg：当前租户是否开启了FG
        let imChatMemberListKey = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.imChatMemberList.rawValue)
        // canBeSortedAlphabetically： 群是否支持首字母排序
        let isSupport = userResolver.fg.dynamicFeatureGatingValue(with: imChatMemberListKey) &&
        chat.canBeSortedAlphabetically &&
        !chat.isSuper
        let memberListDefaultAlphabeticalKey = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.memberListDefaultAlphabetical.rawValue)
        return userResolver.fg.dynamicFeatureGatingValue(with: memberListDefaultAlphabeticalKey) && isSupport
    }

    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }
    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var reloadSubject = PublishSubject<Void>()
    private(set) var disposeBag = DisposeBag()
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }
    @ScopedInjectedLazy private var contactAPI: ContactAPI?
    private let hasModifyAccess: Bool
    var chat: Chat
    var isMe: Bool {
        currentUserId == chat.chatterId
    }
    private var currentUserId: String {
        return self.userResolver.userID
    }
    private var pushChat: Observable<Chat>
    var secretChatEnable: Bool {
        secretChatService?.secretChatEnable ?? false
    }
    weak var targetVC: UIViewController?
    var isOwner: Bool { return currentUserId == chat.ownerId }
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chat.isGroupAdmin
    }
    // 目前GetChatChatter服务端一次性最多返回15个机器人
    let maxDisplayBotCount: Int = 15
    /// 是否有权限修改群头像
    private var hasAccess: Bool {
        return self.chat.isAllowPost && (isOwner || isGroupAdmin || !self.chat.offEditGroupChatInfo)
    }
    private var members: [LarkModel.Chatter] = []
    var contactOptDisposeBag = DisposeBag()
    private let schedulerType: SchedulerType

    // 可感知耗时&错误相关属性
    var errorObserver: Observable<Error> {
        return _errorPublisher.asObservable()
    }

    private var _errorPublisher = PublishSubject<Error>()
    private var firstScreenGroupMemberReadySubject = PublishSubject<Void>()
    var firstScreenGroupMemberReadyOb: Observable<Void> {
        firstScreenGroupMemberReadySubject.asObservable()
    }

    @ScopedInjectedLazy var preloadConfiguration: RustConfigurationService?
    @ScopedInjectedLazy private var secretChatService: SecretChatService?
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    init(resolver: UserResolver,
         chat: Chat,
         pushChat: Observable<Chat>,
         schedulerType: SchedulerType,
         hasModifyAccess: Bool,
         targetVC: UIViewController?) {
        self.chat = chat
        self.pushChat = pushChat
        self.hasModifyAccess = hasModifyAccess
        self.schedulerType = schedulerType
        self.targetVC = targetVC
        self.userResolver = resolver
    }

    func structItems() {
        let items = [
            personInfoItem(),        // 单聊信息
            groupOrBotInfoItem(),    // 群聊/bot信息
            groupMembersItem(),      // 群成员
            onCallDescriptionItem()  // 服务台描述
        ].compactMap({ $0 })
        self.items = items
    }

    func startToObserve() {
        let chatId = chat.id
        self.refreshMembers()
        if chat.type != .p2P {
            // 监听群成员变更，刷新UI
            pushChat
                .filter { $0.id == chatId }
                .distinctUntilChanged { $0.ownerId == $1.ownerId && $0.chatterCount == $1.chatterCount }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chat in
                    self?.chat = chat
                    self?.refreshMembers()
                }).disposed(by: self.disposeBag)
        }
        let pushChatReloadOb = pushChat
            .filter { $0.id == chatId }
            .observeOn(MainScheduler.instance)
            .map({ [weak self] chat -> Void in
                self?.chat = chat
            })
        pushChatReloadOb.subscribe(onNext: { [weak self] _ in
                self?.structItems()
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }
}

// MARK: item方法
extension ChatSettingInfoModuleViewModel {
    // 单聊信息
    func personInfoItem() -> CommonCellItemProtocol? {
        guard chat.type == .p2P, let chatter = chat.chatter, chatter.type == .user else { return nil }
        let secretChatEnable = self.secretChatEnable
        // code_next_line tag CryptChat
        let createGroupEnable = chat.isCrypto ? secretChatEnable : true
        let isShowAddButton = chat.chatter?.type == .user && createGroupEnable
        let groupChat = chat
        let nameModel = ChatInfoPersonInfoItem(
            type: .p2PChatInfo,
            cellIdentifier: ChatInfoPersonInfoCell.lu.reuseIdentifier,
            style: .auto,
            avatarKey: chat.avatarKey,
            medalKey: chat.chatter?.medalKey ?? "",
            entityId: chat.chatterId,
            name: chatter.displayWithAnotherName,
            showCryptoIcon: chat.isCrypto,
            showAddButton: isShowAddButton,
            addButtonTapHandler: { [weak self] in
                ChatSettingTracker.imChatSettingClickAddGroup(chat: groupChat)
                self?.createChatGroup()
            },
            avatarTapHandler: { [weak self] in
                self?.toProfile()
            })
        return nameModel
    }

    // 群聊/机器人信息
    func groupOrBotInfoItem() -> CommonCellItemProtocol? {
        if let chatter = chat.chatter, chatter.type == .user { return nil }
        let isBot = chat.type == .p2P && chat.chatter?.type == .bot
        let chatId = chat.id
        let settingChat = chat
        let isOncall = chat.isOncall
        var tagTypes: [TagType] = []
        var description: String = ""
        if isBot, let chatter = chat.chatter {
            let botTag = chatter.withBotTag
            description = chatter.description_p.text
            if !botTag.isEmpty {
                tagTypes.append(.robot)
            }
        } else if self.chat.isP2PAi {
            if let chatter = chat.chatter {
                description = chatter.description_p.text
            }
        } else {
            if self.chat.isDepartment {
                tagTypes.append(.team)
            }
            if self.chat.isTenant {
                tagTypes.append(.allStaff)
            }
            if self.chat.isPublic {
                tagTypes.append(.public)
            }
            if !self.chat.isOncall {
                // code_block_end
                description = chat.isCrypto ? "" : chat.description
            }
        }
        // code_block_start tag CryptChat
        if self.chat.isCrypto {
            tagTypes.append(.crypto)
        }
        let nameModel = ChatInfoNameModel(
            type: .groupChatInfo,
            cellIdentifier: ChatInfoNameCell.lu.reuseIdentifier,
            style: .auto,
            avatarKey: chat.avatarKey,
            entityId: chat.id,
            name: chat.displayName,
            nameTagTypes: tagTypes,
            description: "",
            canBeShared: chat.chatCanBeShared(currentUserId: currentUserId),
            showEditIcon: self.hasAccess,
            showCryptoIcon: chat.isCrypto,
            showArrow: !chat.isOncall,
            avatarTapHandler: { [weak self] in
                self?.checkPreviewImage()
            },
            tapHandler: { [weak self] _ in
                guard let self = self, let vc = self.targetVC else {
                    assertionFailure("missing targetVC")
                    return
                }
                NewChatSettingTracker.imChatSettingInfoClick(chatId: chatId, isAdmin: self.isOwner)
                NewChatSettingTracker.imChatSettingClickEditGroupInfo(chat: settingChat)
                if isBot || self.chat.isP2PAi {
                    self.toProfile()
                } else if !isOncall {
                    let body = GroupInfoBody(chatId: chatId)
                    self.userResolver.navigator.push(body: body, from: vc)
                }
            })
        return nameModel
    }

    func groupMembersItem() -> CommonCellItemProtocol? {
        guard self.chat.type != .p2P, !chat.isFrozen else { return nil }
        let isAccessToAddMember = self.hasModifyAccess && (!chat.isCrypto || secretChatEnable)

        let chat = self.chat
        return ChatInfoMemberModel(
            type: .groupMember,
            cellIdentifier: ChatInfoMemberCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Legacy_member,
            avatarModels: members.map { .init(avatarKey: $0.avatarKey, medalKey: $0.medalKey) },
            chatUserCount: chat.isUserCountVisible ? self.chat.userCount : nil,
            memberIds: members.map { $0.id },
            descriptionText: "\(self.chat.userCount)",
            // 如果是密聊，则需要有密聊权限才能添加群成员
            hasAccess: isAccessToAddMember,
            isShowMember: !members.isEmpty,
            isShowDeleteButton: (self.isOwner || self.chat.isGroupAdmin) && chat.chatterCount > 1,
            chat: self.chat,
            tapHandler: { [weak self] _ in
                guard let vc = self?.targetVC, let self = self else {
                    assertionFailure("missing targetVC")
                    return
                }
                NewChatSettingTracker.imChatSettingClick(chat: self.chat,
                                                         myUserId: self.currentUserId,
                                                         isOwner: self.isOwner,
                                                         isAdmin: self.isGroupAdmin,
                                                         extra: ["click": "group_member",
                                                                 "target": "im_group_member_view"
                                                         ])
                NewChatSettingTracker.imChatSettingMemberListPageView(chatId: chat.id,
                                                                      isAdmin: self.isOwner,
                                                                      source: "setting_page")
                let body = GroupChatterDetailBody(chatId: chat.id,
                                                  isShowMulti: false,
                                                  isAccessToAddMember: isAccessToAddMember)
                if Display.phone {
                    self.userResolver.navigator.push(body: body, from: vc)
                } else {
                    self.userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: vc,
                        prepare: { vc in
                            vc.modalPresentationStyle = LarkCoreUtils.formSheetStyle()
                        })
                }
            },
            addNewMember: { [weak self] _ in
                self?.onTapAddNewMember()
            },
            selectedMember: { [weak self] (chatterId) in
                guard let vc = self?.targetVC else {
                    assertionFailure("missing targetVC")
                    return
                }
                ChatSettingTracker.infoMemberIMChatSettingClick(chat: chat)
                let body = PersonCardBody(chatterId: chatterId,
                                          chatId: chat.id,
                                          source: .chat)
                if Display.phone {
                    self?.userResolver.navigator.push(body: body, from: vc)
                } else {
                    self?.userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: vc,
                        prepare: { vc in
                            vc.modalPresentationStyle = .formSheet
                        })
                }
            },
            deleteMember: { [weak self] _ in
                self?.onDeleteMember(isAccessToAddMember: isAccessToAddMember)
            })
    }
}

// MARK: 工具方法
extension ChatSettingInfoModuleViewModel {
    private func refreshMembers() {
        self.getGroupMembers(chatId: chat.id)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.firstScreenGroupMemberReadySubject.onNext(())
                self.structItems()
                self.reloadSubject.onNext(())
            }, onError: { [weak self] (error) in
                self?._errorPublisher.onNext(error)
            }).disposed(by: self.disposeBag)
    }

    private func getGroupMembersBy(_ chatterIds: [String], chatId: String, entity: Basic_V1_Entity) -> Observable<Void> {
        let preloadGroupPreviewChatterCount = self.preloadConfiguration?.preloadGroupPreviewChatterCount ?? 0
        let limit = maxDisplayBotCount + preloadGroupPreviewChatterCount

        let chatters = chatterIds.compactMap { (chatterId) -> Chatter? in
            if let pb = entity.chatChatters[chatId]?.chatters[chatterId] ??
                entity.chatters[chatterId], pb.type == .user {
                return LarkModel.Chatter.transform(pb: pb)
            }
            return nil
        }

        let members = self.moveOwnerToFirst(members: chatters)
        let newMembers = members.prefix(preloadGroupPreviewChatterCount)
        let oldMembers = self.members.prefix(preloadGroupPreviewChatterCount)

        if oldMembers.isEmpty || newMembers.count != oldMembers.count ||
            (0..<oldMembers.count).contains(where: { oldMembers[$0].id != newMembers[$0].id }) {
            self.members = members
            return .just(())
        }
        return .empty()
    }

    func getGroupMembers(chatId: String) -> Observable<Void> {
        guard !chatId.isEmpty, let chatterAPI = self.chatterAPI else { return .empty() }
        // fixbug: https://meego.feishu.cn/larksuite/issue/detail/4511752
        // 目前服务端接口GetChatChatter不支持传入具体要拉取的类型, 比如人/机器人
        // 因此先通过多拉取数量的方式解决此问题, 后续服务端侧支持后可恢复preloadGroupPreviewChatterCount, TODO @zhaodong
        let preloadGroupPreviewChatterCount = self.preloadConfiguration?.preloadGroupPreviewChatterCount ?? 0
        let limit = maxDisplayBotCount + preloadGroupPreviewChatterCount

        if isDefaultAlphabetical {
            return chatterAPI.getOrderChatChatters(chatId: chatId,
                                                   scene: .previewFirstScreen,
                                                   cursor: nil,
                                                   count: limit,
                                                   uid: nil)
                .subscribeOn(schedulerType)
                .flatMap { [weak self] (result) -> Observable<Void> in
                    guard let self = self else { return .empty() }
                    let chatterIds = result.intervalData.chatterIds.compactMap {
                        return String($0)
                    }

                    return self.getGroupMembersBy(chatterIds, chatId: chatId, entity: result.entity)
                }
        }

        let getChatChttersOB = chatterAPI.getChatChatters(
            chatId: chatId,
            filter: nil,
            cursor: nil,
            limit: limit,
            condition: nil,
            forceRemote: false,
            offset: nil,
            fromScene: nil
        )

        return getChatChttersOB
            .subscribeOn(schedulerType)
            .flatMap { [weak self] (result) -> Observable<Void> in
                guard let self = self else { return .empty() }
                // letterMaps 和 chatterIds， 仅有一个有值
                let chatterIds = result.chatterIds.isEmpty ?
                    result.letterMaps.map { $0.chatterIds }.reduce([String](), +) :
                    result.chatterIds

                return self.getGroupMembersBy(chatterIds, chatId: chatId, entity: result.entity)
            }
    }

    func moveOwnerToFirst(members: [LarkModel.Chatter]) -> [LarkModel.Chatter] {
        var result = members
        let ownerIndex = result.firstIndex { (user) -> Bool in
            return user.id == self.chat.ownerId
        }
        if let ownerIndex = ownerIndex {
            let owner = result[ownerIndex]
            result.remove(at: ownerIndex)
            result.insert(owner, at: 0)
        }
        return result
    }

    func onCallDescriptionItem() -> CommonCellItemProtocol? {
        // 仅客服群有群描述
        guard chat.isOncall else { return nil }

        let chatId = chat.id

        return ChatInfoDescriptionItem(
            type: .oncallDescription,
            cellIdentifier: ChatInfoDescriptionCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_HelpDesk_TitleofDesc,
            description: chat.description
        ) { [weak self] _ in
            guard let vc = self?.targetVC else {
                assertionFailure("missing targetVC")
                return
            }
            self?.userResolver.navigator.push(body: ModifyGroupDescriptionBody(chatId: chatId), from: vc)
        }
    }

    func toProfile() {
        guard let vc = targetVC else { return }
        ChatSettingTracker.infoMemberIMChatSettingClick(chat: chat)
        let body = PersonCardBody(chatterId: chat.chatterId,
                                  source: .chat)
        self.userResolver.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: vc,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    private func checkPreviewImage() {
        guard let vc = targetVC else { return }
        let asset = LKDisplayAsset.createAsset(avatarKey: chat.avatarKey, avatarViewParams: .defaultBig, chatID: chat.id).transform()
        let body = PreviewImagesBody(assets: [asset],
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: self.chat.id),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canShareImage: false,
                                     canEditImage: false,
                                     canTranslate: userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)),
                                     translateEntityContext: (nil, .other))
        self.userResolver.navigator.present(body: body, from: vc)
    }

    // MARK: - “群成员”
    // 添加群成员
    func onTapAddNewMember() {
        ChatSettingTracker.trackAddNewClick(chatId: chat.id)
        ChatSettingTracker.trackAddNewGroupMemberClick()
        guard isOwner || isGroupAdmin || chat.addMemberPermission == .allMembers else {
            if let view = self.targetVC?.viewIfLoaded {
                let text = BundleI18n.LarkChatSetting.Lark_Group_OnlyGroupOwnerAdminInviteMembers
                UDToast.showTips(with: text, on: view)
            }
            return
        }
        guard let vc = self.targetVC else {
            assertionFailure("missing targetVC")
            return
        }
        // 外部群 && 非密聊，才有二维码和链接
        if chat.isCrossTenant, !chat.isCrypto {
            let body = ExternalGroupAddMemberBody(chatId: chat.id, source: .sectionAdd)
            self.userResolver.navigator.open(body: body, from: vc)
        } else {
            let body = AddGroupMemberBody(chatId: chat.id, source: .sectionAdd)
            self.userResolver.navigator.open(body: body, from: vc)
        }
    }

    func onDeleteMember(isAccessToAddMember: Bool) {
        guard let vc = self.targetVC else {
            assertionFailure("missing targetVC")
            return
        }

        let body = GroupChatterDetailBody(
            chatId: chat.id,
            isShowMulti: true,
            isAccessToAddMember: isAccessToAddMember)

        if Display.phone {
            self.userResolver.navigator.push(body: body, from: vc)
        } else {
            self.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { vc in
                    vc.modalPresentationStyle = LarkCoreUtils.formSheetStyle()
                })
        }
    }

    func createChatGroup() {
        if chat.chatterHasResign, let view = self.targetVC?.viewIfLoaded {
            UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChatWindowP2pChatterDeactiviedCreateGroupTip, on: view)
            return
        }
        let chatId = self.chat.id
        self.fetchP2PChatterAuthAndHandle(businessType: .groupConfirm) { [weak self] in
            guard let vc = self?.targetVC else {
                assertionFailure("missing targetVC")
                return
            }
            self?.userResolver.navigator.open(body: CreateGroupWithRecordBody(p2pChatId: chatId), from: vc)
            NewChatSettingTracker.imChatSettingAddMemberToP2pClick(chatId: chatId)
        }
    }

    func fetchP2PChatterAuthAndHandle(title: String? = nil,
                                      content: String? = nil,
                                      businessType: AddContactBusinessType,
                                      handler: @escaping () -> Void) {
        contactOptDisposeBag = DisposeBag()
        let displayName = chat.chatter?.displayName ?? ""
        let chatId = chat.id
        let userId = chat.chatter?.id ?? ""

        DelayLoadingObservableWraper.wraper(observable: self.fetchP2PChatterAuth(businessType: businessType),
                                            showLoadingIn: self.targetVC?.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] deniedReason in
                guard let vc = self?.targetVC else {
                    assertionFailure("missing targetVC")
                    return
                }
                if deniedReason == .beBlocked {
                    if let view = vc.viewIfLoaded {
                        UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_IM_CantAddToGroupBlocked_Hover, on: view)
                    }
                } else if deniedReason == .blocked {
                    if let view = vc.viewIfLoaded {
                        UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_NewContacts_BlockedOthersUnableToXToastGeneral, on: view)
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
                                                                        title: title,
                                                                        content: content,
                                                                        targetVC: vc,
                                                                        businessType: businessType)
                    self?.userResolver.navigator.present(body: addContactBody, from: vc)
                } else {
                    handler()
                }
            }, onError: { [weak self] (error) in
                Self.logger.error("fetchP2PChatterAuthAndHandle fail \(chatId) \(String(describing: self?.chat.chatterId))", error: error)
            }).disposed(by: contactOptDisposeBag)
    }

    func fetchP2PChatterAuth(businessType: AddContactBusinessType) -> Observable<RustPB.Basic_V1_Auth_DeniedReason> {
        guard let contactAPI = self.contactAPI else {
            return .empty()
        }
        var actionType: Basic_V1_Auth_ActionType = .inviteSameChat
        switch businessType {
        case .shareConfirm:
            actionType = .shareNameCard
        case .groupConfirm:
            if chat.isCrypto {
                actionType = .inviteSameCryptoChat
            } else if chat.isCrossTenant {
                actionType = .inviteSameCrossTenantChat
            }
        case .buzzConfirm, .hongBaoConfirm, .chatVCConfirm, .vcOnGoingConfirm, .eventConfirm, .bannerConfirm, .onboardingConfirm, .profileAdd:
            break
        }
        return contactAPI
            .fetchAuthChattersRequest(actionType: actionType,
                                      isFromServer: true,
                                      chattersAuthInfo: [chat.chatterId: chat.id])
            .map { [weak self] (response) -> RustPB.Basic_V1_Auth_DeniedReason in
                guard let `self` = self else { return .unknownReason }
                let chatterID = self.chat.chatterId
                let deniedReason = response.authResult.deniedReasons[chatterID]
                return deniedReason ?? .unknownReason
            }
    }
}

struct FirstScreenReadyState {
    var chatReady = false
    var groupMemberReady = false
    var chatChatterReady = false

    func isFinish() -> Bool {
        return chatReady && groupMemberReady && chatChatterReady
    }
}
