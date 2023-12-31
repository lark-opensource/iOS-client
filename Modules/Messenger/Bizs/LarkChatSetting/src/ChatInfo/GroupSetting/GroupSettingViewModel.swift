//
//  GroupSettingViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/19.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkActionSheet
import LarkUIKit
import EENavigator
import LarkCore
import UniverseDesignToast
import UniverseDesignDialog
import LarkBadge
import LarkAlertController
import LarkFeatureGating
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkAccountInterface
import LKCommonsTracker
import LarkContainer
import Homeric
import SuiteAppConfig
import UniverseDesignActionPanel
import UniverseDesignFont
import ThreadSafeDataStructure
import LarkNavigation
import LarkSetting
import LarkMessageCore
import RustPB

final class GroupSettingViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(GroupSettingViewModel.self, category: "Module.IM.LarkChatSetting")
    private(set) var disposeBag = DisposeBag()
    private var _items: SafeAtomic<CommonDatasource> = [] + .readWriteLock
    private(set) var items: CommonDatasource {
        get { _items.value }
        set { _items.value = newValue }
    }
    private(set) var isOwner: Bool
    private(set) var chatAPI: ChatAPI
    private(set) var chatterAPI: ChatterAPI
    private let chatWrapper: ChatPushWrapper
    private var chatService: ChatService
    private var currentUserId: String
    private let isThread: Bool
    private var allowApplyForMemberUpperLimit = false
    var showAlert: ((_ title: String, _ message: String) -> Void)?
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chatModel.isGroupAdmin
    }
    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    // 群管理需求 https://bytedance.feishu.cn/docs/doccnxBIe1g1qLMdZPJvYOaxhjb#
    @FeatureGating("im.chat.only.admin.can.pin.vc.buzz") var groupPermissionLimit: Bool

    @ScopedInjectedLazy private var topNoticeService: ChatTopNoticeService?
    @ScopedInjectedLazy private var contactAPI: ContactAPI?

    weak var controller: GroupSettingViewController?

    var chatModel: LarkModel.Chat

    let isCrossTenant: Bool
    let scrollToBottom: Bool
    let openSettingCellType: CommonCellItemType?
    private let calendarInterface: ChatSettingCalendarDependency
    private var shouldShowToNormalGroup: Bool { isOwner && chatModel.isMeeting }
    private var adminMembers: [LarkModel.Chatter] = []

    // 标记是否忽略chat变更的Push
    private var ignoreChatPush: Bool = false

    private var canShowDynamicRule = false

    private var canShowAllowGroupSearchedCell = true
    private var isShowAllowGroupSearchedCell: Bool {
        userResolver.fg.staticFeatureGatingValue(with: "im.chat.searchable.group") && canShowAllowGroupSearchedCell
    }

    // 前端判断是否允许有群邮箱地址/群邮箱权限设置
    private var groupEmailSettingEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "im.chat.setting.group.mail")
        && !chatModel.isCrypto // 密盾聊
        && !chatModel.isPrivateMode // 密聊
        && chatModel.chatMode != .threadV2 // 话题群
        && (!chatModel.isOncall || chatModel.oncallId.isEmpty || chatModel.oncallId == "0") // Oncall群
        && !chatModel.isCustomerService // 客服群
        && !chatModel.isCrossTenant // 外部群
        && !chatModel.isSuper // 超大群
    }
    // “谁可以向此群发送邮件”功能是否应该展示
    // 租户没有域名等情况，前端无法感知，实现方案为：请求Mail后端接口后再决定是否展示
    private var groupEmailSettingShouldShow = false

    private let scheduler = SerialDispatchQueueScheduler(qos: .default)

    private var memberCount: Int32 {
        chatModel.userCount
    }
    private let messageVisibilitySwitchEvent = PublishSubject<Bool>()
    private var pushChatAdmin: Observable<PushChatAdmin>
    private lazy var enableRestrictedModeSetting: Bool = {
        return !self.isThread &&
        self.chatModel.type != .p2P &&
        !chatModel.isCrypto &&
        userResolver.fg.staticFeatureGatingValue(with: "im.chat.restrictedmode")
    }()
    private var showHideUserCountItem: Bool = false
    private lazy var enableHideUserCount: Bool = {
        return self.chatModel.type != .p2P &&
            !chatModel.isCrypto &&
            userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.hide_group_members")
    }()
    private lazy var restrictedModeService: RestrictedModeService = {
        return RestrictedModeService(chatAPI: self.chatAPI, chat: self.chatModel)
    }()

    init(resolver: UserResolver,
         chatWrapper: ChatPushWrapper,
         chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         currentUserId: String,
         chatService: ChatService,
         pushChatAdmin: Observable<PushChatAdmin>,
         calendarInterface: ChatSettingCalendarDependency,
         scrollToBottom: Bool,
         openSettingCellType: CommonCellItemType?
    ) {
        self.userResolver = resolver
        self.chatWrapper = chatWrapper
        self.isThread = (chatWrapper.chat.value.chatMode == .threadV2)
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.currentUserId = currentUserId
        self.chatService = chatService
        self.pushChatAdmin = pushChatAdmin
        self.calendarInterface = calendarInterface
        self.scrollToBottom = scrollToBottom
        self.openSettingCellType = openSettingCellType
        self.chatModel = chatWrapper.chat.value
        self.isCrossTenant = chatModel.isCrossTenant
        self.isOwner = (currentUserId == chatModel.ownerId)
        self.items = self.structureItems()
    }

    func fetchData() {
        let chatId = chatModel.id
        let fetchRemoteChat: Observable<Chat> = chatAPI.fetchChat(by: chatId, forceRemote: true)
            .compactMap { $0 }

        // 拉取chat
        Observable.merge([fetchRemoteChat, chatWrapper.chat.asObservable()])
            .debounce(.milliseconds(500), scheduler: scheduler)
            .observeOn(scheduler)
            .filter { [weak self] in
                guard let self = self else { return false }

                return !self.ignoreChatPush && $0.id == chatId
            }
            .subscribe(onNext: { [weak self] (chat) in
                guard let `self` = self else { return }
                self.chatModel = chat
                self.isOwner = self.currentUserId == chat.ownerId
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }).disposed(by: self.disposeBag)

        // 拉取群管理员
        chatAPI.fetchChatAdminUsersWithLocalAndServer(chatId: chatId)
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                self.adminMembers = res
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }, onError: { (error) in
                Self.logger.error("fetchChatAdminUsers error, error = \(error)")
            }).disposed(by: self.disposeBag)

        pushChatAdmin
            .filter { $0.chatId == chatId }
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.adminMembers = push.adminUsers
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }).disposed(by: disposeBag)

        chatAPI.getDynamicRuleOptionSettings(chatId: chatId)
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] opts in
                guard let self = self else { return }
                self.canShowDynamicRule = !opts.setting.isEmpty
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }).disposed(by: disposeBag)

        //拉取（租户纬度）是否允许申请群成员上限
        if let tenantId = Int64(chatModel.tenantId),
           let chatId = Int64(chatId) {
            chatAPI.pullChatMemberSetting(tenantId: tenantId, chatId: chatId)
                .observeOn(scheduler)
                .subscribe { [weak self] res in
                    guard let self = self else { return }
                    self.allowApplyForMemberUpperLimit = res.allowApply
                    self.items = self.structureItems()
                    self._reloadData.onNext(())
                } onError: { error in
                    Self.logger.error("pullChatMemberSetting error, error = \(error)")
                } .disposed(by: disposeBag)
        }

        // 拉取当前用户的公开群权限
        contactAPI?.fetchAuthChattersWithLocalAndServer(actionType: .allowSettingAsPublicGroup,
                                                       chattersAuthInfo: [self.currentUserId: chatId])
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                if let deniedReason = res.authResult.deniedReasons[self.currentUserId] {                    self.canShowAllowGroupSearchedCell = false
                }
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }, onError: { (error) in
                Self.logger.error("fetchAuthChattersWithLocalAndServer error, error = \(error)")
            }).disposed(by: self.disposeBag)

        if enableRestrictedModeSetting {
            self.restrictedModeService.switchStatusChange
                .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                    self?._reloadData.onNext(())
                }).disposed(by: self.disposeBag)
        }

        // 拉取群邮箱权限设置信息
        // 前端能判断的情况直接过滤，减少请求次数
        if groupEmailSettingEnable {
            chatAPI.getChatGroupAddress(chatId: chatId)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] (res) in
                    guard let self = self else { return }
                    switch res.status {
                    case .exist, .notExist:
                        self.groupEmailSettingShouldShow = true
                        self.items = self.structureItems()
                        self._reloadData.onNext(())
                    case .noPerm:
                        break
                    @unknown default:
                        assertionFailure("Unknown status type")
                    }
                }, onError: { (error) in
                    GroupSettingViewModel.logger.error("getGroupMailAddress error", error: error)
                }).disposed(by: self.disposeBag)
        }

        if enableHideUserCount {
            let actionTypes: [Im_V1_ChatSwitchRequest.ActionType] = [.userCountVisibleSetting]
            let userCountVisibleRawValue = Im_V1_ChatSwitchRequest.ActionType.userCountVisibleSetting.rawValue
            let chatID = chatModel.id
            self.chatAPI.getChatSwitch(chatId: chatID, actionTypes: actionTypes, formServer: false)
                .catchError({ error -> Observable<[Int: Bool]> in
                    Self.logger.error("getUserCountVisibleSettingSwitch from local error \(chatID)", error: error)
                    return .just([:])
                })
                .observeOn(MainScheduler.instance)
                .flatMap { [weak self] localResult -> Observable<[Int: Bool]> in
                    guard let self = self else { return .empty() }
                    Self.logger.info("getUserCountVisibleSettingSwitch from local info \(chatID) \(localResult)")
                    if localResult[userCountVisibleRawValue] != self.showHideUserCountItem {
                        self.showHideUserCountItem = localResult[userCountVisibleRawValue] ?? false
                        self.items = self.structureItems()
                        self._reloadData.onNext(())
                    }
                    return self.chatAPI.getChatSwitch(chatId: chatId, actionTypes: actionTypes, formServer: true)
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] serverResult in
                    guard let self = self else { return }
                    Self.logger.info("getUserCountVisibleSettingSwitch from server info \(chatID) \(serverResult)")
                    if serverResult[userCountVisibleRawValue] != self.showHideUserCountItem {
                        self.showHideUserCountItem = serverResult[userCountVisibleRawValue] ?? false
                        self.items = self.structureItems()
                        self._reloadData.onNext(())
                    }
                }, onError: { error in
                    Self.logger.error("getUserCountVisibleSettingSwitch from server error \(chatID)", error: error)
                }).disposed(by: self.disposeBag)
        }
    }

    func observeData() {
        messageVisibilitySwitchEvent
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] (isOn) in
                self?.switchMessageVisibilitySetting(newStatus: isOn)
            }).disposed(by: self.disposeBag)
    }
}

