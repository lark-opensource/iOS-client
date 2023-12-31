//
//  MailAuthStatusHelper.swift
//  MailSDK
//
//  Created by vvlong on 2021/6/21.
//

import Foundation
import RustPB
import ThreadSafeDataStructure
import RxSwift
import Logger

typealias LarkTabContext = [String: Int]
typealias LarkTabInboxType = Email_Client_V1_Setting.UserType

protocol MailAuthStatusDelegate: AnyObject {
    func updateOauthStatus(viewType: OAuthViewType)
    func showOauthPlaceholderPage(viewType: OAuthViewType, accountInfos: [MailAccountInfo]?)
    func hideOauthPlaceholderPage()
}

class MailAuthStatusHelper {

    static let inboxTypeKey = "inboxType"
    static let isConfigsExpiredKey = "isConfigsExpired" // 是否有账号过期
    static let isConfigsDeletedKey = "isConfigsDeleted" // 是否有账号被删除
    static let showOnboarding = "showOnboarding"

    weak var delegate: MailAuthStatusDelegate?

    private let disposeBag: DisposeBag = DisposeBag()
    internal var getAccountListDisposed = DisposeBag()

    @Atomic([:]) var mailClientCtx: LarkTabContext

//    var oauthPageViewType = OAuthViewType.typeNewUserOnboard
//    var contentFrame: CGRect = .zero
//
//    // MARK: auth page
//    var oauthPlaceholderPage: MailClientImportViewController?

    func refreshAuthPageIfNeeded(_ setting: Email_Client_V1_Setting, vc: MailHomeController) {
        let mailSettingInfo = createLarkMailTabContextFromSetting(setting)
        if needRefreshAuthPage(mailSettingInfo) {
            MailLogger.info("[mailTab] SettingChange push, update Oauth Page")
            mailClientCtx = mailSettingInfo
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.decorateMailTabViewController(vc: vc, showFail: false)
            }
        } else {
            MailLogger.debug("[mailTab] no need to update Oauth Page")
        }
    }

    func decorateMailTabViewController(vc: MailHomeController, showFail: Bool = false) {
        if let primaryAcc = Store.settingData.getCachedPrimaryAccount(), // 出现了tab之后，主账号在搬家，三方权限又被关闭的情况下，展示tab被删的页面
           let currentAcc = Store.settingData.getCachedCurrentAccount() {
            if primaryAcc.mailAccountID == currentAcc.mailAccountID,
               Store.settingData.isInIMAPFlow(primaryAcc), Store.settingData.clientStatus == .saas {
                vc.updateOauthStatus(viewType: .typeOauthDeleted)
                return
            }
        }
        MailLogger.info("[mailTab] decorateMailTabViewController,\(mailClientCtx)")
        if mailClientCtx == [:] {
            if showFail {
                vc.showOauthPlaceholderPage(viewType: .typeLoadingFailed, accountInfos: nil)
            } else {
//                vc.showOauthPlaceholderPage(viewType: .typeLoading)
            }
            return
        } else {
            vc.hideOauthPlaceholderPage()
        }
        guard let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey],
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw),
            inboxType != .larkServer else {
            return
        }

        // auth page
        var viewType: OAuthViewType = .typeNewUserOnboard
        if shouldApiOnboardingWelcomePage {
            viewType = .typeApiOnboard
            vc.updateOauthStatus(viewType: viewType)
        } else if shouldTabShowExchangeNewUserWelcomePage {
            viewType = .typeExchangeOnboard
            vc.updateOauthStatus(viewType: viewType)
        } else if shouldTabShowNewUserWelcomePage {
            viewType = .typeNewUserOnboard
            vc.updateOauthStatus(viewType: viewType)
        } else if shouldTabShowExpiredPage && inboxType == .oauthClient {
            viewType = .typeOauthExpired
            vc.updateOauthStatus(viewType: viewType)
        } else if shouldTabShowDeletedPage && inboxType == .oauthClient {
            viewType = .typeOauthDeleted
            vc.updateOauthStatus(viewType: viewType)
        } else if shouldShowAPIDeletePage {
            viewType = .typeOauthDeleted
            vc.updateOauthStatus(viewType: viewType)
        } else {
            vc.hideOauthPlaceholderPage()
        }
    }

    func authStatus() -> Bool {
        guard let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey],
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw),
            inboxType != .larkServer else {
            return false
        }
        return shouldApiOnboardingWelcomePage || shouldTabShowExchangeNewUserWelcomePage ||
            shouldTabShowNewUserWelcomePage || (shouldTabShowExpiredPage && inboxType == .oauthClient) ||
            (shouldTabShowDeletedPage && inboxType == .oauthClient) || shouldShowAPIDeletePage
    }

    init() {

    }

    func createLarkMailTabContextFromSetting(_ setting: Email_Client_V1_Setting) -> LarkTabContext {
        var mailSettingInfo: LarkTabContext = [:]
        // parse resp
        mailSettingInfo[MailAuthStatusHelper.inboxTypeKey] = setting.userType.rawValue
        mailSettingInfo[MailAuthStatusHelper.showOnboarding] = setting.showApiOnboardingPage ? 1 : 0
        var isExpired = true
        for item in setting.emailClientConfigs where item.configStatus != .expired {
            isExpired = false
            break
        }

        if isExpired &&
            (setting.userType == .oauthClient ||
                setting.userType == .newUser) {
            mailSettingInfo[MailAuthStatusHelper.isConfigsExpiredKey] = 1
        }
        var isDeleted = true
        for item in setting.emailClientConfigs where item.configStatus != .deleted {
            isDeleted = false
            break
        }

        // userType 为oauthClient gmail 绑定态
        // newUser 未绑定态
        if isDeleted &&
            (setting.userType == .oauthClient ||
                setting.userType == .newUser) {
            mailSettingInfo[MailAuthStatusHelper.isConfigsDeletedKey] = 1
        }

        // 未开启三方客户端 且 没有主账号
        // 开启三方客户端 且没有主账号 且 三方服务没有开启
        if (!Store.settingData.mailClient && setting.userType == .noPrimaryAddressUser) ||
            (Store.settingData.mailClient && setting.userType == .noPrimaryAddressUser && !setting.isThirdServiceEnable) {
            mailSettingInfo[MailAuthStatusHelper.isConfigsDeletedKey] = 1
        }

        return mailSettingInfo
    }

    func needRefreshAuthPage(_ mailSettingInfo: LarkTabContext) -> Bool {
        if mailClientCtx == [:] {
            return true
        }
        return mailSettingInfo[MailAuthStatusHelper.inboxTypeKey] != mailClientCtx[MailAuthStatusHelper.inboxTypeKey] ||
            mailSettingInfo[MailAuthStatusHelper.isConfigsExpiredKey] != mailClientCtx[MailAuthStatusHelper.isConfigsExpiredKey] ||
            mailSettingInfo[MailAuthStatusHelper.isConfigsDeletedKey] != mailClientCtx[MailAuthStatusHelper.isConfigsDeletedKey] ||
            mailSettingInfo[MailAuthStatusHelper.showOnboarding] != mailClientCtx[MailAuthStatusHelper.showOnboarding]
    }
}

