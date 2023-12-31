//
//  MailSettingManager.swift
//  MailSDK
//
//  Created by majx on 2020/9/6.
//

import Foundation
import RxSwift
import Logger
import RustPB
import ThreadSafeDataStructure
import EENavigator
import LarkAlertController
import LarkUIKit
import SwiftProtobuf
import LarkContainer
import LarkStorage

typealias MailGetAccountResponse = Email_Client_V1_MailGetAccountResponse
typealias MailClientConfig = Email_Client_V1_EmailClientConfig
typealias MailSetting = Email_Client_V1_Setting
typealias MailReplyLanguage = Email_Client_V1_Setting.ReplyLanguage
typealias MailStorageLimitNotify = Email_Client_V1_StorageLimitNotify
typealias MailChannelPosition = Email_Client_V1_Setting.ChannelPosition
typealias MailSlideAction = Email_Client_V1_SlideAction
typealias MailSlideActionType = Email_Client_V1_SlideAction.SlideActionType
typealias MailAttachmentLocation = Email_Client_V1_Setting.AttachmentLocation
typealias MailAutoCCType = Email_Client_V1_AutoCCAction.AutoCCType
typealias MailNotificationScope = Email_Client_V1_Setting.NotificationScope

public enum MailSettingClientStatus {
    case saas
    case mailClient
    case coExist
}

public struct MailBatchChangeInfo {
    var sessionID: String
    let request: SwiftProtobuf.Message
    var status: MailBatchResultStatus
    var totalCount: Int32
    var progress: Float
}

enum MailPermissionChangeStatus {
    case mailClientRevoke
    case lmsRevoke
    case gcRevoke
    case mailClientAdd
    case lmsAdd(_: String)
    case gcAdd
    case apiMigration(_: String)
}

// 这里管理目前所有的设置修改
enum MailSettingAction {
    enum VacationResponder {
        case enable(_: Bool)
        case startTimestamp(_: Int64)
        case endTimestamp(_: Int64)
        case onlySendToTenant(_: Bool)
        case images(_: [MailClientDraftImage])
        case autoReplyBody(_: String)
        case autoReplySummary(_: String)
    }

    enum Signature {
        case enable(_: Bool)
        case text(_: String)
        case mobileUsePcSignature(_: Bool)
    }

    enum StatusSmartInboxOnboarding {
        case smartInboxAlertRendered(_: Bool)
        case smartInboxPromptRendered(_: Bool)
    }

    case newMailNotification(enable: Bool)
    case allNewMailNotificationSwitch(enable: Bool)
    case newMailNotificationChannel(_: MailChannelPosition, enable: Bool)
    case newMailNotificationScope(_: MailNotificationScope)
    case smartInboxMode(enable: Bool)
    case strangerMode(enable: Bool)
    case signature(_: Signature)
    case vacationResponder(_: VacationResponder)
    case statusSmartInboxOnboarding(_: StatusSmartInboxOnboarding)
    case statusIsMigrationDonePromptRendered(_: Bool)
    case lastVisitImportantLabelTimestamp(_: Int64)
    case lastVisitOtherLabelTimestamp(_: Int64)
    case lastVisitStrangerLabelTimestamp(_: Int64)
    case accountRevokeNotifyPopupVisible(_: Bool)
    case undoSend(enable: Bool, undoTime: Int64)
    case replyLanguage(_: MailReplyLanguage)
    case storageLimitNotify(_: MailStorageLimitNotify)
    case showApiOnboarding
    case conversationMode(enable: Bool)
    case senderAlias(_: MailClientAddress)
    case setDefaultAlias(_: MailClientAddress)
    case deleteAlias(_: MailClientAddress)
    case appendAlias(_: MailClientAddress)
    case conversationRankMode(atBottom: Bool)//新邮件排序
    case swipeAction(_: MailSlideAction)
    case webImageDisplay(enable: Bool)
    case autoCC(enable: Bool, type: MailAutoCCType)
    case attachmentLocation(_: MailAttachmentLocation)
}

struct MailAccountInfo {
    let accountId: String
    let address: String
    let isOAuthAccount: Bool
    var status: MailClientConfig.ConfigStatus?
    let isShared: Bool
    var isSelected: Bool
    var unread: Int64
    var notification: Bool
    var userType: Email_Client_V1_Setting.UserType
    var isMigrating: Bool // 开启imap搬家鉴权
}

struct MailClientAccountInfo {
    let accountID: String
    let provider: MailTripartiteProvider
    let address: String
    let protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum
}

extension Email_Client_V1_Setting.UserType {
    func priorityValue() -> Int {
        switch self {
        case .tripartiteClient:
            return -1
        @unknown default:
            return 0
        }
    }
}

public var MailSettingManagerInterface: MailSettingManager {
    return Store.settingData
}

