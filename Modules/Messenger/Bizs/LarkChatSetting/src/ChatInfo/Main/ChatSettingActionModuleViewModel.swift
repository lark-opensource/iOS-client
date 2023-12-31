//
//  ChatSettingActionModuleViewModel.swift
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
import LKCommonsLogging
import EENavigator
import LarkSDKInterface
import LarkCore
import LarkAlertController
import LarkAccountInterface
import LarkReleaseConfig
import LarkEnv
import LarkSetting
import LarkKAFeatureSwitch
import LarkFeatureGating
import LarkAccount
import UniverseDesignToast
import LarkUIKit
import RxRelay
import LarkSuspendable
import ThreadSafeDataStructure
import LarkLocalizations
import UniverseDesignCheckBox
import SuiteAppConfig

final class ChatSettingActionModuleViewModel: ChatSettingModuleViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var passportUserService: PassportUserService?

    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }
    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }
    var isMe: Bool {
        currentUserId == chat.chatterId
    }
    private static let logger = Logger.log(ChatSettingActionModuleViewModel.self, category: "Module.IM.ChatInfo")
    var reloadSubject = PublishSubject<Void>()
    private let schedulerType: SchedulerType
    private(set) var disposeBag = DisposeBag()
    private var chat: Chat {
        get { _chat.value }
        set { _chat.value = newValue }
    }
    private var _chat: SafeAtomic<Chat>
    var pushChat: Observable<Chat>
    private let hasModifyAccess: Bool
    var isOwner: Bool { return currentUserId == chat.ownerId }
    private var currentUserId: String {
        return self.userResolver.userID
    }
    private var shouldShowToNormalGroup: Bool { isOwner && chat.isMeeting }
    private var isThread: Bool {
        chat.chatMode == .threadV2
    }
    private var isMeetingOrganizer: Bool {
        get { _isMeetingOrganizer.value }
        set { _isMeetingOrganizer.value = newValue }
    }
    private var _isMeetingOrganizer: SafeAtomic<Bool> = false + .readWriteLock
    private var pushCenter: PushNotificationCenter

    private var isOversea: Bool {
        return ReleaseConfig.releaseChannel == "Oversea" || passportUserService?.isFeishuBrand == false
    }
    weak var targetVC: UIViewController?
    /* --- 客服相关 Start --- */
    private var currentChatterInChat: Chatter? {
        get { _currentChatterInChat.value }
        set { _currentChatterInChat.value = newValue }
    }
    private lazy var _currentChatterInChat: SafeAtomic<Chatter?> = {
        self.chatterManager?.currentChatter + .readWriteLock
    }()
    private var oncallRole: Chatter.ChatExtra.OncallRole? {
        return currentChatterInChat?.chatExtra?.oncallRole
    }
    var openAppId: String {
        get { _openAppId.value }
        set { _openAppId.value = newValue }
    }
    private lazy var reportEnable = userResolver.fg.staticFeatureGatingValue(with: "lark.tns.report")

    // 举报相关
    // 在拉取结果成功前仅允许点击一次举报按钮
    var reporting = false
    var _openAppId: SafeAtomic<String> = "" + .readWriteLock
    var currentChatterInChatOb: Observable<Chatter>
    @ScopedInjectedLazy private var chatService: ChatService?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy private var calendarInterface: ChatSettingCalendarDependency?
    @ScopedInjectedLazy private var userService: PassportUserService?

    init(resolver: UserResolver,
         chat: Chat,
         hasModifyAccess: Bool,
         schedulerType: SchedulerType,
         pushChat: Observable<Chat>,
         currentChatterInChatOb: Observable<Chatter>,
         pushCenter: PushNotificationCenter,
         targetVC: UIViewController?) {
        self._chat = chat + .readWriteLock
        self.targetVC = targetVC
        self.currentChatterInChatOb = currentChatterInChatOb
        self.pushChat = pushChat
        self.schedulerType = schedulerType
        self.pushCenter = pushCenter
        self.hasModifyAccess = hasModifyAccess
        self.userResolver = resolver
    }

    func structItems() {
        let items = [leaveItem(),
                     disbandItem(),
                     reportItem()].compactMap({ $0 })
        self.items = items
    }

    func startToObserve() {
        var getChatterReloadOb: Observable<Void> = .empty()
        if chat.type == .p2P, let chatter = self.chat.chatter, chatter.type == .bot, let chatterAPI = self.chatterAPI {
            /// 异步获取app_id，本地获取的chatter上可能没有app_id
            getChatterReloadOb = chatterAPI.getChatter(id: chatter.id, forceRemoteData: true)
                .map({ [weak self] chatter in
                    guard let `self` = self, let chatter = chatter, !chatter.openAppId.isEmpty else { return }
                    self.openAppId = chatter.openAppId
                })
        }

        // 获取当前用户角色
        let currentChatterInChatReloadOb = currentChatterInChatOb
            .map({ [weak self] (chatter) -> Void in
                self?.currentChatterInChat = chatter
            })

        let pushChatReloadOb = pushChat
            .map({ [weak self] chat -> Void in
                self?.chat = chat
            })

        // 看了一下逻辑，isMeetingOrganizer的使用是在点击退群才会用到，所以可以异步拉取，不用初始化时转入
        if self.chat.isMeeting {
            self.calendarInterface?.getIsOrganizer(chatID: self.chat.id).subscribe(onNext: { [weak self] (isOrganizer) in
                self?.isMeetingOrganizer = isOrganizer
            }).disposed(by: self.disposeBag)
        }
        // 100毫秒debounce过滤掉高频信号发射
        Observable.merge(getChatterReloadOb,
                         currentChatterInChatReloadOb,
                         pushChatReloadOb)
            .debounce(.milliseconds(100), scheduler: schedulerType)
            .subscribe(onNext: { [weak self] _ in
                self?.structItems()
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }
}

// MARK: item方法
extension ChatSettingActionModuleViewModel {

    private func showLeaveItem() -> Bool {
        guard hasModifyAccess, self.canLeave, self.chat.type != .p2P, !chat.isFrozen else { return false }
        return true
    }

    private func showDisbandItem() -> Bool {
        guard !chat.isFrozen else {
            return false
        }
        guard (isOwner && !chat.isCustomerService) || (chat.type == .p2P && chat.isCrypto) else {
            return false
        }
        return true
    }

    func leaveItem() -> CommonCellItemProtocol? {
        guard self.showLeaveItem() else { return nil }
        let leaveString: String
        if chat.isOncall {
            leaveString = BundleI18n.LarkChatSetting.Lark_HelpDesk_SettingsLeaveHelpDesk
        } else {
            leaveString = BundleI18n.LarkChatSetting.Lark_Legacy_LeaveChat
        }
        return ChatInfoLeaveGroupModel(
            type: .leaveGroup,
            cellIdentifier: ChatInfoLeaveGroupCell.lu.reuseIdentifier,
            style: showLeaveItem() && showDisbandItem() ? .full : .auto,
            title: leaveString
        ) { [weak self] _ in
            NewChatSettingTracker.imChatSettingLeaveClick(chatId: self?.chat.id ?? "", isAdmin: self?.isOwner ?? false)
            self?.leaveGroup()
            guard let buriedPointChat = self?.chat else { return }
            NewChatSettingTracker.imChatSettingGroupConfirmClick(chat: buriedPointChat)
        }
    }

    // 解散聊天
    private func disbandItem() -> CommonCellItemProtocol? {
        let chat = self.chat
        // 群聊是群主或者单聊是密聊
        guard self.showDisbandItem() else {
            return nil
        }

        let disbandGroupString: String
        if chat.type == .p2P && chat.isCrypto {
            disbandGroupString = BundleI18n.LarkChatSetting.Lark_Legacy_LeaveSecretChat
        } else {
            disbandGroupString = shouldShowToNormalGroup ?
                BundleI18n.LarkChatSetting.Calendar_Setting_DisbandMeetingGroup :
                BundleI18n.LarkChatSetting.Lark_Legacy_DisbandGroup
        }

        let disband = GroupSettingDisbandItem(
            type: .disbandGroup,
            cellIdentifier: GroupSettingDisbandCell.lu.reuseIdentifier,
            style: .auto,
            title: disbandGroupString
        ) { [weak self] _ in
            NewChatSettingTracker.imChatSettingDisbandClick(chatId: chat.id, chat: chat)
            NewChatSettingTracker.imChatSettingDismissGroupConfirmClick(chat: chat)
            self?.disbandGroup()
        }
        return disband
    }

    // 举报
    func reportItem() -> CommonCellItemProtocol? {
        guard !chat.isP2PAi else { return nil }
        let settingEnable = reportEnable ? true : userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteReport))
        if chat.type == .p2P {
            let isBot = chat.chatter?.type == .bot
            if isBot, userService?.userTenantBrand == .lark {return nil }
            guard !isMe, settingEnable, (!isBot || !self.openAppId.isEmpty) else {
                return nil
            }
        } else {
            guard settingEnable else {
                return nil
            }
        }

        return ChatInfoReportModel(
            type: .report,
            cellIdentifier: ChatInfoReportCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Chat_Report
        ) { [weak self] _ in
            guard let `self` = self else { return }
            NewChatSettingTracker.imChatSettingReportClick(chatId: self.chat.id)
            NewChatSettingTracker.imChatSettingReportNoneClick(chat: self.chat)
            self.reportGroup()
        }
    }
}