// section 组装的扩展
private extension GroupSettingViewModel {
    func modeChangeSection() -> CommonSectionModel? {
        let fg = userResolver.fg.staticFeatureGatingValue(with: "message.thread.groupmode")
        guard fg, self.chatModel.type != .p2P, !self.chatModel.isCrypto,
              !self.chatModel.isSuper, !chatModel.isPrivateMode, !self.chatModel.isOncall,
              self.chatModel.chatMode != .threadV2, !self.chatModel.isOfflineOncall,
              self.isOwner || self.isGroupAdmin else {
            return nil
        }
        return CommonSectionModel(title: BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_Title, items: [groupModeItem()].compactMap { $0 })
    }

    // 成员权限管理section
    func memberAuthManagerSection() -> CommonSectionModel {
        CommonSectionModel(
            title:
                BundleI18n.LarkChatSetting.Lark_Chat_MemberPermissionManagement,
            items: [
                groupAdminsItem(),
                editItem(),
                shareAndAddNewPermissionItem(),
                videoMeettingConfigurationItem(),
                atAllItem(),
                urgentConfigurationItem(),
                pinConfigurationItem(),
                topNoticeItem(),
                chatTabsMenuWidgetsItem(),
                chatPinItem(),
                banningItem(),
                mailPermissionItem()
                ].compactMap { $0 }
        )
    }

    //保密设置管理
    func privacySettingsSection() -> CommonSectionModel? {

        var items: [GroupSettingItemProtocol] = [hideUserCountItem()].compactMap { $0 }
        if enableRestrictedModeSetting, self.restrictedModeService.hasRestrictedMode {
            items.append(contentsOf: [preventMessageLeakItem(),
                                      forbiddenMessageCopyForward(),
                                      forbiddenDownloadResource(),
                                      forbiddenScreenCapture(),
                                      messageBurnTime(),
                                      preventMessageWhiteList()
                                     ].compactMap { $0 })
        }
        if items.isEmpty {
            return nil
        }
        return CommonSectionModel(
            title: BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_ContentPermissions_Title,
            items: items
        )
    }

    // 进群管理section
    func joininSection() -> CommonSectionModel {
        CommonSectionModel(
            title:
                BundleI18n.LarkChatSetting.Lark_Legacy_InvitationSettings,
            description: isShowAllowGroupSearchedCell ? nil : BundleI18n.LarkChatSetting.Lark_IM_GroupNotPublicDueToOrgSecuritySettings_Hover,
            items: [
                approvalItem(),
                allowGroupSearchedItem(),
                messageVisibilityItem(),
                whenJoinItem(),
                whenLeaveItem(),
                automaticallyAddGroup(),
                joinAndLeaveItem(),
                shareHistoryItem(),
                applyForMemberLimitItem()
                ].compactMap { $0 }
        )
    }

    // 转让群主的section
    func transferSection() -> CommonSectionModel? {
        let transferItem = GroupSettingTransferItem(
            type: .transfer,
            cellIdentifier: GroupSettingTransferCell.lu.reuseIdentifier,
            style: .auto,
            title:
                BundleI18n.LarkChatSetting.Lark_Legacy_AssignGroupOwner
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.transfer()
            self.imGroupManageClickTrack(clickType: "transfer_group_owner")
        }
        return CommonSectionModel(title: nil, items: [self.isOwner ? transferItem : nil].compactMap({ $0 }))
    }

    // 转为普通群组的section
    func toNormalGroupSection() -> CommonSectionModel? {
        guard !chatModel.isCustomerService, shouldShowToNormalGroup else { return nil }

        let toNormalGroup = GroupSettingToNormalGroupModel(
            type: .toNormalGroup,
            cellIdentifier: GroupSettingToNormalGroupCell.lu.reuseIdentifier,
            style: .none,
            attributedText: NSAttributedString(string: BundleI18n.LarkChatSetting.Calendar_Setting_TransformToNormalGroup,
                                               attributes: [.foregroundColor: UIColor.ud.primaryContentDefault])
        ) { [weak self] _ in
            self?.turnIntoNormalGroup()
        }
        return CommonSectionModel(title: nil, items: [toNormalGroup])
    }
}

// cell(item) 组装的扩展
private extension GroupSettingViewModel {
    // who can start video meetting
    func videoMeettingConfigurationItem() -> CommonCellItemProtocol? {
        guard groupPermissionLimit else { return nil }
        /// limit from https://bytedance.feishu.cn/docs/doccnxBIe1g1qLMdZPJvYOaxhjb#
        if chatModel.chatMode == .threadV2 || chatModel.isCrypto ||
            chatModel.isOfflineOncall || chatModel.isSuper || chatModel.isPrivateMode {
            return nil
        }
        // convert permission setting to subtitle
        let subTitle: String
        switch chatModel.createVideoConferenceSetting {
        case .allMembers:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
        case .onlyManager:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
        case .none, .some(_):
            Self.logger.info("videoMeettingConfigurationItem accept a unknown type: \(chatModel.createVideoConferenceSetting?.rawValue)")
            assertionFailure("unknown type")
            subTitle = ""
        @unknown default:
            assertionFailure("unknown type")
            subTitle = ""
        }
        return VideoMettingConfigurationItem(type: .videoMeettingConfiguration,
                                             cellIdentifier: VideoMettingConfigurationCell.lu.reuseIdentifier,
                                             style: .half,
                                             title: BundleI18n.LarkChatSetting.Lark_GroupManagement_StartVideoCalls,
                                             detail: subTitle,
                                             tapHandler: { [weak self] cell in
                                                 self?.showVideoMeettingConfigrationAlert(in: cell)
                                             })
    }

    // who can urgent
    func urgentConfigurationItem() -> CommonCellItemProtocol? {
        guard groupPermissionLimit else { return nil }
        /// limit from https://bytedance.feishu.cn/docs/doccnxBIe1g1qLMdZPJvYOaxhjb#
        if chatModel.chatMode == .threadV2 || chatModel.isCrypto ||
            chatModel.isOfflineOncall || chatModel.isSuper {
            return nil
        }
        // convert permission setting to subtitle
        let subTitle: String
        switch chatModel.createUrgentSetting {
        case .allMembers:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
        case .onlyManager:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
        case .none, .some(_):
            Self.logger.info("urgentConfigurationItem accept a unknown type: \(chatModel.createUrgentSetting?.rawValue)")
            assertionFailure("unknown type")
            subTitle = ""
        @unknown default:
            assertionFailure("unknown type")
            subTitle = ""
        }
        return UrgentConfigurationItem(type: .urgentConfiguration,
                                       cellIdentifier: UrgentConfigurationCell.lu.reuseIdentifier,
                                       style: .half,
                                       title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanBuzzOthers,
                                       detail: subTitle,
                                       tapHandler: { [weak self] cell in
                                           self?.showUrgentConfigrationAlert(in: cell)
                                       })
    }