public final class MailSettingManager {
    let disposeBag = DisposeBag()
    private var accountInfos: SafeAtomic<[MailAccountInfo]?> = nil + .readWriteLock
    private(set) var currentAccount: SafeAtomic<MailAccount?> = nil + .readWriteLock
    private(set) var primaryAccount: SafeAtomic<MailAccount?> = nil + .readWriteLock
    private var currentAccType: String = "" // cache值，不加锁，用于埋点上报
    private(set) var accountList: SafeAtomic<[MailAccount]?> = nil + .readWriteLock
    private var netSettingGetSuccess: SafeAtomic<Bool> = false + .readWriteLock
    private var tabVCFetchSettingSuccess: SafeAtomic<Bool> = false + .readWriteLock
    private var currentSigData: SafeAtomic<SigListData?> = nil + .readWriteLock
    private var currentSigAccountId: SafeAtomic<String> = "" + .readWriteLock
    private var expriedMap: SafeAtomic<[String: Bool]> = [:] + .readWriteLock
    private var migrateStatMap: SafeAtomic<[String: Bool]> = [:] + .readWriteLock
    private var oauthState: SafeAtomic<[String: MailClientAccountInfo]> = [:] + .readWriteLock
    // accountID为key (sessionID, 对应请求)元组为value
    private(set) var batchChangeSessions: SafeAtomic<[String: [MailBatchChangeInfo]]> = [:] + .readWriteLock
    private lazy var dataCenter: MultiAccountDataCenter = self.makeMultiAccountDataCenter()
    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }
    var currentUserContext: MailUserContext? {
        if let userContext = try? Container.shared.getCurrentUserResolver().resolve(assert: MailUserContext.self) {
            return userContext
        } else {
            mailAssertionFailure("[UserContainer] Access UserContext in setting manager before user login")
            return nil
        }
    }
    public var mailClient: Bool {
        if let userType = currentAccount.value?.mailSetting.userType {
            if userType == .noPrimaryAddressUser && clientStatus == .mailClient {
                return true
            }
            return userType == .tripartiteClient
        } else {
            return false
        }
    }
    public var clientStatus: MailSettingClientStatus = .saas

    /// 如果用户没有开启Lark mail，包括未绑定、关闭Email tab等，return false
    var hasEmailService: Bool {
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType != .newUser, !setting.emailAlias.defaultAddress.address.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    /// 用户是否绑定了企业邮箱
    var hasEnterpriseMail: Bool {
        return Store.settingData.getCachedAccountList()?.first(where: { $0.mailSetting.userType != .noPrimaryAddressUser && $0.mailSetting.userType != .tripartiteClient  }) != nil
    }

    /// 判断用户是否能使用大搜，包括未绑定、关闭Email tab，纯三方等状态无法使用
    public var hasLarkSearchService: Bool {
        if Store.settingData.clientStatus == .mailClient {
            return false
        }
        if let account = Store.settingData.getCachedCurrentAccount() {
            return !account.isUnuse()
        } else {
            return false
        }
    }

    // MARK: Observable
    @DataManagerValue<()> var accountInfoChanges

    @DataManagerValue<()> var netSettingPush

    @DataManagerValue<(MailPermissionChangeStatus, Bool)> var permissionChanges // Bool代表是否需要将页面退出到首屏，用于当前账号被回收的场景

    /// reboot home vc 用于需要重刷首页的情况，exp 共存->纯三方(且没有三方账号，需要跳转到添加页，这里直接走一次冷启动判断逻辑)
    @DataManagerValue<()> var rebootChanges

    /// 刷新多账号banner
    @DataManagerValue<()> var accountListChanges
    
    /// Stranger Batch Change Sessions
    @DataManagerValue<([MailBatchChangeInfo])> var batchSessionChanges
    private(set) var strangerModeChangeInfo: (Bool, String)?

    @DataManagerValue<([MailThreadCellSwipeAction], [MailThreadCellSwipeAction])> var swipeActionChanges
    private(set) var swipeActions: SafeAtomic<([MailThreadCellSwipeAction], [MailThreadCellSwipeAction])> = ([.archive], [.read]) + .readWriteLock

    @DataManagerValue<()> var easSyncRangeChanges
    
    @DataManagerValue<()> var preloadRangeChanges

    init() {
        addObserver()
    }
    
    func updateOauthState(state: String, info: MailClientAccountInfo) {
        oauthState.value.updateValue(info, forKey: state)
    }
    
    func getOauthStateInfo(state: String) -> MailClientAccountInfo? {
        return oauthState.value[state]
    }

    func deleteOauthState(state: String) {
        oauthState.value.removeValue(forKey: state)
    }

    func cleanCache() {
        accountInfos.value = nil
        currentAccount.value = nil
        accountList.value = nil
        currentSigData.value = nil
        currentSigAccountId.value = ""
        primaryAccount.value = nil
        oauthState.value = [:]
        netSettingGetSuccess.value = false
        resetTabVCSettingLoadedFlag()
    }

    func findCurrentSetting(account: MailAccount) -> Email_Client_V1_Setting {
        if account.accountSelected.isSelected {
            return account.mailSetting
        } else if let selectedAccount = account.sharedAccounts.first(where: { $0.accountSelected.isSelected }) {
            return selectedAccount.mailSetting
        }
        return account.mailSetting
    }

    func makeMultiAccountDataCenter() -> MultiAccountDataCenter {
        switch clientStatus {
        case .saas:
            return MultiAccountSaasDataCenter()
        case .mailClient:
            return MultiAccountMailClientDataCenter(userKVStore: makeUserKVStore())
        case .coExist:
            return MultiAccountCoExistDataCenter(userKVStore: makeUserKVStore())
        }
    }

    func makeUserKVStore() -> MailKVStore {
        if let userID = currentUserContext?.user.userID {
            return MailKVStore(space: .user(id: userID), mSpace: .global)
        } else {
            return MailKVStore(space: .global, mSpace: .global)
        }
    }

    func acceptCurrentAccountChange() {
        EventBus.$accountChange.accept(.currentAccountChange)
    }

    func addObserver() {
        EventBus
            .accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                guard let self = self else { return }
                switch change {
                case .accountChange(let change):
                    self.dataCenter.handleAccountChange(change: change)
                    self.updatePrimaryAccountCacheIfNeeded(change.account)
                case .shareAccountChange(let change):
                    self.dataCenter.handleShareAccountChange(change: change)
                    if !change.account.mailAccountID.isEmpty {
                        self.updatePrimaryAccountCacheIfNeeded(change.account)
                        self.updateClientStatusIfNeeded()
                    }
                case .currentAccountChange:
                    // nothing
                    break
                case .unknow:
                    mailAssertionFailure("accountChange .unknow happen")
                }
        }).disposed(by: disposeBag)

        EventBus
            .unreadCountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
            guard let `self` = self else { return }
            if case .unreadThreadCount(let change) = push {
                MailLogger.info("mail setting manager mail unread thread changed")
                self.updateAccountUnread(by: change.countMap)
            }
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SDK_CLEAN_DATA)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] noti in
            guard let `self` = self else { return }
            self.cleanCache()
        }).disposed(by: disposeBag)
        
        MailCommonDataMananger
            .shared
            .batchResultChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.mailBatchResultChanges(change)
            }).disposed(by: disposeBag)
    }
    
    func mailBatchResultChanges(_ change: MailBatchResultChange) {
        MailLogger.info("[mail_stranger] Store mailBatchResultChanges change: \(change)")
        guard change.scene == .stranger else {
            return
        }
        guard let mailAccountID = self.getCachedCurrentAccount()?.mailAccountID else {
            return
        }
        var currentSessions = self.batchChangeSessions.value[mailAccountID] ?? []
        /// 只更新缓存，只有用户主动操作会清理，否则可能存在push/Toast等交互需要最终状态
        let accountID = strangerModeChangeInfo?.1 ?? ""
        if let enable = strangerModeChangeInfo?.0, enable == false, // 只有关闭功能会需要增加session进行弹窗
           var account = getCachedAccountList()?.first(where: { $0.mailAccountID == accountID }) {
            var req = Email_Client_V1_MailUpdateAccountRequest()
            account.mailSetting.enableStranger = enable
            req.account = account
            if !currentSessions.map({ $0.sessionID }).contains(change.sessionID) {
                // push与callback时序不保证的时候可能会重复添加，增加保护
                currentSessions.append(MailBatchChangeInfo(sessionID: change.sessionID, request: req, status: change.status, totalCount: change.totalCount, progress: change.progress))
            }
            self.strangerModeChangeInfo = nil
        }
        var changeSessionIndex = -1
        for (index, changeSession) in currentSessions.enumerated() where changeSession.sessionID == change.sessionID {
            changeSessionIndex = index
        }
        if changeSessionIndex != -1 {
            if currentSessions[changeSessionIndex].status != .canceled { // 端上已取消的需要屏蔽更新
                currentSessions[changeSessionIndex].status = change.status
            }
            currentSessions[changeSessionIndex].totalCount = change.totalCount
            currentSessions[changeSessionIndex].progress = change.progress
        }
        self.batchChangeSessions.value.updateValue(currentSessions, forKey: mailAccountID)
        self.$batchSessionChanges.accept(currentSessions)
    }
    
    func updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo, pushChange: Bool = true, replaceSessionID: String = "") {
        guard let mailAccountID = self.getCachedCurrentAccount()?.mailAccountID else {
            return
        }
        var currentSessions = self.batchChangeSessions.value[mailAccountID] ?? []
        var changeSessionIndex = -1
        if replaceSessionID.isEmpty {
            for (index, changeSession) in currentSessions.enumerated() where changeSession.sessionID == batchChangeInfo.sessionID {
                changeSessionIndex = index
            }
        } else {
            for (index, changeSession) in currentSessions.enumerated() where changeSession.sessionID == replaceSessionID {
                changeSessionIndex = index
            }
        }
        if changeSessionIndex != -1 {
            if !replaceSessionID.isEmpty {
                currentSessions[changeSessionIndex].sessionID = batchChangeInfo.sessionID
            }
            if currentSessions[changeSessionIndex].status != .canceled { // 端上已取消的需要屏蔽更新
                currentSessions[changeSessionIndex].status = batchChangeInfo.status
            }
            currentSessions[changeSessionIndex].totalCount = batchChangeInfo.totalCount
            currentSessions[changeSessionIndex].progress = batchChangeInfo.progress

        } else {
            currentSessions.append(batchChangeInfo)
        }
        self.batchChangeSessions.value.updateValue(currentSessions, forKey: mailAccountID)
        if pushChange {
            self.$batchSessionChanges.accept(currentSessions)
        }
    }
    
    func getBatchChangeSessionInfos() -> [MailBatchChangeInfo] {
        guard let mailAccountID = self.getCachedCurrentAccount()?.mailAccountID,
              let currentSessions = self.batchChangeSessions.value[mailAccountID] else {
            return []
        }
        return currentSessions
    }
    
    func clearBatchChangeSessionIDs(_ sessionID: String, forceClear: Bool = false) {
        guard let mailAccountID = self.getCachedCurrentAccount()?.mailAccountID else {
            return
        }
        var currentSessions = self.batchChangeSessions.value[mailAccountID] ?? []
        self.batchChangeSessions.value.updateValue(currentSessions, forKey: mailAccountID)
        if let modeChangeInfo = strangerModeChangeInfo, modeChangeInfo.1 == mailAccountID {
            /// 主动取消的case，同时清理接收setting修改push的标记位
            if let clearSession = currentSessions.first(where: { $0.sessionID == sessionID }),
               let req = clearSession.request as? Email_Client_V1_MailUpdateAccountRequest,
               req.account.mailSetting.enableStranger == modeChangeInfo.0 {
                MailLogger.info("[mail_stranger] user cancel disable stranger mode, clear strangerModeChangeInfo")
                strangerModeChangeInfo = nil
            }
        }
        if let changeSessionIndex = currentSessions.firstIndex(where: { $0.sessionID == sessionID }) {
            if currentSessions[changeSessionIndex].status == .processing {
                currentSessions[changeSessionIndex].status = .canceled
            }
        }
        if forceClear {
            currentSessions.removeAll(where: { $0.sessionID == sessionID })
        }
        self.batchChangeSessions.value.updateValue(currentSessions, forKey: mailAccountID)
        self.$batchSessionChanges.accept(currentSessions)
    }

    func shareAccountChangeDefaultHandler(_ change: MailSharedAccountChange) {
        guard !change.account.mailAccountID.isEmpty else { return }
        if change.isBind {
            var accountInfos = Store.settingData.getAccountInfos()
            accountInfos.append(MailSettingManager.getInfo(of: change.account, isMigrating: false, primaryAccount: change.account))
            Store.settingData.setAccountInfos(of: accountInfos)
            if var accountLists = Store.settingData.getCachedAccountList(), !accountLists.map({ $0.mailAccountID }).contains(change.account.mailAccountID) {
                accountLists.append(change.account)
                Store.settingData.updateAccountList(accountLists)
                if change.account.mailSetting.userType == .tripartiteClient {
                    let kvStore = makeUserKVStore()
                    kvStore.set(true, forKey: "mail_client_account_onboard_\(change.account.mailAccountID)")
                }
            }
        } else {
            Store.settingData.setAccountInfos(of: Store.settingData.getAccountInfos().filter({ $0.accountId != change.account.mailAccountID }))
            if var accountLists = Store.settingData.getCachedAccountList(),
               accountLists.map({ $0.mailAccountID }).contains(change.account.mailAccountID) {
                accountLists = accountLists.filter({ $0.mailAccountID != change.account.mailAccountID })
                Store.settingData.updateAccountList(accountLists)
            }
        }
        Store.settingData.$accountInfoChanges.accept(())
    }

    func updatePrimaryAccountCacheIfNeeded(_ account: MailAccount) {
        if !account.isShared {
            primaryAccount.value = account
        }
    }

    func hasMailClient() -> Bool {
        return Store.settingData.clientStatus == .mailClient || Store.settingData.clientStatus == .coExist
    }

    func isMailClient(_ accountId: String) -> Bool {
        if let account = getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }) {
            return account.mailSetting.userType == .tripartiteClient
        }
        return false
    }

    public func updateCachedCurrentAccount(_ account: MailAccount, pushChange: Bool = true, accountList: [MailAccount]? = nil) {
        if let accountList = accountList, pushChange {
            updateAccountList([account] + accountList)
        }
        if let currentAccount = ([account] + (self.accountList.value ?? [])).first(where: { $0.accountSelected.isSelected }) {
            selectMailClientAcc(acc: currentAccount)
            handleAccountUpdate(currentAccount, pushChange: pushChange)
        } else {
            MailLogger.error("[mail_client] coexist updateCachedCurrentAccount by default, accList data is not ready")
            selectMailClientAcc(acc: account)
            handleAccountUpdate(account, pushChange: pushChange)
            updateCacheConst()
        }
    }

    func updateAccountList(_ accountList: [MailAccount]) {
        let validAccountList = accountList.filter({ $0.isValid() })
        MailLogger.info("[mail_client] coexist updateAccountList account: \(accountList.count) validAccountList: \(validAccountList.count)")
        self.accountList.value = validAccountList
    }

    /// 三方客户端的主账号为空壳，需要映射到共享账号中的第一个 或 选中的一个
    private func selectMailClientAcc(acc: MailAccount) {
        var account: MailAccount? = acc
        if clientStatus == .mailClient {
            account = getMailClientAccount()
        }
        if let account = account, account.isValid() {
            currentAccount.value = account
        } else {
            MailLogger.info("[mail_home] currentAccount set default value, invaild!!")
        }
        updateCacheConst()
        updateCacheSwipeAction()
    }

    private func updateCacheConst() {
        currentAccType = _getMailAccountType(account: currentAccount.value)
    }

    private func updateCacheSwipeAction() {
        let actionSetting: Email_Client_V1_SlideAction? = {
            if clientStatus == .mailClient {
                return primaryAccount.value?.mailSetting.slideAction
            } else {
                return currentAccount.value?.mailSetting.slideAction
            }
        }()
        guard let slideAction = actionSetting else {
            return
        }
        updateSwipeActions(slideAction)
    }

    func updateSwipeActions(_ slideAction: Email_Client_V1_SlideAction) {
        swipeActions.value = (slideAction.rightSlideActionOn ?
                              slideAction.rightSlideAction.removeUnsupport(inSetting: false).convertToSwipeAction() : [],
                              slideAction.leftSlideActionOn ?
                              slideAction.leftSlideAction.removeUnsupport(inSetting: false).convertToSwipeAction() : [])
        self.$swipeActionChanges.accept((swipeActions.value))
    }
    
    private func handleAccountUpdate(_ account: MailAccount, pushChange: Bool = true) {
        if let newId = currentAccount.value?.mailAccountID, !newId.isEmpty, newId != currentSigAccountId.value {
            // 账号信息有变化，重新更新签名信息
            currentSigData.value = nil
            getCurrentSigListData().subscribe()
        }
        if pushChange {
            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED, object: nil)
        }
    }

    /// 获取缓存的 current setting，适用于需要同步获得 setting 的情况
    func getCachedCurrentSetting() -> MailSetting? {
        if mailClient {
            return getMailClientAccount()?.mailSetting
        } else {
            if let currentAccount = currentAccount.value {
                return currentAccount.mailSetting
            }
            _ = getCurrentSetting().subscribe()
            return nil
        }
    }

    func getMailClientAccount() -> MailAccount? {
        if let selectedTriAcc = accountList.value?.first(where: { $0.mailSetting.userType == .tripartiteClient && $0.accountSelected.isSelected }) {
            return selectedTriAcc
        } else {
            return nil
        }
    }

    func getAvailableMailClientAccount() -> MailAccount? {
        if let selectedTriAcc = accountList.value?.first(where: { $0.mailSetting.userType == .tripartiteClient && $0.accountSelected.isSelected }) {
            return selectedTriAcc
        } else if let firstTriAccc = accountList.value?.first(where: { $0.mailSetting.userType == .tripartiteClient }) {
            return firstTriAccc
        } else {
            return nil
        }
    }

    func switchToAvailableAccountIfNeeded() {
        // 三方场景下，新建三方账号后，未收到ShareAccountPush之前App退出，会导致端上未执行切账号而获取当前账号异常，此为兜底逻辑
        if Store.settingData.clientStatus == .mailClient,
           let nextAccID = getAvailableMailClientAccount()?.mailAccountID {
            Store.settingData.switchMailAccount(to: nextAccID).subscribe(onNext: { [weak self] (_) in
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
            }, onError: { (err) in
                mailAssertionFailure("err in switch account \(err)")
            }).disposed(by: self.disposeBag)
        }
    }


    /// 获取缓存的 current account，适用于需要同步获得 account 的情况
    public func getCachedCurrentAccount(fetchNet: Bool = true) -> MailAccount? {
        if clientStatus == .mailClient {
            if let account = getMailClientAccount(), account.isValid() {
                return account
            } else {
                return nil
            }
        } else {
            if let currentAccount = currentAccount.value, currentAccount.isValid() {
                return currentAccount
            }
            if fetchNet {
                _ = getCurrentAccount().subscribe()
            }
            
            return nil
        }
    }

    public func getCachedCurrentAccountAlignRust(fetchNet: Bool = true) -> MailAccount? {
        if let currentAccount = currentAccount.value, currentAccount.isValid() {
            return currentAccount
        }
        if fetchNet {
            _ = getCurrentAccount().subscribe()
        }

        return nil
    }
    
    func checkPushValid(push: MailAccountChange) -> Bool {
        if FeatureManager.open(FeatureKey(fgKey: .disableAccountValidCheck,
                                       openInMailClient: true)) {
            return true
        }
        if let cachedAccount = getCachedPrimaryAccount(),
           cachedAccount.accountSelected.timestamp > 0, push.account.accountSelected.timestamp > 0 {
            if push.account.accountSelected.timestamp > cachedAccount.accountSelected.timestamp {
                return true
            } else {
                MailLogger.info("[checkPushValid] ignore push, cacheTime=\(cachedAccount.accountSelected.timestamp), pushTime=\(push.account.accountSelected.timestamp), cacheId=\(cachedAccount.mailAccountID),pushId=\(push.account.mailAccountID)")
                return false
            }
        }
        return true
    }

    func getCachedPrimaryAccount() -> MailAccount? {
        return primaryAccount.value
    }

    func getCachedAccountList() -> [MailAccount]? {
        return dataCenter.getCachedAccountList()
    }

    func deleteAccountFromList(_ accID: String) {
        guard var list = accountList.value else { return }
        if let index = list.firstIndex(where: { $0.mailAccountID == accID }) {
            list.remove(at: index)
            accountList.value = list
        }
    }

    func updateAccountInList(_ account: MailAccount) {
        guard var list = accountList.value else { return }
        if let index = list.firstIndex(where: { $0.mailAccountID == account.mailAccountID }) {
            list[index] = account
            accountList.value = list
        }
    }
    
    func getCachedCurrentSigData() -> SigListData? {
        if let data = currentSigData.value {
            return data
        }
        getCurrentSigListData().subscribe()
        return nil
    }

    func checkRepeatAddress(_ address: String?) -> Bool {
        guard let address = address else {
            return false
        }
        guard let existAddresses = getCachedAccountList()?
            .filter({ $0.mailSetting.userType == .tripartiteClient })
            .map({ $0.accountAddress.lowercased() }) else {
            return false
        }
        return existAddresses.contains(address.lowercased())
    }

    public func ifNetSettingLoaded() -> Bool {
        return netSettingGetSuccess.value
    }

    public func netSettingLoadedNotify() {
        self.$netSettingPush.accept(())
        self.netSettingGetSuccess.value = true
    }

    func ifTabVCSettingLoaded() -> Bool {
        return tabVCFetchSettingSuccess.value
    }

    func resetTabVCSettingLoadedFlag() {
        tabVCFetchSettingSuccess.value = false
    }

    func tabVCFetchSettingLoadedNotify() {
        self.tabVCFetchSettingSuccess.value = true
    }
    
    public func mailSettingTitle() -> String {
        return BundleI18n.MailSDK.Mail_Normal_Email
    }

    func folderOpen() -> Bool {
        let userType = currentAccount.value?.mailSetting.userType
        let mailType = currentAccount.value?.mailSetting.emailClientConfigs.first?.mailType

        if userType == .exchangeClient || userType == .exchangeClientNewUser || userType == .tripartiteClient {
            return true
        }

        if userType == .oauthClient || userType == .newUser {
            if mailType != .gmail && mailType != .none {
                return true
            } else {
                return FeatureManager.open(.gmailFolder)
            }
        }

        return true
    }

    // 获取当前所在的账号设置，通过这种方式拿到的账号设置，会合并主账号的数据
    func getCurrentSetting(fetchDb: Bool = true) -> Observable<MailSetting> {
        if fetchDb {
            // 如果有setting，尽快返回
            if let currentSetting = currentAccount.value?.mailSetting {
                return Observable.create({ (ob) -> Disposable in
                    ob.onNext(currentSetting)
                    ob.onCompleted()
                    return Disposables.create()
                })
            }
        }

        return getAccount(fetchDb: fetchDb).map { (responseAccount) -> MailSetting in
            if let currentAcc = ([responseAccount] + responseAccount.sharedAccounts).first(where: { $0.accountSelected.isSelected }) {
                return currentAcc.mailSetting
            }
            return responseAccount.mailSetting
        }
    }

    public func getAccount(fetchDb: Bool = true) -> Observable<MailAccount> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        MailLogger.info("[mail_client] getAccount fetchDb: \(fetchDb)")
        return fetcher.getPrimaryAccount(fetchDb: fetchDb).map { (response) -> MailAccount in
            return response.account
        }
    }

    public func updatePrimaryAcc(_ account: MailAccount) {
        MailLogger.info("[mail_client] coexist updatePrimaryAcc account: \(account.mailAccountID)")
        if account.isValid() {
            self.primaryAccount.value = account
        }
    }

    public func updateClientStatusIfNeeded() {
        let lastClientStatus = clientStatus
        guard let primaryAccount = primaryAccount.value else {
            MailLogger.error("[mail_client] coexist primaryAccount is nil")
            return
        }
        let enableMailClient = primaryAccount.mailSetting.isThirdServiceEnable && FeatureManager.realTimeOpen(.mailClient)
        if enableMailClient {
            if primaryAccount.mailSetting.userType == .noPrimaryAddressUser || isInIMAPFlow(primaryAccount) {
                Store.settingData.clientStatus = .mailClient
            } else {
                Store.settingData.clientStatus = .coExist
            }
        } else {
            Store.settingData.clientStatus = .saas
        }
        if lastClientStatus != clientStatus {
            MailLogger.info("[mail_client] coexist enableMailClient: \(enableMailClient)")
            MailLogger.info("[mail_client] coexist clientStatus update to -> \(clientStatus)")
            dataCenter = self.makeMultiAccountDataCenter()
        }
    }

    func resetClientStatus() {
        MailLogger.info("[mail_client] coexist resetClientStatus")
        Store.settingData.clientStatus = .saas
        dataCenter = self.makeMultiAccountDataCenter()
    }

    func isInIMAPFlow(_ account: MailAccount) -> Bool {
        if FeatureManager.open(.imapMigration, openInMailClient: false) {
            return account.mailSetting.userType == .exchangeClient && account.mailSetting.mailOnboardStatus == .forceInput
        } else {
            if account.isShared {
                return false
            }
            return (account.mailSetting.userType == .larkServer || account.mailSetting.userType == .exchangeClient) && account.mailSetting.mailOnboardStatus == .forceInput
        }
    }

    // 获取全量的 account list
    func getAccountList(fetchDb: Bool = true) -> Observable<(currentAccountId: String, accountList: [MailAccount])> {
        return dataCenter.getAccountList(fetchDb: fetchDb)
    }

    // 获取主账号信息
    func getPrimaryAccount() -> Observable<MailAccount> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getPrimaryAccount().map { (response) -> MailAccount in
            return response.account
        }
    }

    // 获取当前所在的账号信息
    // 通过这种方式拿到的账号设置，会合并主账号的数据
    public func getCurrentAccount() -> Observable<MailAccount> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getCurrentAccount().map { (response) -> MailAccount in
            return response.account
        }
    }
    
    // 检查usage是否发生了变化
    func checkSigUsage(origin: [SignatureUsage], new: [SignatureUsage]) {
        var needClear = false
        if origin.count != new.count {
            needClear = true
        }
        if !needClear {
            var originSort = origin.sorted { $0.address < $1.address }
            var newSort = new.sorted { $0.address < $1.address }
            for (index, usage) in originSort.enumerated() {
                if usage != newSort[index] {
                    needClear = true
                    break
                }
            }
        }
        if needClear {
            DispatchQueue.main.async {
                Store.editorLoader?.changeNewEditor(type: .settingChange)
            }
        }
    }
    
    public func processSigData(resp: Email_Client_V1_MailGetSignatureResponse,
                                email: String?,
                                name: String?) -> Email_Client_V1_MailGetSignatureResponse {
        var resData = resp
        // 处理名字和邮箱信息
        for (index, sig) in resp.signatures.enumerated() {
            let data = Data(sig.templateValueJson.utf8)
            var jsonDic: [String: Any] = [:]
            if var dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                jsonDic = dic
            }
            jsonDic["B-NAME"] = name ?? ""
            jsonDic["B-ENTERPRISE-EMAIL"] = email ?? ""
            guard let stringData = try? JSONSerialization.data(withJSONObject: jsonDic, options: []),
                let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue) else {
                continue
            }
            resData.signatures[index].templateValueJson = JSONString as String
        }
        return resData
    }
    
    func getCurrentSigListData() -> Observable<Void> {
        if !FeatureManager.realTimeOpen(.enterpriseSignature) {
            return Observable.empty()
        }
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        guard let accountId = self.currentAccount.value?.mailAccountID, !accountId.isEmpty else {
            MailLogger.error("mailAccountID is empty")
            return Observable.empty()
        }
        let name = self.currentAccount.value?.accountName
        let email = self.currentAccount.value?.accountAddress
        return fetcher.getSignaturesRequest(fromSetting: false,
                                            accountId: accountId).map { [weak self] (resp) -> Void in
            guard let `self` = self else { return }
            let resData = Store.settingData.processSigData(resp: resp,
                                                             email: email,
                                                             name: name)
            self.currentSigAccountId.value = accountId
            self.checkSigUsage(origin: self.currentSigData.value?.signatureUsages ?? [], new: resData.signatureUsages)
            self.currentSigData.value = resData
            for signature in resData.signatures {
                signature.images.forEach { (image) in
                    if !image.cid.isEmpty && !image.fileToken.isEmpty {
                        let value = ["imageName": image.imageName, "fileToken": image.fileToken]
                        self.currentUserContext?.cacheService.set(object: value as NSCoding, for: image.cid)
                    }
                }
            }
            return
        }
    }

    func updateCurrentSigData(_ sigData: SigListData) {
        self.currentSigData.value = sigData
    }

    func getAccountInfos(fetchDB: Bool = true) -> [MailAccountInfo] {
        if Store.settingData.clientStatus == .mailClient {
            return _getAccountInfos().filter({ $0.isShared && $0.userType == .tripartiteClient })
        } else if Store.settingData.clientStatus == .saas {
            return _getAccountInfos().filter({ $0.userType != .tripartiteClient })
        } else {
            return _getAccountInfos()
        }
    }

    private func _getAccountInfos(fetchDB: Bool = true) -> [MailAccountInfo] {
        if let infos = accountInfos.value {
            return infos
        } else {
            if fetchDB {
                _ = getAccountList()
            }
        }
        return []
    }

    func getOtherAccountUnreadBadge() -> (count: Int64, isRed: Bool) {
        if let currentAccountId = currentAccount.value?.mailAccountID {
            var redCount: Int64 = 0
            var grayCount: Int64 = 0
            var isRed: Bool = false
            getAccountInfos().forEach { (info) in
                if info.accountId != currentAccountId {
                    if info.notification {
                        redCount += info.unread
                        isRed = true
                    } else {
                        grayCount += info.unread
                    }
                }
            }
            if isRed {
                return (count: redCount, isRed: true)
            } else {
                return (count: grayCount, isRed: false)
            }
        }
        return (count: 0, isRed: false)
    }

    func getMailAccountListType() -> String {
        guard let typeArray = getCachedAccountList()?.map({ _getMailAccountType(account: $0) }).filter({ !$0.isEmpty }) else {
            return ""
        }
        return typeArray.joined(separator: ",")
    }

    func getMailAccountType() -> String {
        return currentAccType
    }

    func _getMailAccountType(account: MailAccount?) -> String {
        guard let currentAcc = account else {
            return ""
        }
        let userType = currentAcc.mailSetting.userType
        switch userType {
        case .larkServer, .larkServerUnbind, .gmailApiClient, .exchangeApiClient:
            return "lms"
        case .oauthClient, .newUser:
            return "gmailClient"
        case .exchangeClient, .exchangeClientNewUser:
            return "exchangeClient"
        case .tripartiteClient:
            if currentAcc.protocol == .exchange {
                return "eas"
            } else {
                return "imap"
            }
        @unknown default:
            return "unknown"
        }
    }

    /// 更改当前账号的设置
    func updateCurrentSettings(_ settings: MailSettingAction...,
                                onSuccess: (() -> Void)? = nil,
                                onError: ((Error) -> Void)? = nil) {
        getCurrentAccount().subscribe(onNext: { [weak self](account) in
            guard let `self` = self else { return }
            var account = account
            self.updateSettings(settings, of: &account, onSuccess: onSuccess, onError: onError)
        }, onError: { (error) in
            MailLogger.error("mail update current settings error")
        }).disposed(by: disposeBag)
    }

    /// 更新 Setting,  可变参数形式
    func updateSettings(_ settings: MailSettingAction...,
                        of account: inout MailAccount,
                        onSuccess: (() -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        updateSettings(settings, of: &account, onSuccess: onSuccess, onError: onError)
    }

    /// 更新 Setting,  数组参数形式
    // nolint: long_function, cyclomatic complexity -- 包含一个较长的 switch case，不影响代码可读性
    func updateSettings(_ settings: [MailSettingAction],
                        of account: inout MailAccount,
                        onSuccess: (() -> Void)? = nil,
                        onError: ((Error) -> Void)? = nil) {
        var allSettingsLog = ""
        let accountId = account.mailAccountID
        var hasChangeStranger: Bool = false
        var newSettings = MailSetting() /// 仅传递有改变的设置值，实现增量更新
        settings.forEach { (update) in
            var tempLog = ""
            switch update {
            case .newMailNotification(let enable):
                account.mailSetting.newMailNotification = enable
                newSettings.newMailNotification = enable
                tempLog = "new mail notification enable: \(enable)"
            case .allNewMailNotificationSwitch(let enable):
                account.mailSetting.allNewMailNotificationSwitch = enable
                newSettings.allNewMailNotificationSwitch = enable
                tempLog = "all new mail notification switch enable: \(enable)"
            case .newMailNotificationChannel(let channel, let enable):
                let newChannel = changeChannel(oldChannel: account.mailSetting.newMailNotificationChannel,
                                               channel: channel, enable: enable)
                account.mailSetting.newMailNotificationChannel = newChannel
                newSettings.newMailNotificationChannel = newChannel
                tempLog = "new mail notification Channel: \(channel.rawValue)"
            case .newMailNotificationScope(let scope):
                account.mailSetting.notificationScope = scope
                newSettings.notificationScope = scope
                tempLog = "new mail notification scope: \(scope)"
            case .smartInboxMode(let enable):
                account.mailSetting.smartInboxMode = enable
                newSettings.smartInboxMode = enable
                tempLog = "smart inbox enable: \(enable)"
            case .strangerMode(let enable):
                account.mailSetting.enableStranger = enable
                newSettings.enableStranger = enable
                let currentAccIsShared = getCachedCurrentAccount()?.isShared ?? false
                tempLog = "[mail_stranger] stranger enable: \(enable) currentAccIsShared: \(currentAccIsShared)"
                if !enable && !currentAccIsShared { // 当前在公共账号则不发起主动loading逻辑
                    strangerModeChangeInfo = (false, accountId)
                    hasChangeStranger = true
                }
            case .signature(let signature):
                newSettings.signature = account.mailSetting.signature
                switch signature {
                case .enable(let enable):
                    account.mailSetting.signature.enabled = enable
                    newSettings.signature.enabled = enable
                    tempLog = "signature enable: \(enable)"
                case .text(let text):
                    account.mailSetting.signature.text = text
                    newSettings.signature.text = text
                    tempLog = "signature text: \(text.count)"
                case .mobileUsePcSignature(let mobileUsePcSignature):
                    account.mailSetting.mobileUsePcSignature = mobileUsePcSignature
                    newSettings.mobileUsePcSignature = mobileUsePcSignature
                    tempLog = "signature use pc signature: \(mobileUsePcSignature)"
                }
            case .vacationResponder(let vacationResponder):
                newSettings.vacationResponder = account.mailSetting.vacationResponder
                switch vacationResponder {
                case .enable(let enable):
                    account.mailSetting.vacationResponder.enable = enable
                    newSettings.vacationResponder.enable = enable
                    tempLog = "vacation responder enable: \(enable)"
                case .startTimestamp(let startTimestamp):
                    account.mailSetting.vacationResponder.startTimestamp = startTimestamp
                    newSettings.vacationResponder.startTimestamp = startTimestamp
                    tempLog = "vacation responder start time: \(startTimestamp)"
                case .endTimestamp(let endTimestamp):
                    account.mailSetting.vacationResponder.endTimestamp = endTimestamp
                    newSettings.vacationResponder.endTimestamp = endTimestamp
                    tempLog = "vacation responder end time: \(endTimestamp)"
                case .onlySendToTenant(let onlySendToTenant):
                    account.mailSetting.vacationResponder.onlySendToTenant = onlySendToTenant
                    newSettings.vacationResponder.onlySendToTenant = onlySendToTenant
                    tempLog = "vacation responder only send to tenant: \(onlySendToTenant)"
                case .images(let images):
                    account.mailSetting.vacationResponder.images = images
                    newSettings.vacationResponder.images = images
                    tempLog = "vacation responder images - count: \(images.count)"
                case .autoReplyBody(let autoReplyBody):
                    account.mailSetting.vacationResponder.autoReplyBody = autoReplyBody
                    newSettings.vacationResponder.autoReplyBody = autoReplyBody
                    tempLog = "vacation responder auto reply body - length: \(autoReplyBody.count)"
                case .autoReplySummary(let autoReplySummary):
                    account.mailSetting.vacationResponder.autoReplySummary = autoReplySummary
                    newSettings.vacationResponder.autoReplySummary = autoReplySummary
                    tempLog = "vacation responder auto reply summary - length: \(autoReplySummary.count)"
                }
            case .statusSmartInboxOnboarding(let status):
                newSettings.statusSmartInboxOnboarding = account.mailSetting.statusSmartInboxOnboarding
                switch status {
                case .smartInboxAlertRendered(let rendered):
                    account.mailSetting.statusSmartInboxOnboarding.smartInboxAlertRendered = rendered
                    newSettings.statusSmartInboxOnboarding.smartInboxAlertRendered = rendered
                    tempLog = "smart inbox onboarding alert rendered: \(rendered)"
                case .smartInboxPromptRendered(let rendered):
                    account.mailSetting.statusSmartInboxOnboarding.smartInboxPromptRendered = rendered
                    newSettings.statusSmartInboxOnboarding.smartInboxPromptRendered = rendered
                    tempLog = "smart inbox onboarding prompt rendered: \(rendered)"
                }
            case .statusIsMigrationDonePromptRendered(let rendered):
                account.mailSetting.statusIsMigrationDonePromptRendered = rendered
                newSettings.statusIsMigrationDonePromptRendered = rendered
                tempLog = "migration done prompt rendered: \(rendered)"
            case .lastVisitImportantLabelTimestamp(let timestamp):
                account.mailSetting.lastVisitImportantLabelTimestamp = timestamp
                newSettings.lastVisitImportantLabelTimestamp = timestamp
                tempLog = "last vist important label timestamp: \(timestamp)"
            case .lastVisitOtherLabelTimestamp(let timestamp):
                account.mailSetting.lastVisitOtherLabelTimestamp = timestamp
                newSettings.lastVisitOtherLabelTimestamp = timestamp
                tempLog = "last vist other label timestamp: \(timestamp)"
            case .lastVisitStrangerLabelTimestamp(let timestamp):
                account.mailSetting.lastVisitStrangerLabelTimestamp = timestamp
                newSettings.lastVisitStrangerLabelTimestamp = timestamp
                tempLog = "last vist stranger label timestamp: \(timestamp)"
            case .accountRevokeNotifyPopupVisible(let visible):
                account.mailSetting.accountRevokeNotifyPopupVisible = visible
                newSettings.accountRevokeNotifyPopupVisible = visible
                tempLog = "account revoke notify popup visible: \(visible)"
            case .undoSend(let enable, let undoTime):
                account.mailSetting.undoSendEnable = enable
                account.mailSetting.undoTime = undoTime
                newSettings.undoSendEnable = enable
                newSettings.undoTime = undoTime
                tempLog = "account undo send enable: \(enable), time: \(undoTime)"
            case .replyLanguage(let language):
                account.mailSetting.replyLanguage = language
                newSettings.replyLanguage = language
                tempLog = "account replyLanguage: \(language)"
            case .storageLimitNotify(let storageLimit):
                account.mailSetting.storageLimitNotify = storageLimit
                newSettings.storageLimitNotify = storageLimit
                tempLog = "account storageLimitNotify: \(storageLimit.limit) - \(storageLimit.enable)"
            case .showApiOnboarding:
                account.mailSetting.showApiOnboardingPage = false
                newSettings.showApiOnboardingPage = false
                tempLog = "showApiOnboarding false"
            case .conversationMode(let enable):
                account.mailSetting.enableConversationMode = enable
                newSettings.enableConversationMode = enable
                tempLog = "conversationMode enable: \(enable)"
            case .senderAlias(let targetAddress):
                newSettings.emailAlias = account.mailSetting.emailAlias
                newSettings.emailAlias.allAddresses = account.mailSetting.emailAlias.allAddresses.map({
                    return $0.address == targetAddress.address ? targetAddress : $0
                })
                if newSettings.emailAlias.primaryAddress.address == targetAddress.address {
                    newSettings.emailAlias.primaryAddress = targetAddress
                    account.mailSetting.emailAlias.primaryAddress = targetAddress
                }
                if targetAddress.address == account.mailSetting.emailAlias.defaultAddress.address {
                    account.mailSetting.emailAlias.defaultAddress = targetAddress
                    newSettings.emailAlias.defaultAddress = targetAddress
                }
                account.mailSetting.emailAlias.allAddresses = newSettings.emailAlias.allAddresses
                tempLog = "account senderAlias: \(targetAddress.name)"
            case .setDefaultAlias(let address):
                newSettings.emailAlias = account.mailSetting.emailAlias
                account.mailSetting.emailAlias.defaultAddress = address
                newSettings.emailAlias.defaultAddress = address
            case .deleteAlias(let targetAddress):
                newSettings.emailAlias = account.mailSetting.emailAlias
                if targetAddress.address == account.mailSetting.emailAlias.defaultAddress.address {
                    newSettings.emailAlias.defaultAddress = account.mailSetting.emailAlias.primaryAddress
                    account.mailSetting.emailAlias.defaultAddress = newSettings.emailAlias.defaultAddress
                }
                var newAllAddresses: [MailClientAddress] = []
                for clientAddress in account.mailSetting.emailAlias.allAddresses {
                    if clientAddress.address != targetAddress.address {
                        newAllAddresses.append(clientAddress)
                    }
                }
                newSettings.emailAlias.allAddresses = newAllAddresses
                account.mailSetting.emailAlias.allAddresses = newAllAddresses
            case .appendAlias(let targetAddress):
                newSettings.emailAlias = account.mailSetting.emailAlias
                var newAllAddresses = account.mailSetting.emailAlias.allAddresses
                newAllAddresses.append(targetAddress)
                newSettings.emailAlias.allAddresses = newAllAddresses
                account.mailSetting.emailAlias.allAddresses = newAllAddresses
            case .conversationRankMode(let atBottom):
                account.mailSetting.mobileMessageDisplayRankMode = atBottom
                newSettings.mobileMessageDisplayRankMode = atBottom
                tempLog = "mobileMessageDisplayRankMode atBottom: \(atBottom)"
            case .swipeAction(let slideAction):
                account.mailSetting.slideAction = slideAction
                newSettings.slideAction = slideAction
                tempLog = "swipeAction slideAction: \(slideAction)"
            case .webImageDisplay(let enable):
                account.mailSetting.webImageDisplay = enable
                newSettings.webImageDisplay = enable
                tempLog = "webImageDisplay enable: \(enable)"
            case .autoCC(let enable, let type):
                account.mailSetting.autoCcAction.autoCcEnable = enable
                account.mailSetting.autoCcAction.autoCcType = type
                newSettings.autoCcAction.autoCcEnable = enable
                newSettings.autoCcAction.autoCcType = type
                tempLog = "autoCC enable:\(enable), type:\(type)"
            case .attachmentLocation(let location):
                account.mailSetting.attachmentLocation = location
                newSettings.attachmentLocation = location
                tempLog = "attachmentLocation location: \(location)"
            }

            MailLogger.info("mail update account: " + accountId + " settings: - " + tempLog)
            allSettingsLog = allSettingsLog + tempLog + " | "
        }

        /// 这里考虑到后端性能，只传递当前账号的，因此裁剪掉 sharedAccounts 数据
        var newAccount = account
        newAccount.sharedAccounts = []
        let tempAccount = newAccount
        if currentUserContext?.featureManager.open(.settingUpdate, openInMailClient: true) == true {
            /// 仅传递有改变的设置值，实现增量更新
            /// newAccount 只包含了有改变的设置值，其他设置值不可信、不可用
            /// tempAccount 记录了所有的设置值，可以用来乐观更新
            newAccount.mailSetting = newSettings
            newAccount.mailSetting.userType = account.mailSetting.userType // 需要把 userType 写回去
        }
        // 陌生人开关属于公共设置项，但不能应用到公共邮箱，端上做一次拦截
        if newAccount.isShared {
            newAccount.mailSetting.enableStranger = false
        }
        updateAccount(account: newAccount).subscribe(onNext: { [weak self] in
            onSuccess?()
            MailLogger.info("[mail_stranger] mail update account: " + accountId + " setting success")
            if var accList = self?.getCachedAccountList() {
                for (idx, acc) in accList.enumerated() where acc.mailAccountID == accountId {
                    accList[idx] = tempAccount
                }
                self?.accountList.value = accList
            }
            if accountId == self?.getCachedCurrentAccount()?.mailAccountID {
                self?.currentAccount.value = tempAccount
                NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED, object: nil)
            }
        }, onError: { [weak self] (error) in
            onError?(error)
            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_UPDATE_RESP, object: nil)
            MailLogger.error("[mail_stranger] mail update account: " + accountId + " setting error: - " + allSettingsLog)
            if hasChangeStranger {
                self?.strangerModeChangeInfo = nil
            }
        }).disposed(by: disposeBag)
    }

    public func updateAccountUnread(by unreadMap: [String: Int64]) {
        if var accountInfos = self.accountInfos.value {
            for (key, value) in unreadMap {
                if let index = accountInfos.firstIndex(where: { $0.accountId == key }) {
                    accountInfos[index].unread = value
                }
            }
            self.accountInfos.value = accountInfos
        }
        self.$accountInfoChanges.accept(())
    }

    private func updateAccount(account: MailAccount) -> Observable<Void> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.updateMailAccount(account)
    }

    func setAccountInfos(of accountInfos: [MailAccountInfo]) {
        self.accountInfos.value = accountInfos
    }

    func updateAccountInfos(of primaryAccount: MailAccount) {
        guard primaryAccount.isValid() else {
            MailLogger.error("[mail_account] primaryAccount is inValid, no need to updateAccountInfos")
            return
        }
        var unreadMap: [String: Int64] = [:]
        accountInfos.value?.forEach({ (info) in
            unreadMap[info.accountId] = info.unread
        })
        
        let migrateMap = migrateStatMap.value
        /// 1. update account info with cached unread count and migrate state
        self.accountInfos.value = MailSettingManager.getAccountInfos(of: primaryAccount, unreadMap: unreadMap, migrateMap: migrateMap)

        /// 2. then get newest unread count
        fetcher?.getAllAccountUnreadCount().subscribe(onNext: { [weak self](resp) in
            guard let `self` = self else { return }
            self.updateAccountUnread(by: resp.unreadCountMap)
        }).disposed(by: disposeBag)
    }
    
    func updateImapMigrateStates(stateMap: [Int64: Email_Client_V1_IMAPMigrationState]) {
        var map = [String: Bool]()
        for (key, value) in stateMap {
            if value.status == .init_ && String(key) != primaryAccount.value?.mailAccountID {
                map[String(key)] = true
            }
        }
        if var accountInfos = self.accountInfos.value {
            for (index, value) in accountInfos.enumerated() {
                accountInfos[index].isMigrating = map[value.accountId] ?? false
            }
            self.accountInfos.value = accountInfos
        }
        migrateStatMap.value = map
        self.$accountInfoChanges.accept(())
    }

    // MARK: - 工具方法
    static func getAccountInfos(of primaryAccount: MailAccount, unreadMap: [String: Int64]?, migrateMap: [String: Bool]) -> [MailAccountInfo] {
        let isMigrating = migrateMap[primaryAccount.mailAccountID] ?? false
        var accountInfos: [MailAccountInfo] = [getInfo(of: primaryAccount,
                                                       isMigrating: isMigrating,
                                                       primaryAccount: primaryAccount,
                                                       unread: unreadMap?[primaryAccount.mailAccountID])]
        if !primaryAccount.sharedAccounts.isEmpty {
            accountInfos.append(contentsOf: primaryAccount.sharedAccounts.map { getInfo(of: $0,
                                                                                        isMigrating: migrateMap[$0.mailAccountID] ?? false,
                                                                                        primaryAccount: primaryAccount,
                                                                                        unread: unreadMap?[$0.mailAccountID]) })
        }
        return accountInfos
    }

    static func getInfo(of account: MailAccount, isMigrating: Bool, primaryAccount: MailAccount, unread: Int64? = nil) -> MailAccountInfo {
        return MailAccountInfo(accountId: account.mailAccountID,
                               address: account.accountAddress,
                               isOAuthAccount: account.mailSetting.userType != .larkServer && account.mailSetting.userType != .exchangeClient && account.mailSetting.userType != .exchangeApiClient && account.mailSetting.userType != .gmailApiClient,
                               status: account.mailSetting.emailClientConfigs.first?.configStatus,
                               isShared: account.isShared,
                               isSelected: account.accountSelected.isSelected,
                               unread: unread ?? 0,
                               notification: primaryAccount.mailSetting.allNewMailNotificationSwitch ? account.mailSetting.newMailNotification : false,
                               userType: account.mailSetting.userType,
                               isMigrating: isMigrating)
    }

    func changeChannel(oldChannel: Int32, channel: MailChannelPosition, enable: Bool) -> Int32 {
        var newChannel = String(oldChannel, radix:2).comple()
        switch channel {
        case .push:
            let pushIndex = newChannel.index(newChannel.startIndex, offsetBy: 1)
            newChannel.replaceSubrange(pushIndex...pushIndex, with: enable ? "1" : "0")
        case .bot:
            let botIndex = newChannel.index(newChannel.startIndex, offsetBy: 0)
            newChannel.replaceSubrange(botIndex...botIndex, with: enable ? "1" : "0")
        @unknown default:
            break
        }
        return Int32(binary2dec(newChannel))
    }

    func binary2dec(_ num: String) -> Int {
        var sum = 0
        for c in num {
            sum = sum * 2 + (Int("\(c)") ?? 0)
        }
        return sum
    }
}