// MARK: 工具方法
extension ChatSettingActionModuleViewModel {
    // 客服群仅协助人（xxxHelper）可以退群
    private var canLeave: Bool {
        guard chat.isOncall else { return true }
        switch oncallRole {
        case .oncallHelper, .userHelper, .unknown:
            return true
        case .user, .oncall, .none:
            return false
        @unknown default:
            assert(false, "new value")
            return false
        }
    }

    private func createDisbandOrFrozenConfirmView() -> (UIView, UDCheckBox) {
        let contentView = UIView()
        let subTitleLabel = UILabel()
        subTitleLabel.text = BundleI18n.LarkChatSetting.Lark_IM_CanKeepHistoryButMembersGone_Desc
        subTitleLabel.numberOfLines = 0
        subTitleLabel.font = UIFont.systemFont(ofSize: 16)
        subTitleLabel.textColor = UIColor.ud.textTitle
        let tipLabel = UILabel()
        tipLabel.numberOfLines = 0
        /// paragraphStyle.lineBreakStrategy = none by default
        /// UILabel.lineBreakStrategy = standard by default
        /// 「 lineBreakStrategy = standard 」 会导致英文语言环境下两个单词被识别成一个整体而一起换行
        tipLabel.attributedText = NSAttributedString(string: BundleI18n.LarkChatSetting.Lark_IM_MembersHaveRecordsAfterGrpDisbanded_Desc,
                                                     attributes: [.paragraphStyle: NSParagraphStyle()])
        tipLabel.font = UIFont.systemFont(ofSize: 16)
        tipLabel.textColor = UIColor.ud.textTitle
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.tapCallBack = { $0.isSelected = !$0.isSelected }

        let layoutGuide = UILayoutGuide()
        contentView.addSubview(subTitleLabel)
        contentView.addLayoutGuide(layoutGuide)
        contentView.addSubview(checkBox)
        contentView.addSubview(tipLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        layoutGuide.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }
        checkBox.snp.makeConstraints { (maker) in
            maker.left.top.equalTo(layoutGuide)
            maker.size.equalTo(20)
        }
        tipLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(checkBox.snp.right).offset(12)
            maker.right.equalTo(layoutGuide.snp.right)
            maker.top.bottom.equalTo(layoutGuide)
        }
        return (contentView, checkBox)
    }

    // 触发解散群
    private func disbandGroup() {
        func supportFrozen() -> Bool {
            if !userResolver.fg.staticFeatureGatingValue(with: "im.chat.keep_chat_history") || AppConfigManager.shared.leanModeIsOn {
                return false
            }
            if !isOwner || chat.isCustomerService || chat.isMeeting || chat.isCrypto || chat.isAssociatedTeam || chat.isSuper {
                return false
            }
            return true
        }

        guard let targetVC = targetVC else { return }
        let titleString = chat.isCrypto ? "" : BundleI18n.LarkChatSetting.Lark_IM_DisbandThisGroup_Title
        let contentString: String
        if chat.isMeeting {
            contentString = BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingDisbandMeetingDeccribe
        } else if chat.isCrypto {
            contentString = BundleI18n.LarkChatSetting.Lark_Legacy_SecretChatDisbandNow
        } else {
            contentString = BundleI18n.LarkChatSetting.Lark_Legacy_GroupSettingDisbandDeccribe
        }
        let sureString = BundleI18n.LarkChatSetting.Lark_Legacy_Sure

        let alertController = LarkAlertController()
        alertController.setTitle(text: titleString)
        alertController.addCancelButton(dismissCompletion: { [weak self] in
            guard let self = self else { return }
            NewChatSettingTracker.imDismissGroupConfirmClick(chat: self.chat)
        })
        if supportFrozen() {
            let (view, checkBox) = self.createDisbandOrFrozenConfirmView()
            alertController.setContent(view: view)
            alertController.addDestructiveButton(text: sureString,
                                                 dismissCompletion: { [weak self, weak checkBox] in
                guard let self = self, let checkBox = checkBox else { return }
                if checkBox.isSelected {
                    self.frozen()
                } else {
                    self.doDisband()
                }
                NewChatSettingTracker.imChatSettingDisbandConfirmClick(chatId: self.chat.id, chat: self.chat)
            })
        } else {
            alertController.setContent(text: contentString)
            alertController.addDestructiveButton(text: sureString,
                                                 dismissCompletion: { [weak self] in
                guard let self = self else { return }
                NewChatSettingTracker.imChatSettingDisbandConfirmClick(chatId: self.chat.id, chat: self.chat)
                self.doDisband()
            })
        }
        self.userResolver.navigator.present(alertController, from: targetVC)
    }

    private func frozen() {
        let chatId = self.chat.id
        self.chatAPI?.frozenGroup(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                Self.logger.info("frozen group \(chatId) success")
                self?.targetVC?.popSelf()
            }, onError: { [weak self] error in
                Self.logger.error("frozen group failed", additionalData: ["chatID": chatId], error: error)
                guard let view = self?.targetVC?.viewIfLoaded else { return }
                UDToast.showFailureIfNeeded(on: view, error: error)
            }).disposed(by: disposeBag)
    }

    // 调用解散群接口并处理结果
    private func doDisband() {
        let chatId = self.chat.id
        self.chatService?.disbandGroup(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                SuspendManager.shared.removeSuspend(byId: chatId)
            }, onError: { [weak self] error in
                Self.logger.error("disband group failed", additionalData: ["chatID": chatId], error: error)
                guard let view = self?.targetVC?.viewIfLoaded else { return }
                UDToast.showFailureIfNeeded(on: view, error: error)
            }).disposed(by: disposeBag)
    }

    /* --- 退群相关 Start --- */
    // 检查是不是会议群，并返回对应的文案
    func getLeaveTipWithCheckIsMeeting(_ defaultLeaveMessage: String) -> String {
        guard chat.isMeeting else { return defaultLeaveMessage }

        if isMeetingOrganizer {
            return BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoExitMeetingNotifyOrganizer
        } else {
            return BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoExitGroupNotify(chat.displayName)
        }
    }

    // 获取退群提示Message
    func getLeaveTips() -> String {
        if chat.isOncall {
            return BundleI18n.LarkChatSetting.Lark_HelpDesk_DescofLeaveHelpDeskTip(chat.displayName)
        }

        let defaultMessage: String
        if isOwner {
            if chat.userCount == 1 {
                defaultMessage = BundleI18n.LarkChatSetting.Lark_Group_NoOtherMembersLeaveWillDisbandTitle
            } else {
                defaultMessage = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoTransferTips
            }
        } else if chat.isCrypto {
            defaultMessage = BundleI18n.LarkChatSetting.Lark_Legacy_SecretChatDisband
        } else {
            defaultMessage = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoExitGroupNotify(chat.displayName)
        }

        return getLeaveTipWithCheckIsMeeting(defaultMessage)
    }

    // MARK: - 点击退出群
    func leaveGroup() {
        ChatSettingTracker.trackExitGroup(chat: self.chat)
        guard let vc = self.targetVC else {
            assertionFailure("missing targetVC")
            return
        }
        self.leaveGroupAuth { [weak self] in
            guard let self = self else {
                return
            }
            // 是群主则需要选择是直接退出还是转让后退出,不是群主则直接退出
            if self.isOwner, self.chat.userCount > 1 {
                var body = QuitGroupBody(chatId: self.chat.id, isThread: self.isThread)
                body.tips = self.getLeaveTips()
                if Display.pad {
                    self.userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: vc,
                        prepare: { vc in
                            vc.modalPresentationStyle = LarkCoreUtils.formSheetStyle()
                        })
                } else {
                    self.userResolver.navigator.push(body: body, from: vc)
                }
            } else {
                let leaveString: String
                if self.chat.isOncall {
                    leaveString = BundleI18n.LarkChatSetting.Lark_HelpDesk_TitleofLeaveHelpDeskTip
                } else {
                    leaveString = BundleI18n.LarkChatSetting.Lark_Legacy_LeaveChat_Title
                }
                let alertController = LarkAlertController()
                alertController.setTitle(text: leaveString)
                alertController.setContent(text: self.getLeaveTips())
                alertController.addCancelButton(dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    NewChatSettingTracker.imDismissGroupConfirmClick(chat: self.chat)
                })
                alertController.addDestructiveButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_LeaveConfirm,
                                                     dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    NewChatSettingTracker.imChatSettingDisbandConfirmClick(chatId: self.chat.id, chat: self.chat)
                    self.doLeave()
                })

                self.userResolver.navigator.present(alertController, from: vc)
            }
        }
    }

    //检验退群权限
    private func leaveGroupAuth(pass: @escaping () -> Void) {
        guard let chatAPI = self.chatAPI, let targetVC = self.targetVC else {
            return
        }
        guard self.chat.isDepartment else {
            //非部门群无需鉴权
            pass()
            return
        }
        let ob = chatAPI.exitDepartmentGroupAuthorization(chatId: self.chat.id)
        DelayLoadingObservableWraper.wraper(observable: ob, showLoadingIn: targetVC.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                pass()
            }, onError: { [weak self] error in
                if let error = error.underlyingError as? APIError, error.code == 4056 {
                    // 鉴权失败
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_IM_LeaveDeptGrpNo_Title)
                    alertController.setContent(text: error.displayMessage)
                    alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_IM_OkICantLeave_Button)
                    self?.userResolver.navigator.present(alertController, from: targetVC)
                } else {
                    // 通用接口报错
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip,
                                        on: targetVC.view,
                                        error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    // 执行退群操作
    func doLeave() {
        guard let chatAPI = self.chatAPI else { return }
        let chatId = self.chat.id
        let currentId = self.currentUserId

        self.pushLocalLeaveGroup(with: chatId, status: .start)
        self.parsingUserOperation(
            chatAPI.deleteChatters(chatId: chatId, chatterIds: [currentId], newOwnerId: nil)
                .observeOn(MainScheduler.instance)
                .do(onNext: { [weak self] _ in
                    self?.pushLocalLeaveGroup(with: chatId, status: .success)
                    self?.pushLocalLeaveGroup(with: chatId, status: .completed)
                    if (self?.chat.chatMode ?? .default) == .threadV2, !(self?.chat.isPublic ?? true) {
                        self?.pushCenter.post(PushRemoveMeForRecommendList(channelId: chatId))
                    }
                    SuspendManager.shared.removeSuspend(byId: chatId)
                }, onError: { [weak self] _ in
                    self?.pushLocalLeaveGroup(with: chatId, status: .error)
                }),
            logMessage: "quit group failed")
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

    // Push 退群消息
    func pushLocalLeaveGroup(with channnelId: String, status: LocalLeaveGroupStatus) {
        self.pushCenter.post(PushLocalLeaveGroupChannnel(channelId: channnelId, status: status))
    }

    // MARK: - “举报”
    // 举报
    func reportGroup() {
        let vc = self.targetVC
        if chat.isSingleBot { botReport() } else { newReportGroup() }
    }

    func newReportGroup() {
        // 检查当前的是否已经点击了举报
        guard !self.reporting else { return }
        self.reporting = true
        // 获取服务端下发的举报链接
        self.chatAPI?.getChatReportLink(chatId: self.chat.id, language: LanguageManager.currentLanguage.rawValue)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                self?.reporting = false
                guard response.hasReportURL == true else { return }
                guard let self = self,
                      let url = URL(string: response.reportURL) else { return }
                self.openReportBrowser(url: url)
            }, onError: { [weak self](error) in
                self?.reporting = false
                guard let vc = self?.targetVC else { return }
                /// 获取服务端下发的举报链接失败
                let errorMessage = BundleI18n.LarkChatSetting.Lark_IM_Report_ReportFailedRetry_Toast
                if let view = vc.viewIfLoaded {
                    UDToast.showFailure(with: errorMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    // 服务端人力问题不支持判断是否为机器人,沿用老的举报逻辑
    func botReport() {
        let paramsJSONData: Data?
        let type: String
        /// map to jsonstring
        if chat.type == .p2P, let chatter = chat.chatter {
            if chatter.type == .bot {
                paramsJSONData = try? JSONSerialization.data(
                    withJSONObject: ["app_id": self.openAppId],
                    options: .prettyPrinted)
                type = "app"
            } else {
                /// map to jsonstring
                paramsJSONData = try? JSONSerialization.data(
                    withJSONObject: ["chatter_id": chatter.id, "is_cross_tenant": chat.isCrossTenant ? 1 : 0],
                    options: .prettyPrinted)
                type = "chatter"
            }
        } else {
            type = "chat"
            paramsJSONData = try? JSONSerialization.data(
                withJSONObject: ["chat_id": self.chat.id],
                options: .prettyPrinted)
        }
        guard let data = paramsJSONData else { return }
        guard let paramsJSONString = String(data: data, encoding: .utf8) else { return }
        /// push url
        guard var url =
                URL(string: "https://\(DomainSettingManager.shared.currentSetting[.suiteReport]?.first ?? "")/report/")
        else { return }
        url = url.lf.appendPercentEncodedQuery(["type": type, "params": paramsJSONString])
        openReportBrowser(url: url)
    }

    // 打开举报页面的WebBrowser
    func openReportBrowser(url: URL) {
        guard let vc = self.targetVC else {
            assertionFailure("missing targetVC")
            return
        }
        if Display.pad {
            self.userResolver.navigator.present(url,
                                     wrap: LkNavigationController.self,
                                     from: vc,
                                     prepare: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        } else {
            self.userResolver.navigator.push(url, from: vc)
        }
    }
}