    // who can pin
    func pinConfigurationItem() -> CommonCellItemProtocol? {
        guard !supportChatPinPermissionEntrance else { return nil }
        guard groupPermissionLimit else { return nil }
        guard !ChatNewPinConfig.supportPinMessage(chat: chatModel, self.userResolver.fg) else { return nil }
        /// limit from https://bytedance.feishu.cn/docs/doccnxBIe1g1qLMdZPJvYOaxhjb#
        if chatModel.isCrypto || chatModel.isOfflineOncall || chatModel.isSuper || chatModel.isPrivateMode {
            return nil
        }
        let supportNewPermission = ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg)
        let subTitle: String
        if supportNewPermission {
            subTitle = getChatPinAlertSubTitle()
        } else {
            switch chatModel.pinPermissionSetting {
            case .allMembers:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
            case .onlyManager:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
            case .none, .some(_):
                Self.logger.info("pinConfigurationItem accept a unknown type: \(chatModel.pinPermissionSetting?.rawValue)")
                assertionFailure("unknown type")
                subTitle = ""
            @unknown default:
                assertionFailure("unknown type")
                subTitle = ""
            }
        }
        return PinConfigurationItem(type: .pinConfiguration,
                                    cellIdentifier: PinConfigurationCell.lu.reuseIdentifier,
                                    style: .half,
                                    title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanPin,
                                    detail: subTitle,
                                    tapHandler: { [weak self] cell in
            guard let self = self else { return }
            if supportNewPermission {
                self.showChatPinConfigrationAlert(in: cell, title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanPin, clickType: "pin_restriction")
            } else {
                self.showPinConfigrationAlert(in: cell)
            }
        })
    }

    /// 置顶的消息
    func topNoticeItem() -> GroupSettingItemProtocol? {
        if supportChatPinPermissionEntrance {
            return nil
        }
        if !(topNoticeService?.isSupportTopNoticeChat(chatModel) ?? false) {
            return nil
        }
        if ChatNewPinConfig.supportPinMessage(chat: chatModel, self.userResolver.fg) {
            return nil
        }
        let title = self.getTitleForTopNoticeItem()
        let supportNewPermission = ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg)
        let subTitle: String
        if supportNewPermission {
            subTitle = getChatPinAlertSubTitle()
        } else {
            let setting = chatModel.topNoticePermissionSetting
            switch setting {
            case .allMembers:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
            case .onlyManager:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
            case .unknown:
                Self.logger.info("topNoticeItem accept a unknown type: \(setting.rawValue)")
                assertionFailure("unknown type")
                subTitle = ""
            @unknown default:
                assertionFailure("new type")
                subTitle = ""
            }
        }
        return topNoticeConfigurationItem(
            type: .topNotice,
            cellIdentifier: topNoticeConfigurationCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: subTitle
        ) { [weak self] (cell) in
            guard let self = self else { return }
            if supportNewPermission {
                self.showChatPinConfigrationAlert(in: cell, title: title, clickType: "pin_to_top_restriction")
            } else {
                self.showTopNoticeConfigrationAlert(in: cell)
            }
        }
    }

    var tabsMenuWidgetsPermissionTitle: String {
        if userResolver.fg.staticFeatureGatingValue(with: "im.chat.widget.permission") {
            return BundleI18n.LarkChatSetting.Lark_Group_WhoCanManageTabsWidgets_Settings_Text
        } else if userResolver.fg.staticFeatureGatingValue(with: "im.chat.input.menu.editor") {
            return BundleI18n.LarkChatSetting.Lark_GroupSettings_WhoCanManageTabsMenuWidgets_Text
        } else {
            return BundleI18n.LarkChatSetting.Lark_IM_Tabs_WhoCanManageTabs_Settings_Title
        }
    }

    var supportChatPinPermissionEntrance: Bool {
        return ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg)
    }

    // 群 New Pin 权限
    func chatPinItem() -> GroupSettingItemProtocol? {
        if isThread {
            if self.supportChatPinPermissionEntrance {
                let title = BundleI18n.LarkChatSetting.Lark_IM_TopicGroupOld_WhoCanPinClip_Title
                return ChatPinAuthConfigurationItem(
                    type: .chatPinAuth,
                    cellIdentifier: ChatPinAuthConfigurationCell.lu.reuseIdentifier,
                    style: .half,
                    title: title,
                    detail: getChatPinAlertSubTitle()
                ) { [weak self] (cell) in
                    guard let self = self else { return }
                    self.showChatPinConfigrationAlert(in: cell, title: title, clickType: "new_pin_restriction")
                }
            } else {
                return nil
            }
        } else {
            guard ChatNewPinConfig.checkEnable(chat: chatModel, self.userResolver.fg) || self.supportChatPinPermissionEntrance else { return nil }
            let title: String
            if ChatNewPinConfig.supportPinMessage(chat: chatModel, self.userResolver.fg) || ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg) {
                title = BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_WhoManagePinnedCombined_Text
            } else {
                title = BundleI18n.LarkChatSetting.Lark_GroupSettings_WhoCanManagePinnedItems_Text
            }
            if ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg) {
                return ChatPinAuthConfigurationItem(
                    type: .chatPinAuth,
                    cellIdentifier: ChatPinAuthConfigurationCell.lu.reuseIdentifier,
                    style: .half,
                    title: title,
                    detail: getChatPinAlertSubTitle()
                ) { [weak self] (cell) in
                    guard let self = self else { return }
                    self.showChatPinConfigrationAlert(in: cell, title: title, clickType: "new_pin_restriction")
                }
            } else {
                let setting = chatModel.chatTabPermissionSetting
                let subTitle: String
                switch setting {
                case .allMembers:
                    subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
                case .onlyManager:
                    subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
                case .unknown:
                    Self.logger.info("chatPinItem \(chatModel.id) accept a unknown type: \(setting.rawValue)")
                    assertionFailure("unknown type")
                    subTitle = ""
                @unknown default:
                    assertionFailure("new type")
                    subTitle = ""
                }
                return ChatPinAuthConfigurationItem(
                    type: .chatPinAuth,
                    cellIdentifier: ChatPinAuthConfigurationCell.lu.reuseIdentifier,
                    style: .half,
                    title: title,
                    detail: subTitle
                ) { [weak self] (cell) in
                    guard let self = self else { return }
                    self.showChatTabsMenuWidgetsConfigrationAlert(in: cell, title: title, clickType: "new_pin_restriction")
                }
            }
        }
    }

    // 群 tab 、群菜单、群 widgets 权限
    func chatTabsMenuWidgetsItem() -> GroupSettingItemProtocol? {
        guard !supportChatPinPermissionEntrance,
              !isThread,
              !chatModel.isOncall,
              !chatModel.isCrypto,
              !ChatNewPinConfig.checkEnable(chat: chatModel, self.userResolver.fg),
              userResolver.fg.staticFeatureGatingValue(with: "im.chat.titlebar.tabs.202203"),
              userResolver.fg.staticFeatureGatingValue(with: "im.chat.tabs.permission.to.edit") else {
                  return nil
              }
        let supportNewPermission = ChatPinPermissionUtils.supportNewPermission(self.userResolver.fg)
        let subTitle: String
        if supportNewPermission {
            subTitle = getChatPinAlertSubTitle()
        } else {
            let setting = chatModel.chatTabPermissionSetting
            switch setting {
            case .allMembers:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
            case .onlyManager:
                subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
            case .unknown:
                Self.logger.info("chatTabsMenuWidgetsItem \(chatModel.id) accept a unknown type: \(setting.rawValue)")
                assertionFailure("unknown type")
                subTitle = ""
            @unknown default:
                assertionFailure("new type")
                subTitle = ""
            }
        }
        return ChatTabsMenuWidgetsConfigurationItem(
            type: .chatTabsMenuWidgetsAuth,
            cellIdentifier: ChatTabsMenuWidgetsConfigurationCell.lu.reuseIdentifier,
            style: .half,
            title: tabsMenuWidgetsPermissionTitle,
            detail: subTitle
        ) { [weak self] (cell) in
            guard let self = self else { return }
            if supportNewPermission {
                self.showChatPinConfigrationAlert(in: cell, title: self.tabsMenuWidgetsPermissionTitle, clickType: "tab_restriction")
            } else {
                self.showChatTabsMenuWidgetsConfigrationAlert(in: cell, title: self.tabsMenuWidgetsPermissionTitle, clickType: "tab_restriction")
            }
        }
    }

    private func getChatPinAlertSubTitle() -> String {
        let setting = chatModel.chatPinPermissionSetting
        let subTitle: String
        switch setting {
        case .allMembers:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
        case .onlyManager:
            subTitle = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
        case .unknown:
            Self.logger.info("chatPinItem \(chatModel.id) accept a unknown type: \(setting.rawValue)")
            assertionFailure("unknown type")
            subTitle = ""
        @unknown default:
            assertionFailure("new type")
            subTitle = ""
        }
        return subTitle
    }

    //群模式（普通 or 话题）
    func groupModeItem() -> CommonCellItemProtocol? {
        let chat = chatModel
        var disableSelect: Bool = false
        if !chat.displayInThreadMode, chat.enableMessageBurn {
            //当前是普通模式，且打开了消息自动删除，不允许切换到话题模式
            Self.logger.info("chat groupModeItem disableSelect \(self.chatModel.id) \(chat.displayInThreadMode) \(chat.enableMessageBurn)")
            disableSelect = true
        }
        return ChatInfoModeChangeModel(type: .groupMode,
                                       cellIdentifier: ChatInfoModeChangeCell.lu.reuseIdentifier,
                                       style: .none,
                                       selectedMode: chat.displayInThreadMode ? .thread : .normal,
                                       disableSelect: disableSelect,
                                       modeChange: { [weak self] selected in
            guard let self = self, let vc = self.controller else { return }
            let clickType = selected == .thread ? "thread_mode" : "normal_mode"
            self.imGroupManageClickTrack(clickType: clickType, target: "im_group_mode_change_confirm_view")

            let alertController = LarkAlertController()
            let title = selected == .thread ? BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_SwitchToTopicMode_Title
            : BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_SwitchToChatMode_Title
            alertController.setTitle(text: title, alignment: .center)
            let content = selected == .thread ? BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_SwitchToTopicMode_Desc
            : BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_SwitchToChatMode_Desc
            alertController.setContent(text: content)
            alertController.addCancelButton(dismissCheck: { [weak self] in
                self?._reloadData.onNext(())
                return true
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                let hud = UDToast.showLoading(on: vc.view)
                self.parsingUserOperation(self.chatAPI.updateChat(chatId: chat.id, displayModeInThread: selected == .thread),
                                          logMessage: "displayMode switch set faild \(selected)",
                                          alertMessage: nil,
                                          successHandler: {
                    hud.remove()
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSwitched_Toast, on: vc.view)
                },
                                          failedHandler: { [weak self] in
                    hud.remove()
                    self?._reloadData.onNext(())
                })
                NewChatSettingTracker.imGroupModeChangeConfirmClick(chat: chat, toMode: selected)
            })
            self.userResolver.navigator.present(alertController, from: vc)
        },
                                       disableModeChangeClick: { [weak self] toSelect in
            guard let self = self, let vc = self.controller else { return }
            if toSelect == .thread {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_IM_TopicsNotOkforSelfDestruct_Desc, on: vc.view)
            } else {
                Self.logger.error("chat groupModeItem disableSelect callback except \(self.chatModel.id)")
            }
        })
    }

    // 群管理员
    func groupAdminsItem() -> CommonCellItemProtocol? {
        let chat = chatModel
        guard chat.type != .p2P, self.isOwner else { return nil }
        let isAccessToAddMember = true
        let descriptionText = adminMembers.isEmpty ? BundleI18n.LarkChatSetting.Lark_Legacy_AddGroupAdmins_Mobile
            : "\(adminMembers.count) / \(chat.userCount > 5000 ? 20 : 10)"
        return ChatAdminMemberModel(
            type: .groupMember,
            cellIdentifier: ChatAdminMemberCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAdminsTitle,
            avatarModels: adminMembers.map { .init(avatarKey: $0.avatarKey, medalKey: $0.medalKey) },
            chatUserCount: chat.userCount,
            memberIds: adminMembers.map { $0.id },
            descriptionText: descriptionText,
            hasAccess: isAccessToAddMember,
            isShowMember: !adminMembers.isEmpty,
            isShowDeleteButton: self.isOwner && chat.chatterCount > 1,
            chat: chat,
            tapHandler: { [weak self] _ in
                self?.imGroupManageClickTrack(clickType: "group_admin_member", target: "im_group_admin_view")
                self?.groupAdminsCellTapped()
            },
            addNewMember: { [weak self] _ in self?.onTapAddNewAdmin() },
            selectedMember: { [weak self] (chatterId) in self?.selectedMember(chatterId: chatterId) },
            deleteMember: { [weak self] _ in
                guard let self = self, let vc = self.controller else {
                    assertionFailure("reduce targetVC to jump")
                    return
                }
                let body = GroupAdminBody(chat: chat,
                                          isShowMulti: true)
                self.userResolver.navigator.push(body: body, from: vc)
            })
    }

    func editItem() -> GroupSettingItemProtocol {
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_EditGroupInfo
        let count = self.memberCount
        let chatId = chatModel.id
        let permission = chatModel.offEditGroupChatInfo ?
            BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin :
            BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup

        return EditGroupInfoConfigurationItem(
            type: .edit,
            cellIdentifier: EditGroupInfoConfigurationCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: permission
        ) { [weak self] (cell) in
            guard let self = self else { return }
            self.showGroupInfoConfigurationAlert(in: cell)
        }
    }

    private func chatCanBeShared(_ chat: Chat) -> Bool {
        return chatModel.isPublic
    }

    // 仅群主可添加群成员、分享群
    func shareAndAddNewPermissionItem() -> GroupSettingItemProtocol? {
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_ManageGroupMembersShareGroup
        let chatId = chatModel.id
        let sharePermission = chatModel.shareCardPermission
        let addPermission = chatModel.addMemberPermission
        let count = self.memberCount
        let status = (sharePermission == .notAllowed && addPermission == .allMembers) || (chatModel.addMemberPermission == .onlyOwner) ?
            BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin :
            BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
        return ShareAndAddNewPermissionItem(
            type: .shareAndAddNewPermission,
            cellIdentifier: ShareAndAddNewPermissionCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: status
        ) { [weak self] (cell) in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("lose targetVC to jump")
                return
            }
            self.showShareAndAddNewAlert(in: cell)
        }
    }

    func showShareAndAddNewAlert(in view: UIView) {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let permission = self.chatModel.addMemberPermission == .allMembers && self.chatModel.shareCardPermission == .allowed
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_ManageGroupMembersShareGroup,
                                        in: view,
                                        clickType: "add_member_share_group",
                                        items: [.allMembers, .onlyOwner]) { type in
            switch type {
            case .allMembers:
                guard permission != true else { return }
                self.switchShareCardAndAddNewPermission(newStatus: true)
            case .onlyOwner:
                guard permission != false else { return }
                // 公开群需要弹窗提醒，并联动关闭公开性开关
                if self.chatModel.isPublic {
                    let alert = LarkAlertController()
                    alert.setContent(text: BundleI18n.LarkChatSetting.Lark_Group_MustTurnOnBothTitle)
                    alert.addCancelButton(dismissCompletion: {
                    })
                    alert.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm, dismissCompletion: {
                        self.closeChatCanSearchSetting()
                    })
                    self.userResolver.navigator.present(alert, from: vc)
                } else {
                    self.switchShareCardAndAddNewPermission(newStatus: false)
                }
            @unknown default:
                assertionFailure("unknonw type")
            }
        }
    }

    func shareHistoryItem() -> GroupSettingItemProtocol? {
        if chatCanBeShared(chatModel) ||
            !userResolver.fg.staticFeatureGatingValue(with: .init(key: .groupShareHistory))
            || !AppConfigManager.shared.feature(for: .groupShareHistory).isOn {
            return nil
        }

        let chatID = self.chatModel.id
        let title =
            BundleI18n.LarkChatSetting.Lark_Group_SharingHistoryDescription
        return GroupShareHistoryItem(
            type: .shareHistory,
            cellIdentifier: GroupShareHistoryCell.lu.reuseIdentifier,
            style: .auto,
            title: title
        ) {  [weak self] (_) in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            ChatSettingTracker.newShareHistoryClick(chatId: chatID)
            self.imGroupManageClickTrack(clickType: "group_share_history")
            self.userResolver.navigator.push(body: GroupShareHistoryBody(chatId: chatID,
                                                              title: title,
                                                              isThreadGroup: self.isThread),
                                  from: vc)
        }
    }

    func automaticallyAddGroup() -> GroupSettingItemProtocol? {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.auto_join_depart_group") else { return nil }
        guard !(chatModel.isPublic || chatModel.isCrypto || chatModel.isCrossTenant || chatModel.isPrivateMode), self.canShowDynamicRule else { return nil }
        let title = BundleI18n.LarkChatSetting.Lark_GroupSettings_WhoCanAutoJoin_Title
        let chatID = self.chatModel.id
        return AutomaticallyAddGroupItem(
            type: .automaticallyAddGroup,
            cellIdentifier: AutomaticallyAddGroupItemCell.lu.reuseIdentifier,
            style: .auto,
            title: title
        ) { [weak self] _ in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            self.chatAPI
                .getDynamicRule(chatId: chatID)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self, weak vc] (res) in
                    guard let vc = vc, let self = self else {
                        assertionFailure("reduce targetVC to jump")
                        return
                    }
                    if res.rules.isEmpty {
                        UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_NoRules_Mobile_Toast, on: vc.view)
                        return
                    }
                    self.userResolver.navigator.push(body: AutomaticallyAddGroupBody(chatId: chatID, rules: res.rules),
                                                     from: vc)
                }.disposed(by: self.disposeBag)
        }
    }

    /// group member join and leave history
    /// 群成员进退群历史
    func joinAndLeaveItem() -> GroupSettingItemProtocol? {
        let chatID = self.chatModel.id
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_ViewJoinAndLeaveHistory
        guard AppConfigManager.shared.feature(for: .enterLeaveGroupHistory).isOn else { return nil }
        return JoinAndLeaveEntryItem(
            type: .joinAndLeave,
            cellIdentifier: JoinAndLeaveEntryCell.lu.reuseIdentifier,
            style: .auto,
            title: title
        ) { [weak self] _ in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            self.imGroupManageClickTrack(clickType: "member_inout_history")
            ChatSettingTracker.newViewJoinLeaveHistory(chatId: chatID)
            self.userResolver.navigator.push(body: JoinAndLeaveBody(chatId: chatID), from: vc)
        }
    }

    func approvalItem() -> GroupSettingItemProtocol? {
        let chatID = self.chatModel.id

        let statusString = chatModel.addMemberApply == .needApply ?
            BundleI18n.LarkChatSetting.Lark_Legacy_OpenNow :
            BundleI18n.LarkChatSetting.Lark_Legacy_MineMessageSettingClose
        return GroupSettingApproveItem(
            type: .approval,
            cellIdentifier: GroupSettingApproveCell.lu.reuseIdentifier,
            style: .half,
            title:
                BundleI18n.LarkChatSetting.Lark_Group_ApproveInvitation,
            detail:
                BundleI18n.LarkChatSetting.Lark_Group_ApproveInvitationDescription,
            status: statusString,
            badgePath: self.approve,
            showBadge: chatModel.showApplyBadge
        ) { [weak self] _ in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            self.userResolver.navigator.push(body: ApprovalBody(chatId: chatID), from: vc)
        }
    }

    //申请群成员上限
    private func applyForMemberLimitItem() -> GroupSettingItemProtocol? {
        let chatID = self.chatModel.id

        let title = BundleI18n.LarkChatSetting.Lark_GroupLimit_GroupSizeAppeal_Option
        if !allowApplyForMemberUpperLimit {
            return nil
        }
        return GroupSettingTransferItem(
            type: .applyForMemberLimit,
            cellIdentifier: GroupSettingTransferCell.lu.reuseIdentifier,
            style: .auto,
            title: title
        ) { [weak self] _ in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            self.imGroupManageClickTrack(clickType: "apply_member_toplimit", target: "im_chat_member_toplimit_apply_view")
            self.userResolver.navigator.present(body: GroupApplyForLimitBody(chatId: chatID),
                                     wrap: LkNavigationController.self,
                                     from: vc,
                                     prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
                                     animated: true)
        }
    }
    private func allowGroupSearchedItem() -> GroupSettingItemProtocol? {
        guard isShowAllowGroupSearchedCell else { return nil }
        let chatID = self.chatModel.id
        let statusString = chatModel.isPublic ?
            BundleI18n.LarkChatSetting.Lark_Legacy_OpenNow :
            BundleI18n.LarkChatSetting.Lark_Legacy_MineMessageSettingClose

        return GroupSettingAllowGroupSearchedItem(
            type: .allowGroupSearched,
            cellIdentifier: GroupSettingAllowGroupSearchedCell.lu.reuseIdentifier,
            style: .half,
            title: BundleI18n.LarkChatSetting.Lark_Group_FindGroupViaSearchTitle,
            detail: "",
            status: statusString,
            cellEnable: !self.chatModel.isCrossTenant && chatModel.oncallId.isEmpty && !self.chatModel.isMeeting,
            badgePath: nil,
            showBadge: false
        ) { [weak self] _ in
            guard let self = self, let vc = self.controller else {
                assertionFailure("lose targetVC to jump")
                return
            }
            self.imGroupManageClickTrack(clickType: "allow_to_be_searched", target: "im_chat_allow_to_be_searched_view")
            let body = GroupSearchAbleConfigBody(chatId: chatID)
            self.userResolver.navigator.push(body: body, from: vc)
        }
    }

    func messageVisibilityItem() -> GroupSettingItemProtocol? {
        /// 公开群、话题群不涉及在群管理中增加历史消息不可见开关
        guard chatModel.type == .group,
              chatModel.chatMode == .default,
              !chatModel.isPublic else { return nil }
        let enabled = !chatModel.isTeamOpenGroupForAnyTeam
        let status = chatModel.messageVisibilitySetting == .allMessages
        return GroupSettingMessageVisibilityItem(
            type: .messageVisibility,
            cellIdentifier: GroupSettingMessageVisibilityCell.lu.reuseIdentifier,
            style: .half,
            title: BundleI18n.LarkChatSetting.Lark_Group_NewMembersCanViewHistoryMessages,
            detail: enabled ? "" : BundleI18n.LarkChatSetting.Project_T_NotAllowOpenGroupMemberReadHistory_Text,
            status: status,
            enabled: enabled
        ) { [weak self] (_, isOn) in
            guard let self = self else { return }
            self.imGroupManageClickTrack(clickType: "is_history_message_view",
                                         extra: ["target": "none",
                                                 "status": isOn ? "off_to_on" : "on_to_off"])
            self.messageVisibilitySwitchEvent.onNext(isOn)
        }
    }

    func atAllItem() -> GroupSettingItemProtocol {
        let count = self.memberCount
        let chatId = chatModel.id
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanAtAll
        let detail = chatModel.atAllPermission == .onlyOwner ?
            BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin :
            BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup

        return AtAllConfigurationItem(
            type: .atAll,
            cellIdentifier: AtAllConfigurationCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: detail
        ) { [weak self] (cell) in
            guard let self = self else { return }
            self.showAtAllAlert(in: cell)
        }
    }

    func banningItem() -> GroupSettingItemProtocol? {
        if chatModel.isCrypto { return nil }
        // code_next_line tag CryptChat
        var messageMap: [Chat.PostType: String]
        if chatModel.chatMode == .threadV2 {
            let onlyAdminThreadTitle = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGroupOwnerGroupAdminNewTopics
            messageMap = [
                .anyone: BundleI18n.LarkChatSetting.Lark_Group_Topic_GroupSettings_MsgRestriction_Default,
                .onlyAdmin: onlyAdminThreadTitle,
                .whiteList: BundleI18n.LarkChatSetting.Lark_Group_Topic_GroupSettings_MsgRestriction_SelectedMember
            ]
        } else {
            let onlyAdminChatTitle = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGASendMsg
            messageMap = [
                .anyone: BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup,
                .onlyAdmin: onlyAdminChatTitle,
                .whiteList: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_MsgRestriction_SelectedMember
            ]
        }

        let title = BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_MsgRestriction_Title
        let chatId = chatModel.id
        let isBannedPost = !chatModel.isAllowPost && chatModel.adminPostSetting == .bannedPost
        let detail = isBannedPost ? BundleI18n.LarkChatSetting.Lark_IM_ChatSettings_WhoCanPostInGroup_OptionIsNobody :
        (messageMap[chatModel.postType] ?? "")
        return GroupSettingBanningItem(
            type: .banning,
            cellIdentifier: GroupSettingBanningCell.lu.reuseIdentifier,
            style: .auto,
            title: title,
            detail: detail,
            cellEnable: !isBannedPost
        ) { [weak self] _ in
            guard let vc = self?.controller, let self = self else {
                assertionFailure("reduce targetVC to jump")
                return
            }
            if isBannedPost {
                let text = BundleI18n.LarkChatSetting.Lark_IM_UnableEditSettingAdminProhibitPosting_Toast
                UDToast.showTips(with: text, on: vc.view)
                return
            }
            self.userResolver.navigator.present(body: BanningSettingBody(chatId: chatId),
                                     wrap: LkNavigationController.self,
                                     from: vc,
                                     prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen },
                                     animated: true)
        }
    }

    func mailPermissionItem() -> GroupSettingItemProtocol? {
        if groupEmailSettingShouldShow,
           let mailSetting = chatModel.mailSetting {
            let detail: String
            let title = BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Title
            if !mailSetting.allowMailSend {
                detail = BundleI18n.LarkChatSetting.Lark_Chat_NoOneCanSend
            } else {
                let permission = ChatSettingMailPermissionType.transformFrom(type: mailSetting.sendPermission)
                detail = MailPermissionSettingViewModel.getPermissionMap()[permission] ?? ""
            }
            return GroupSettingMailPermissionItem(
                type: .mailPermission,
                cellIdentifier: GroupSettingMailPermissionCell.lu.reuseIdentifier,
                style: .auto,
                title: title,
                detail: detail
            ) { [weak self] cell in
                guard let self = self, self.controller != nil else {
                    assertionFailure("reduce targetVC to jump")
                    return
                }
                self.showMailConfigurationAlert(in: cell)
            }
        } else {
            return nil
        }
    }

    func whenLeaveItem() -> GroupSettingItemProtocol {
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoWIllBeNotifiedLeave
        let count = chatModel.userCount
        let chatId = chatModel.id
        let isSuper = chatModel.isSuper
        return GroupSettingLeaveNotifyItem(
            type: .whenLeave,
            cellIdentifier: GroupSettingLeaveNotifyCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: convert(chatModel.quitMessageVisible)
        ) { [weak self] cell in
            guard let self = self else { return }
            let title = title
            let items: [Chat.SystemMessageVisible.Enum]
            if isSuper {
                items = [.allMembers, .notAnyone]
            } else {
                items = [.allMembers, .onlyOwner, .notAnyone]
            }
            self.showNotificationAlertSheet(title: title,
                                            in: cell,
                                            clickType: "leave_group_system_message",
                                            items: items) { [weak self] (type) in
                ChatSettingTracker.newTrackChatManageLeaveGroup(type, memberCount: Int(count), chatId: chatId)
                self?.changeLeaveNotification(to: type)
            }
        }
    }

    func whenJoinItem() -> GroupSettingItemProtocol {
        let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoWIllBeNotifiedForNewMembers
        let count = chatModel.userCount
        let chatId = chatModel.id
        let isSuper = chatModel.isSuper
        return GroupSettingJoinNotifyItem(
            type: .whenJoin,
            cellIdentifier: GroupSettingJoinNotifyCell.lu.reuseIdentifier,
            style: .half,
            title: title,
            detail: convert(chatModel.joinMessageVisible)
        ) { [weak self] cell in
            guard let self = self else { return }
            let title = title
            self.imGroupManageClickTrack(clickType: "join_group_system_message")
            let items: [Chat.SystemMessageVisible.Enum]
            if isSuper {
                items = [.allMembers, .notAnyone]
            } else {
                items = [.allMembers, .onlyOwner, .notAnyone]
            }
            self.showNotificationAlertSheet(title: title,
                                            in: cell,
                                            clickType: "join_group_system_message",
                                            items: items) { [weak self] (type) in
                ChatSettingTracker.newTrackChatManageEnterGroup(type, memberCount: Int(count), chatId: chatId)
                self?.changeJoinNotification(to: type)
            }
        }
    }

    // 防泄密模式
    func preventMessageLeakItem() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.preventMessageLeakItem(chat: self.chatModel, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result, logMessage: "preventMessage switch set faild \(status)",
                                       alertMessage: nil,
                                       failedHandler: { [weak self] in
                self?._reloadData.onNext(())
            })
        })
    }

    // 禁止拷贝转发
    func forbiddenMessageCopyForward() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.forbiddenMessageCopyForward(chat: self.chatModel, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenMessageForward set faild \(status)",
                                      alertMessage: nil,
                                      failedHandler: { [weak self] in
                self?._reloadData.onNext(())
            })
        })
    }

    // 禁止下载
    func forbiddenDownloadResource() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.forbiddenDownloadResource(chat: self.chatModel, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenDownloadResource set faild \(status)",
                                      alertMessage: nil,
                                      failedHandler: { [weak self] in
                self?._reloadData.onNext(())
            })
        })
    }

    // 禁止截图/录屏
    func forbiddenScreenCapture() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.forbiddenScreenCapture(chat: self.chatModel, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenDownloadResource set faild \(status)",
                                      alertMessage: nil,
                                      failedHandler: { [weak self] in
                self?._reloadData.onNext(())
            })
        })
    }

    func messageBurnTime() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.burnTime(chat: self.chatModel, tapHandler: { [weak self] in
            guard let self = self, let vc = self.controller, !self.chatModel.displayInThreadMode else {
                return
            }
            Self.logger.info("chat restrictedModeSetting messageBurnTimeItemClick \(self.chatModel.id) \(self.chatModel.restrictedBurnTime.description(closeStatusText: "close"))")
            let selectTimeVC = BurnMessageTimeSelectViewcontroller(selectedTime: self.chatModel.restrictedBurnTime,
                                                                   chatId: self.chatModel.id,
                                                                   chatAPI: self.chatAPI)
            self.userResolver.navigator.push(selectTimeVC, from: vc)
        })
    }

    func preventMessageWhiteList() -> GroupSettingItemProtocol? {
        return self.restrictedModeService.setWhiteList(chat: self.chatModel, tapHandler: { [weak self] in
            guard let self = self, let vc = self.controller else {
                return
            }
            let vm = PreventMessageWhiteListViewModel(chat: self.chatModel,
                                                      userResolver: self.userResolver)
            let to = PreventMessageWhiteListController(viewModel: vm)
            self.userResolver.navigator.present(to,
                                                wrap: LkNavigationController.self,
                                                from: vc,
                                                prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen },
                                                animated: true)
        })
    }

    func hideUserCountItem() -> GroupSettingItemProtocol? {
        guard self.showHideUserCountItem else { return nil }
        return HideUserCountItem(
            type: .hideUserCount,
            cellIdentifier: HideUserCountCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_ContentPermissionsHideMembers_Title,
            detail: BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_ContentPermissionsHideMembers_Desc,
            status: chatModel.userCountVisibleSetting == .onlyManager,
            switchHandler: { [weak self] _, status in
                guard let self = self else { return }
                let chatID = self.chatModel.id
                Self.logger.info("begin update userCountVisibleSetting chatID: \(chatID) \(status)")
                self.parsingUserOperation(
                    self.chatAPI.updateChat(chatID: chatID, userCountVisibleSetting: status ? .onlyManager : .allMembers),
                    logMessage: "update userCountVisibleSetting fail \(status)",
                    alertMessage: BundleI18n.LarkChatSetting.Lark_IM_GroupSettings_ContentPermissionsHideMembers_NoEditPermission_Toast,
                    failedHandler: { [weak self] in
                        self?._reloadData.onNext(())
                    }
                )
            }
        )
    }

    func structureItems() -> CommonDatasource {
        var sections = CommonDatasource()

        if self.chatModel.isCrypto {
            // code_next_line tag CryptChat
            sections = [
                self.transferSection()
            ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        } else {
            sections = [
                self.modeChangeSection(),
                self.memberAuthManagerSection(),
                self.privacySettingsSection(),
                self.joininSection(),
                self.transferSection(),
                self.toNormalGroupSection()
            ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        }

        return sections
    }

    private func convert(_ type: Chat.SystemMessageVisible.Enum) -> String {
        switch type {
        case .onlyOwner:
            let title = BundleI18n.LarkChatSetting.Lark_GroupManagement_OnlyGroupOwnerAndGroupAdmin
            return title
        case .allMembers:
            return BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup
        case .notAnyone:
            return BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingNotifyNone
        @unknown default:
            return BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingNotifyNone
        }
    }
}

// MARK: - 会议群转普通群
private extension GroupSettingViewModel {
    func groupAdminsCellTapped() {
        let chat = chatModel
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        // 群管理员为空时引导去添加，否则去管理员页面
        if self.adminMembers.isEmpty {
            let body = GroupAddAdminBody(chatId: chat.id,
                                         chatCount: chat.userCount,
                                         controller: vc)
            self.userResolver.navigator.push(body: body, from: vc)
        } else {
            let body = GroupAdminBody(chat: chat)
            self.userResolver.navigator.push(body: body, from: vc)
        }
    }
    func doTurnIntoNormalGroup() {
        calendarInterface
            .toNormalGroup(chatID: chatModel.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let chatId = self?.chatModel.id else { return }
                guard let vc = self?.controller else {
                    assertionFailure("reduce targetVC to jump")
                    return
                }
                self?.userResolver.navigator.push(body: ChatControllerByIdBody(chatId: chatId), from: vc)
            }, onError: { [weak self] error in
                if let window = self?.controller?.currentWindow() {
                    UDToast.showFailure(
                        with: BundleI18n.LarkChatSetting.Calendar_SubscribeCalendar_OperationFailed,
                        on: window,
                        error: error
                    )
                }
            }).disposed(by: disposeBag)
    }

    func turnIntoNormalGroup() {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }

        let createTime = chatModel.createTime
        let chatId = chatModel.id
        /// 构造alert弹窗
        let alertController = LarkAlertController()

        alertController.setTitle(text: BundleI18n.LarkChatSetting.Calendar_Setting_ConfirmTransform, alignment: .center)
        alertController.setContent(text: BundleI18n.LarkChatSetting.Calendar_Setting_TransformGroupConfirmSubtitle)

        /// 取消
        alertController.addCancelButton(dismissCheck: {
            ChatSettingTracker.trackToNormalGroupPopupClicked(false)
            return true
        })

        /// 转为普通群
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            ChatSettingTracker.newTrackToNormalGroupClicked(createTime: createTime, chatId: chatId)
            guard let `self` = self else { return }
            self.doTurnIntoNormalGroup()
        })

        self.userResolver.navigator.present(alertController, from: vc)
    }
}