extension String {
    func comple() -> String {
        if self.count < 2 {
            return "0\(self)"
        }
        return self
    }
}

// MARK: - MailSetting
extension MailSettingManager {
    func switchMailAccount(to accountId: String) -> Observable<Email_Client_V1_MailSwitchAccountResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        MailLogger.info("[mail_init] [mail_client] switchMailAccount to \(accountId)")
        return fetcher.switchMailAccount(to: accountId)
    }

    func getPrimaryAccount(fetchDb: Bool = true) -> Observable<Email_Client_V1_MailGetAccountResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        MailLogger.info("[mail_client] getPrimaryAccount fetchDb: \(fetchDb)")
        return fetcher.getPrimaryAccount(fetchDb: fetchDb)
    }
}

extension MailSettingManager {
    func mailClientExpiredCheck(
        accountContext: MailAccountContext,
        from: EENavigator.NavigatorFrom,
        commonHandler: (() -> Void)? = nil
    ) {
        guard mailClient else {
            commonHandler?()
            return
        }
        MailLogger.info("[mail_client_debug] mailClientExpiredCheck curAcc: \(getCachedCurrentAccount()?.mailAccountID)")
        guard let currentAcc = accountContext.mailAccount else {
            commonHandler?()
            return
        }
        let mailAccountID = currentAcc.mailAccountID
        if let status = getAccountInfos().first(where: { $0.accountId == mailAccountID })?.status, status == .expired {
            let alert = LarkAlertController()
            var content = BundleI18n.MailSDK.Mail_ThirdClient_AccountExpiredDescMobile(currentAcc.mailSetting.emailAlias.defaultAddress.address)
            var confirmText = BundleI18n.MailSDK.Mail_ThirdClient_VerifiedAgain
            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_AccountExpired)
            alert.setContent(text: content, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: confirmText, numberOfLines: 2, dismissCompletion: { [weak self] in
                if currentAcc.provider.isTokenLogin() {
                    self?.tokenRelink(provider: currentAcc.provider, navigator: accountContext.navigator, from: from, accountID: mailAccountID, address: currentAcc.mailSetting.emailAlias.defaultAddress.address)
                } else {
                    /// 到高级设置
                    let adSettingVC = MailClientAdvanceSettingViewController(scene: .reVerfiy, accountID: mailAccountID, accountContext: accountContext, isFreeBind: FeatureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false))
                    let adSettingNav = LkNavigationController(rootViewController: adSettingVC)
                    adSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                    accountContext.navigator.present(adSettingNav, from: from)
                }
            })
            accountContext.navigator.present(alert, from: from)
        } else {
            commonHandler?()
        }
    }
    
    func tokenRelink(
        provider: MailTripartiteProvider?,
        navigator: Navigatable,
        from: NavigatorFrom,
        accountID: String = "",
        address: String = "",
        protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum? = nil,
        completionHandler: (() -> Void)? = nil
    ) {
        MailLogger.info("[mail_client_token] getOauthUrl provider: \(provider) accountID: \(accountID)")
        var accID: String?
        if !accountID.isEmpty {
            accID = accountID
        }
        Store.fetcher?.getOauthUrl(provider: provider, protocolConfig: protocolConfig, address: address, accountID: accID)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_token] getOauthUrl success! state: \(response.state)")
                Store.settingData.updateOauthState(state: response.state, info: MailClientAccountInfo(accountID: accountID, provider: response.provider, address: address, protocolConfig: protocolConfig ?? .imap))
                if let url = URL(string: response.authURL) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                        completionHandler?()
                    })
                } else {
                    MailLogger.error("[mail_client_token] openOauthUrl fail")
                }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.error("[mail_client_token] getOauthUrl fail", error: error)
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_LoginFailed)
            alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PleaseLogIntoAgain, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_MicroSoftLogIn, numberOfLines: 2, dismissCompletion: {
                Store.settingData.tokenRelink(provider: provider, navigator: navigator, from: from)
            })
            navigator.present(alert, from: from)
            completionHandler?()
        }).disposed(by: self.disposeBag)
    }

    func storageLimitCheck(from: EENavigator.NavigatorFrom, navigator: Navigatable, commonHandler: (() -> Void)? = nil) {
        getCurrentSetting()
        .subscribe(onNext: { (resp) in
            // 已满
            let storageLimit = 100
            guard resp.storageLimitNotify.enable && resp.storageLimitNotify.limit >= storageLimit else {
                commonHandler?()
                return
            }
            let alert = LarkAlertController()
            var content = ""
            var confirmText = ""
            if resp.storageLimitNotify.isAdmin {
                content = BundleI18n.MailSDK.Mail_Billing_StorageIsFullPleaseUpgradeThePlan
                confirmText = BundleI18n.MailSDK.Mail_Billing_ContactServiceConsultant
            } else {
                content = BundleI18n.MailSDK.Mail_Billing_PleaseContactTheAdministrator
                confirmText = BundleI18n.MailSDK.Mail_Billing_Confirm
            }
            alert.setTitle(text: BundleI18n.MailSDK.Mail_Billing_ServiceSuspension)
            alert.setContent(text: content, alignment: .center)
            alert.addPrimaryButton(text: confirmText, numberOfLines: 2, dismissCompletion: {
                guard resp.storageLimitNotify.isAdmin else { return }
                MailStorageLimitHelper.contactServiceConsultant(from: from, navigator: navigator)
            })
            if resp.storageLimitNotify.isAdmin {
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Billing_Later, newLine: true)
            }
            navigator.present(alert, from: from)
        }).disposed(by: self.disposeBag)
    }

    func threadDisplayType() -> String {
        return currentAccount.value?.mailSetting.enableConversationMode ?? true ? "conversational" : "traditional"
    }
}

extension MailAccount {
    func isValid() -> Bool {
        return !self.mailAccountID.isEmpty
    }

    func isUnuse() -> Bool {
        let status = self.mailSetting.emailClientConfigs.first?.configStatus
        let userType = self.mailSetting.userType
        return userType == .noPrimaryAddressUser || userType == .newUser || userType == .exchangeClientNewUser
        || status == .deleted || self.mailSetting.emailAlias.defaultAddress.address.isEmpty
    }

    var isFreeBindUser: Bool {
        guard let mailType = mailSetting.emailClientConfigs.first?.mailType else {
            return false
        }
        return mailSetting.userType == .oauthClient && (mailType == .imap || mailType == .exchange || mailType == .gmail)
    }
}
