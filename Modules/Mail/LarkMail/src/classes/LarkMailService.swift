//
//  LarkMailService.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/28.
//

import Foundation
import RxSwift
import LarkModel
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import EENavigator
import LarkRustClient
import LarkAppResources
import MailSDK
import LarkContainer
import LarkNavigation
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkMailInterface
#if MessengerMod
import LarkMessengerInterface
#endif
import SpaceInterface

// MARK: -
protocol LarkMailServiceDependency {
    var token: String? { get }
    var deviceID: String? { get }
    var rustService: RustService? { get }
    var userDomain: String { get }
    var userIsOverSea: Bool { get }
    var userAppConfig: UserAppConfig? { get }
    var userUniversalSettingService: UserUniversalSettingService? { get }
    var globalWaterMarkOn: Observable<Bool> { get }
    var chatterAPI: ChatterAPI? { get }
    var resourceAPI: ResourceAPI? { get }
    var passportService: PassportUserService? { get }
    var navigationService: NavigationService? { get }
    var currentChatter: Chatter? { get }
    var pushNotificationCenter: PushNotificationCenter? { get }

    func openURL(_ url: URL?, from controller: UIViewController?)
    func showUserProfile(_ userId: String, from controller: UIViewController?)
}

/// Mail-module interface . if other Module need mail service . should user LarkMailService
final class LarkMailService {
    struct RoutePath {
        static let forwardInbox = "/client/mail/forward/inbox"
        static let forwardCard = "/client/mail/forward/card"
        static let approvalMsg = "/client/mail/approval_message"
        static let cardShare = "/client/mail/card/share"
        static let cardDelete = "/client/mail/card/delete"
        static let cardSpam = "/client/mail/card/spam"
        static let setting = "/client/mail/setting"
        static let oauth =  "/client/mail/oauth"
        static let search = "client/mail/comprehensive_search/thread"
        static let deleteMail = "/client/mail/preview/illegal_message"
        static let aiCreateTask = "/client/mail/myai/todo/create"
        static let aiCreateDraft = "/client/mail/myai/draft/create"
        static let aiMarkAllRead = "/client/mail/message/mark_all_as_read"
    }
    static var sharedHasInit: Bool = false
    /// dependency of larkMailService
    let dependency: LarkMailServiceDependency
    /// imp of mailSDK depency
    private(set) var mailSDKAPIImp: MailSDKApiWrapper!
    /// mailSDK
    private(set) public var mail: MailSDKManager!
    /// logger for larkmailservice
    let logger = Logger.log(LarkMailService.self, category: "Module.Mail")
    /// vc factory
    private(set) lazy var factory: MailViewControllerFactory = {
        let temp = MailViewControllerFactory(factory: self.mail)
        temp.delegate = self
        return temp
    }()
    /// emailtab
    private(set) weak var mailTabBarController: MailTabBarController?
    private(set) var mailPushCenter: MailPushCenter?

    /// docsl
    var globalWaterMarkIsShow: Bool = false
    /// disposebag for rxSwift
    let disposeBag = DisposeBag()
    /// disposebag only for app life circle
    var appConfigDisposeBage = DisposeBag()

    let resolver: UserResolver
    let navigator: Navigatable
    let userContext: MailUserContext

    init(dependency: LarkMailServiceDependency, resolver: UserResolver) throws {
        self.dependency = dependency
        self.resolver = resolver
        self.navigator = resolver.navigator
        self.userContext = try resolver.resolve(assert: MailUserContext.self)
        setupConfig(userContext: userContext)
        LarkMailService.sharedHasInit = true
    }

    /// setup component
    private func setupConfig(userContext: MailUserContext) {
        _ = MailPushFilter.shared
        initMailSDK(userContext: userContext) // init mailSDK
        initAPIWrapper() // set up api for mailsdk
        initPushCenter() // init push center
        setupObservers()
    }

    private func initAPIWrapper() {
        MailLaunchStatService.default.markActionStart(type: .initAPIWrapper)
        let wrapper = MailSDKApiWrapper()
        mailSDKAPIImp = wrapper
        updateAPIDependency()
        mail.setMailSDKAPI(wrapper)
        MailLaunchStatService.default.markActionEnd(type: .initAPIWrapper)
    }