extension MailAuthStatusHelper {

    var shouldTabShowDeletedPage: Bool {
        guard !mailClientCtx.isEmpty else {
            assert(false, "can not call shouldTabShowDeleetedPage, before mailClientConfig init")
            return false
        }
        if let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey] {
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw)
            if inboxType != .oauthClient {
                return false
            }
        }
        // only hasn't oauth can show go oauth page
        if let deleted = mailClientCtx[MailAuthStatusHelper.isConfigsDeletedKey], deleted == 1 {
            return true
        }
        return false
    }

    var shouldShowAPIDeletePage: Bool {
        guard !mailClientCtx.isEmpty else {
            assert(false, "can not call shouldTabShowDeleetedPage, before mailClientConfig init")
            return false
        }

        if let deleted = mailClientCtx[MailAuthStatusHelper.isConfigsDeletedKey], deleted == 1 {
            return true
        }
        return false
    }

    var shouldTabShowExpiredPage: Bool {
        guard !mailClientCtx.isEmpty else {
            assert(false, "can not call shouldTabShowExpiredPage, before mailClientConfig init")
            return false
        }
        if let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey] {
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw)
            if inboxType != .oauthClient {
                return false
            }
        }
        // only hasn't oauth can show go oauth page
        if let expired = mailClientCtx[MailAuthStatusHelper.isConfigsExpiredKey], expired == 1 {
            return true
        }
        return false
    }

    // usertype为newUser且onboarding fg on，展示newUser欢迎页面
    var shouldTabShowNewUserWelcomePage: Bool {
        guard !mailClientCtx.isEmpty else {
            return false
        }
        guard let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey],
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw),
            inboxType == .newUser else {
            return false
        }
        return true
    }
    // 展示newUser欢迎页面
    var shouldTabShowExchangeNewUserWelcomePage: Bool {
        guard !mailClientCtx.isEmpty else {
            return false
        }
        guard let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey],
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw),
            inboxType == .exchangeClientNewUser else {
            return false
        }
        return true
    }
    // 展示Api onboarding欢迎页面
    var shouldApiOnboardingWelcomePage: Bool {
        guard !mailClientCtx.isEmpty else {
            return false
        }
        guard let inboxTypeRaw = mailClientCtx[MailAuthStatusHelper.inboxTypeKey],
            let inboxType = LarkTabInboxType(rawValue: inboxTypeRaw),
            inboxType == .gmailApiClient || inboxType == .exchangeApiClient else {
            return false
        }
        guard let showOnboarding = mailClientCtx[MailAuthStatusHelper.showOnboarding], showOnboarding == 1 else {
            return false
        }
        return true
    }
}