// MARK: handler
private extension GroupSettingViewModel {
    // action when user tapping VideoMeettingConfigration item
    func showVideoMeettingConfigrationAlert(in view: UIView) {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let setting = chatModel.createVideoConferenceSetting
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_StartVideoCalls,
                                        in: view,
                                        clickType: "vc_restriction",
                                        items: [.allMembers, .onlyOwner]) { type in
            let newSetting: Chat.CreateVideoConferenceSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            @unknown default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let newSetting = newSetting, setting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, createVideoConferenceSetting: newSetting),
                logMessage: "change edit access failed!",
                alertMessage: nil
            )
        }
    }

    // action when user tapping UrgentConfigration item
    func showUrgentConfigrationAlert(in view: UIView) {
        let setting = chatModel.createUrgentSetting
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanBuzzOthers,
                                        in: view,
                                        clickType: "ding_restriction",
                                        items: [.allMembers, .onlyOwner]) { type in
            let newSetting: Chat.CreateUrgentSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            @unknown default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let newSetting = newSetting, setting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, createUrgentSetting: newSetting),
                logMessage: "change createUrgentSetting failed!",
                alertMessage: nil
            )
        }
    }

    // action when user tapping PinConfigration item
    private func showPinConfigrationAlert(in view: UIView) {
        let setting = chatModel.pinPermissionSetting
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanPin,
                                        in: view,
                                        clickType: "pin_restriction",
                                        items: [.allMembers, .onlyOwner]) { type in
            let newSetting: Chat.PinPermissionSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            @unknown default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let newSetting = newSetting, setting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, pinPermissionSetting: newSetting),
                logMessage: "change pinPermissionSetting failed!",
                alertMessage: nil
            )
        }
    }

    private func showTopNoticeConfigrationAlert(in view: UIView) {
        let setting = chatModel.topNoticePermissionSetting
        self.showNotificationAlertSheet(title: self.getTitleForTopNoticeItem(),
                                        in: view,
                                        clickType: "pin_to_top_restriction",
                                        items: [.allMembers, .onlyOwner]) { [weak self] type in
            let newSetting: Chat.TopNoticePermissionSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            @unknown default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let self = self, let newSetting = newSetting, setting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, topNoticePermissionType: newSetting),
                logMessage: "change TopNoticePermissionSetting failed!",
                alertMessage: nil
            )
        }
    }

    private func showChatTabsMenuWidgetsConfigrationAlert(in view: UIView, title: String, clickType: String) {
        let oldSetting = chatModel.chatTabPermissionSetting
        self.showNotificationAlertSheet(title: title,
                                        in: view,
                                        clickType: clickType,
                                        items: [.allMembers, .onlyOwner]) { [weak self] type in
            let newSetting: Chat.ChatTabPermissionSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            @unknown default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let self = self, let newSetting = newSetting, oldSetting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, chatTabPermissionSetting: newSetting),
                logMessage: "change ChatTabsMenuWidgetsPermissionSetting \(self.chatModel.id) failed!",
                alertMessage: nil
            )
        }
    }

    private func showChatPinConfigrationAlert(in view: UIView, title: String, clickType: String) {
        let oldSetting = chatModel.chatPinPermissionSetting
        self.showNotificationAlertSheet(title: title,
                                        in: view,
                                        clickType: clickType,
                                        items: [.allMembers, .onlyOwner]) { [weak self] type in
            let newSetting: Chat.ChatPinPermissionSetting?
            switch type {
            case .allMembers:
                newSetting = .allMembers
            case .onlyOwner:
                newSetting = .onlyManager
            default:
                newSetting = nil
                assertionFailure("unknonw type")
            }
            guard let self = self, let newSetting = newSetting, oldSetting != newSetting else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, chatPinPermissionSetting: newSetting),
                logMessage: "change ChatPinPermissionSetting \(self.chatModel.id) failed!",
                alertMessage: nil
            )
        }
    }

    private func getTitleForTopNoticeItem() -> String {
       let title = chatModel.chatMode == .threadV2 ?
        BundleI18n.LarkChatSetting.Lark_IMChatPin_WhoCanPinTopicAndAnnouncement_Option :
        BundleI18n.LarkChatSetting.Lark_IMChatPin_WhoCanPinChatAndAnnouncement_Option
        return title
    }

    func selectedMember(chatterId: String) {
        let chat = chatModel
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let body = PersonCardBody(chatterId: chatterId,
                                  chatId: chat.id,
                                  source: .chat)
        if Display.phone {
            self.userResolver.navigator.push(body: body, from: vc)
        } else {
            self.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }

    func onTapAddNewAdmin() {
        let chat = chatModel
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let body = GroupAddAdminBody(chatId: chat.id,
                                     chatCount: chat.userCount,
                                     defaultUnableCancelSelectedIds: self.adminMembers.map({ $0.id }),
                                     controller: vc)
        self.userResolver.navigator.push(body: body, from: vc)
    }

    func showGroupInfoConfigurationAlert(in view: UIView) {
        let offEditInfo = self.chatModel.offEditGroupChatInfo
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_EditGroupInfo,
                                        in: view,
                                        clickType: "edit_group_info",
                                        items: [.allMembers, .onlyOwner]) { type in
            let newOffEditInfo: Bool?
            switch type {
            case .allMembers:
                newOffEditInfo = false
            case .onlyOwner:
                newOffEditInfo = true
            @unknown default:
                newOffEditInfo = nil
                assertionFailure("unknonw type")
            }
            guard let newOffEditInfo = newOffEditInfo, offEditInfo != newOffEditInfo else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, offEditInfo: newOffEditInfo),
                logMessage: "change edit access failed!",
                alertMessage: nil
            )
        }
    }

    func switchShareCardAndAddNewPermission(newStatus: Bool) {
        parsingUserOperation(
            chatAPI.updateChat(chatId: chatModel.id,
                               addMemberPermission: newStatus ? .allMembers : .onlyOwner,
                               shareCardPermission: newStatus ? .allowed : .notAllowed),
            logMessage: "change share card permission failed!",
            alertMessage: nil
        )
    }

    func closeChatCanSearchSetting() {
        guard chatModel.isPublic else {
            assertionFailure("not public group, can't use this api")
            return
        }
        parsingUserOperation(
            chatAPI.updateChat(chatId: chatModel.id,
                               isPublic: false,
                               addMemberPermission: .onlyOwner,
                               shareCardPermission: .notAllowed),
            logMessage: "change share card permission failed!",
            alertMessage: nil
        ) {
        }
    }

    func switchMessageVisibilitySetting(newStatus: Bool) {
        parsingUserOperation(
            chatAPI.updateChat(chatId: chatModel.id, messageVisibilitySetting: newStatus ? .allMessages : .onlyNewMessages),
            logMessage: "change message visibility failed!",
            alertMessage: nil
        ) { [weak self] in
            self?._reloadData.onNext(())
        }
    }

    func showNotificationAlertSheet(title: String,
                                    in view: UIView,
                                    clickType: String,
                                    items: [Chat.SystemMessageVisible.Enum],
                                    _ handler: @escaping (Chat.SystemMessageVisible.Enum) -> Void) {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }

        let adapter = ActionSheetAdapter()

        let actionSheet = adapter.create(
            level: .normal(source:
                ActionSheetAdapterSource(
                    sourceView: view,
                    sourceRect: CGRect(
                        x: view.bounds.width / 2,
                        y: view.bounds.height / 2,
                        width: 0, height: 0),
                    arrowDirection: .unknown)),
            title: title)

        if items.contains(where: { $0 == .allMembers }) {
            adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_EveryoneInThisGroup) { [weak self] in handler(.allMembers)
                self?.imGroupManageClickTrack(clickType: clickType,
                                              target: "none",
                                              extra: ["status": "all"])
            }
        }
        if items.contains(where: { $0 == .onlyOwner }) {
            adapter.addItem(title: self.convert(.onlyOwner)) { [weak self] in
                handler(.onlyOwner)
                self?.imGroupManageClickTrack(clickType: clickType,
                                              target: "none",
                                              extra: ["status": "only_group_owner_and_admin"])
            }
        }
        if items.contains(where: { $0 == .notAnyone }) {
            adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingNotifyNone) { [weak self] in
                handler(.notAnyone)
                self?.imGroupManageClickTrack(clickType: clickType,
                                              target: "none",
                                              extra: ["status": "nobody"])
            }
        }
        adapter.addCancelItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)

        self.userResolver.navigator.present(actionSheet, from: vc)
    }

    func changeLeaveNotification(to type: Chat.SystemMessageVisible.Enum) {
        parsingUserOperation(
            chatAPI.updateChat(chatId: chatModel.id, leaveGroupNotiftType: type),
            logMessage: "change leave group notify type error",
            alertMessage: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError)
    }

    func changeJoinNotification(to type: Chat.SystemMessageVisible.Enum) {
        parsingUserOperation(
            chatAPI.updateChat(chatId: chatModel.id, joinGroupNotiftType: type),
            logMessage: "change join group notify type error",
            alertMessage: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError)
    }

    private func showAtAllAlert(in view: UIView) {
        let atAllPermission = chatModel.atAllPermission
        self.showNotificationAlertSheet(title: BundleI18n.LarkChatSetting.Lark_GroupManagement_WhoCanAtAll,
                                        in: view,
                                        clickType: "mention_all_member",
                                        items: [.allMembers, .onlyOwner]) { type in
            let newAtAllPermission: LarkModel.Chat.AtAllPermission.Enum?
            switch type {
            case .allMembers:
                newAtAllPermission = .allMembers
            case .onlyOwner:
                newAtAllPermission = .onlyOwner
            @unknown default:
                newAtAllPermission = nil
                assertionFailure("unknonw type")
            }
            guard let newAtAllPermission = newAtAllPermission, atAllPermission != newAtAllPermission else { return }
            self.parsingUserOperation(
                self.chatAPI.updateChat(chatId: self.chatModel.id, atAllPermission: newAtAllPermission),
                logMessage: "change @all permission failed!",
                alertMessage: nil
            )
        }
    }

    func transfer() {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let source: ChatSettingTracker.TransferGroupSource = .manageGroup
        ChatSettingTracker.newTrackTransferClick(source: source, chatId: chatModel.id, chat: self.chatModel)

        if chatModel.chatterCount <= 1 {
            let title = BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner
            let content = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoTransferOnlyownerContent
            self.showAlert?(title, content)
            return
        }
        var body = TransferGroupOwnerBody(chatId: self.chatModel.id,
                                          mode: .assign,
                                          isThread: self.isThread)
        let chat = chatModel
        body.lifeCycleCallback = { [weak self] res in
            ChatSettingTracker.trackTransmitChatOwner(chat: chat, source: .chatManage)
            switch res {
            case .before:
                self?.imGroupManageClickTrack(clickType: "transfer_group_owner", target: "none")
            case .success:
                if let window = self?.controller?.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwnerSuccess, on: window)
                }
            case .failure(let error, let newOwnerId):
                if let error = error.underlyingError as? APIError, let window = self?.controller?.currentWindow() {
                    switch error.type {
                    case .transferGroupOwnerFailed(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        if !error.displayMessage.isEmpty {
                            UDToast.showFailure(with: error.displayMessage, on: window)
                        } else {
                            UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwnerFailed, on: window, error: error)
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

    func showMailConfigurationAlert(in view: UIView) {
        guard let vc = self.controller else {
            assertionFailure("reduce targetVC to jump")
            return
        }
        let adapter = ActionSheetAdapter()

        let actionSheet = adapter.create(
            level: .normal(source:
                ActionSheetAdapterSource(
                    sourceView: view,
                    sourceRect: CGRect(
                        x: view.bounds.width / 2,
                        y: view.bounds.height / 2,
                        width: 0, height: 0),
                    arrowDirection: .unknown)),
            title: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Title)

        let permission = chatModel.mailSetting
        adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGASendEmail) { [weak self] in
            self?.imGroupManageClickTrack(clickType: "mail_restriction", extra: ["status": "only_group_owner_and_admin"])

            guard let self = self, permission?.sendPermission != .groupAdmin else { return }
            self.confirmMailOption(mailPermissionType: .groupAdmin)
        }
        adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Member) { [weak self] in
            self?.imGroupManageClickTrack(clickType: "mail_restriction", extra: ["status": "only_group_member"])
            guard let self = self, permission?.sendPermission != .groupMembers else { return }
            self.confirmMailOption(mailPermissionType: .groupMembers)
        }
        adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_Tenant) { [weak self] in
            self?.imGroupManageClickTrack(clickType: "mail_restriction", extra: ["status": "only_team_member"])
            guard let self = self, permission?.sendPermission != .organizationMembers else { return }
            self.confirmMailOption(mailPermissionType: .organizationMembers)
        }
        adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_Email_Permission_All) { [weak self] in
            self?.imGroupManageClickTrack(clickType: "mail_restriction", extra: ["status": "all"])
            guard let self = self, permission?.sendPermission != .all else { return }
            self.confirmMailOption(mailPermissionType: .all)
        }

        adapter.addItem(title: BundleI18n.LarkChatSetting.Lark_Chat_NoOneCanSend) { [weak self] in
            self?.imGroupManageClickTrack(clickType: "mail_restriction", extra: ["status": "nobody"])
            guard let self = self, permission?.allowMailSend != false else { return }
            self.confirmMailOption(mailPermissionType: .allNot)
        }

        adapter.addCancelItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(actionSheet, from: vc)
    }

    func confirmMailOption(mailPermissionType: ChatSettingMailPermissionType) {
       let chatId = self.chatModel.id
        ChatSettingTracker.mailPermissionTrack(mailPermissionType, memberCount: Int(self.chatModel.userCount), chatId: chatId)

        let permissionType: Chat.MailPermissionType
        switch mailPermissionType {
        case .unknown:
            permissionType = .unknown
        case .groupAdmin:
            permissionType = .groupAdmin
        case .groupMembers:
            permissionType = .groupMembers
        case .organizationMembers:
            permissionType = .organizationMembers
        case .all:
            permissionType = .all
        case .allNot:
            // 单独处理allNot
            chatAPI.updateChat(chatId: chatId, allowSendMail: false)
                .subscribe(onError: { [weak self] (error) in
                    self?.confirmMailOptionErrorHandler(error: error, chatId: chatId)
                }).disposed(by: self.disposeBag)
            return
        }
        chatAPI.updateChat(chatId: chatId,
                           allowSendMail: true,
                           permissionType: permissionType)
            .subscribe(onNext: { _ in
            // success
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            self.confirmMailOptionErrorHandler(error: error, chatId: chatId)
            Self.logger.error(
                "update permissionType error,id = \(chatId),type = \(mailPermissionType)",
            error: error)
        }).disposed(by: disposeBag)
    }

    private func confirmMailOptionErrorHandler(error: Error, chatId: String) {
        guard let window = self.controller?.view.window else { return }
        DispatchQueue.main.async {
            UDToast.showFailure(
                with: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                on: window,
                error: error
            )
        }
    }

    // rusult parsingUserOperation
    func parsingUserOperation(
        _ result: Observable<LarkModel.Chat>,
        logMessage: String,
        alertMessage: String?,
        successHandler: (() -> Swift.Void)? = nil,
        failedHandler: (() -> Swift.Void)? = nil
    ) {
        let chatId = self.chatModel.id
        result.observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                successHandler?()
            }, onError: { [weak self] (error) in
                Self.logger.error(logMessage, additionalData: ["chatId": chatId], error: error)

                failedHandler?()

                guard let window = self?.controller?.view.window else {
                    assertionFailure("reduce window to jump")
                    return
                }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .newVersionFeature(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        UDToast.showFailure(
                            with: alertMessage ?? error.serverMessage,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    UDToast.showFailure(with: alertMessage ?? BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                                           on: window)
                }
            }).disposed(by: self.disposeBag)
    }
}