    private func setupObservers() {
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_LOADING_VIEW_FAILED)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self]  _ in
            guard let `self` = self else { return }
            self.preloadSettingInServerNavMode()
        }).disposed(by: disposeBag)
    }

    func updateAPIDependency() {
        mailSDKAPIImp.setChatterAPI(dependency.chatterAPI)
        mailSDKAPIImp.setResourceAPI(dependency.resourceAPI)
        mailSDKAPIImp.setUserAppConfig(dependency.userAppConfig)
        mailSDKAPIImp.setUserUniversalSettingService(dependency.userUniversalSettingService)
        mailSDKAPIImp.setPassportService(dependency.passportService)
        mailSDKAPIImp.setCurrentAccount { [weak self] in self?.dependency.currentChatter }
    }

    private func initMailSDK(userContext: MailUserContext) {
        MailLaunchStatService.default.markActionStart(type: .initMailSDK)
        #if DEBUG
        MailSDKManager.registerMailLogger(.debug, handler: self, flag: false)
        #else
        MailSDKManager.registerMailLogger(.info, handler: self, flag: false)
        #endif
        let mailConfig = defaultMailConfig()
        self.mail = MailSDKManager(userContext: userContext, config: mailConfig, delegate: self)
        MailLaunchStatService.default.markActionEnd(type: .initMailSDK)
    }

    private func initPushCenter() {
        /// mail
        updateMailPushCenter()
        /// mail Client MailSDK -> LarkMail
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAuthStatusChange(noti:)),
                                               name: Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED,
                                               object: nil)
    }

    func updateMailPushCenter() {
        guard let pushNotificationCenter = dependency.pushNotificationCenter else { return }
        if let pushCenter = mailPushCenter {
            pushCenter.mailTabBarController = mailTabBarController
            pushCenter.update(pushNotificationCenter)
        } else {
            mailPushCenter = MailPushCenter(pushNotificationCenter)
            mailPushCenter?.mailTabBarController = mailTabBarController
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: config
extension LarkMailService {
    fileprivate func defaultMailConfig() -> MailConfig {
        var mailConfig = MailConfig()
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            mailConfig.infos["Lark"] = appVersion
        }
        mailConfig.deviceID = dependency.deviceID
        mailConfig.userDomain = self.userDomain
        return mailConfig
    }
}

// MARK: - MailSDKDelegate
extension LarkMailService: MailSDKDelegate {
    var userDomain: String? {
        return dependency.userDomain
    }

    var globalWaterMarkIsOn: Bool {
        return self.globalWaterMarkIsShow
    }

    var hasMailTab: Bool {
        let service = dependency.navigationService
        return service?.checkInTabs(for: .mail) == true
    }

    var isInMailTab: Bool {
        if let currentTab = mailTabBarController?.animatedTabBarController?.currentTab, currentTab == .mail {
            return true
        }
        return false
    }

    var rustService: RustService? {
        return dependency.rustService
    }

    func handleAuthenticationChallenge() {
    }


    func requiredNewBearSession(completion: @escaping (String?, Error?) -> Void) {
    }

    func mailRequiredToShowUserProfile(_ userId: String, from controller: UIViewController?) {
        dependency.showUserProfile(userId, from: controller)
    }

    func sendLarkOpenEvent(_ event: LarkOpenEvent) {
        switch event {
        case .openURL(let url, let vc):
            dependency.openURL(url, from: vc)
#if MessengerMod
        case .routeChat(let chatId):
            let body = ChatControllerByIdBody(
                chatId: chatId,
                fromWhere: .ignored,
                showNormalBack: false
            )
            if let fromVC = navigator.mainSceneWindow?.fromViewController {
                navigator.push(body: body, from: fromVC)
            }
#endif
        default:
            break
        }
    }

    // UserInfo 相关信息
    var token: String? {
        return dependency.token
    }

    var userId: String? {
        return dependency.passportService?.user.userID
    }

    var avatarURL: String? {
        return dependency.currentChatter?.avatarThumbFirstUrl
    }

    var name: String? {
        return dependency.currentChatter?.name
    }

    var nameEn: String? {
        return dependency.currentChatter?.enUsName
    }

    var mailAddress: String? {
        return dependency.currentChatter?.email ?? ""
    }

    var departmentName: String? {
        return dependency.currentChatter?.department
    }
    var tenantId: String? {
        return dependency.currentChatter?.tenantId
    }
    var tenantName: String? {
        return dependency.passportService?.userTenant.tenantName
    }
}

// MARK: MailViewControllerFactoryDelegate
extension LarkMailService: MailViewControllerFactoryDelegate {
    func willCreateMailTabController(factory: MailViewControllerFactory) {}

    func didCreateMailTabController(factory: MailViewControllerFactory, tabController: MailTabBarController) {
        mailTabBarController = tabController
        mailPushCenter?.mailTabBarController = mailTabBarController
        userContext.bootManager.handleBeforeInitMail()
        // 如果tab在首屏，由于mail业务延迟加载，需要及时触发mail业务加载，以免等待（loading页）
        (try? resolver.resolve(assert: LarkMailInterface.self))?.notifyMailNaviUpdated(isEnabled: true)
    }
}

// MARK: MailLoggerHandler
extension LarkMailService: MailLoggerHandler {
    func handleMailLogEvent(_ event: MailLogEvent) {
        let logLevel = event.level
        let message = (event.component ?? "") + event.message + logLevel.mark
        let extraInfo = event.extraInfo?.mapValues({ (value) -> String in
            "\(value)"
        })
        let error = event.error
        let fileName = event.fileName
        let funcLine = event.funcLine
        let funcName = event.funcName
        switch logLevel {
        case .debug, .verbose:
            logger.debug(message, additionalData: extraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .info:
            logger.info(message, additionalData: extraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .warning:
            logger.warn(message, additionalData: extraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .error, .severe:
            logger.error(message, additionalData: extraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        }
    }
}