//extension MailAuthStatusHelper {
//    // MARK: auth page
//    func showOauthPlaceholderPage(viewType: OAuthViewType, accountInfos: [MailAccountInfo]? = nil) {
//        MailLogger.info("show oauth placeholder page \(viewType)")
//        if let page = oauthPlaceholderPage {
//            hideContentController(page)
//        }
//        if viewType == .typeNoOAuthView {
//            hideOauthPlaceholderPage()
//            return
//        }
//        shouldShowOauthPage = true
//        oauthPageViewType = viewType
//
//        createOauthPageIfNeeded()
//        oauthPlaceholderPage?.view.frame = content.view.frame
//        oauthPlaceholderPage?.setupViewType(viewType: viewType)
//        oauthPlaceholderPage?.delegate = self
//
//        if let infos = accountInfos, infos.count > 1 {
//            let badge = Store.settingData.getOtherAccountUnreadBadge()
//            var address = infos.first { $0.isSelected }?.address ?? ""
//            if address.isEmpty {
//                address = BundleI18n.MailSDK.Mail_Mailbox_BusinessEmailDidntLink
//            }
//            self.oauthPlaceholderPage?.showMultiAccount(address: address, showBadge: badge)
//        } else {
//            self.oauthPlaceholderPage?.hideMultiAccount()
//        }
//
//        view.addSubview(oauthPlaceholderPage!.view)
//
//        if viewType == .typeNewUserOnboard {
//            checkIfShowNewUserPopupAlert()
//        }
//    }
//
//    func updateOauthStatus(viewType: OAuthViewType) {
//        asyncRunInMainThread {
//            if viewType == .typeLoading || viewType == .typeLoadingFailed {
//                self.showOauthPlaceholderPage(viewType: viewType)
//                MailLogger.info("mail tab update oauth loading \(viewType)")
//            } else {
//                self.getAccountListDisposed = DisposeBag()
//                /// 这里跟当前账号状态相关
//                Store.settingData.getAccountList()
//                .subscribe(onNext: { [weak self](resp) in
//                    guard let `self` = self else { return }
//                    if let setting = Store.settingData.getCachedCurrentSetting(), setting.userType != .larkServer {
//                        var viewType: OAuthViewType = .typeNoOAuthView
//                        if let status = setting.emailClientConfigs.first?.configStatus {
//                            switch status {
//                            case .deleted:
//                                viewType = .typeOauthDeleted
//                            case .expired:
//                                viewType = .typeOauthExpired
//                            case .notApplicable:
//                                viewType = .typeNewUserOnboard
//                            default:
//                                self.hideOauthPlaceholderPage()
//                                return
//                            }
//                        } else if setting.userType == .newUser {
//                            viewType = .typeNewUserOnboard
//                        } else if setting.userType == .exchangeClientNewUser {
//                            viewType = .typeExchangeOnboard
//                        } else if (setting.userType == .gmailApiClient || setting.userType == .exchangeApiClient) {
//                            if setting.showApiOnboardingPage {
//                                viewType = .typeApiOnboard
//                            } else {
//                                MailLogger.info("api onboard mode, onboarding is false")
//                                self.hideOauthPlaceholderPage()
//                                return
//                            }
//                        } else if setting.userType == .noPrimaryAddressUser {
//                            viewType = .typeOauthDeleted
//                        }
//
//                        MailLogger.info("mail tab update oauth status: \(viewType)")
//                        let accountInfos = Store.settingData.getAccountInfos()
//                        self.showOauthPlaceholderPage(viewType: viewType, accountInfos: accountInfos)
//                    } else {
//                        MailLogger.info("mail tab update oauth hide")
//                        self.hideOauthPlaceholderPage()
//                    }
//                }).disposed(by: self.getAccountListDisposed)
//            }
//        }
//    }
//
//    func hideOauthPlaceholderPage() {
//        shouldShowOauthPage = false
//        oauthPageViewType = .typeNoOAuthView
//        guard let page = oauthPlaceholderPage else {
//            return
//        }
//        hideContentController(page)
//    }
//
//    // MARK: Internal Method
//    func createOauthPageIfNeeded() {
//        if oauthPlaceholderPage == nil {
//            oauthPlaceholderPage = MailClientImportViewController()
//            oauthPlaceholderPage?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        }
//    }
//
//    func checkIfShowNewUserPopupAlert() {
//        guard isViewLoaded else { return }
//        self.checkIfShowNewUserPopupAlert()
//    }
//
//    @objc
//    func mailCurrentAccountChange(_ notification: Notification) {
//        updateOauthStatus(viewType: oauthPageViewType)
//    }
//
//    @objc
//    func mailHideApiOnboardingPage(_ notification: Notification) {
//        self.hideOauthPlaceholderPage()
//    }
//}
@propertyWrapper
struct Atomic<T> {
    private let value: SafeAtomic<T>

    init(_ value: T) {
        self.value = SafeAtomic(value, with: .readWriteLock)
    }

    var wrappedValue: T {
        mutating get {
            value.value
        }
        set {
            self.value.value = newValue
        }
    }
}