// MAKR: - track
private extension GroupSettingViewModel {
    func imGroupManageClickTrack(clickType: String, target: String = "none", extra: [String: String] = [:]) {
        var extra = extra
        extra["target"] = target
        NewChatSettingTracker.imGroupManageClick(
            chat: self.chatModel,
            myUserId: self.currentUserId,
            isOwner: self.isOwner,
            isAdmin: self.isGroupAdmin,
            clickType: clickType,
            extra: extra)
    }
}

// MAKR: - badge
private extension GroupSettingViewModel {
    var groupSetting: Path {
        return Path().prefix(Path().chat_id, with: chatModel.id).chat_more.setting.group_setting
    }

    var approve: Path { return groupSetting.approve }
}

// MARK: alias
private typealias VideoMettingConfigurationCell = GroupSettingBanningCell
private typealias VideoMettingConfigurationItem = GroupSettingBanningItem

private typealias UrgentConfigurationCell = GroupSettingBanningCell
private typealias UrgentConfigurationItem = GroupSettingBanningItem

private typealias PinConfigurationCell = GroupSettingBanningCell
private typealias PinConfigurationItem = GroupSettingBanningItem

private typealias EditGroupInfoConfigurationCell = GroupSettingBanningCell
private typealias EditGroupInfoConfigurationItem = GroupSettingBanningItem

private typealias ShareAndAddNewPermissionCell = GroupSettingBanningCell
private typealias ShareAndAddNewPermissionItem = GroupSettingBanningItem

private typealias AtAllConfigurationCell = GroupSettingBanningCell
private typealias AtAllConfigurationItem = GroupSettingBanningItem

private typealias topNoticeConfigurationCell = GroupSettingBanningCell
private typealias topNoticeConfigurationItem = GroupSettingBanningItem

private typealias ChatTabsMenuWidgetsConfigurationCell = GroupSettingBanningCell
private typealias ChatTabsMenuWidgetsConfigurationItem = GroupSettingBanningItem

private typealias ChatPinAuthConfigurationCell = GroupSettingBanningCell
private typealias ChatPinAuthConfigurationItem = GroupSettingBanningItem
