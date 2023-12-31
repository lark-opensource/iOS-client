//
//  Docs.swift
//  Docs
//
//  Created by weidong fu on 31/1/2018.
//

import Foundation
import LarkUIKit
import EENavigator
import RxSwift

public typealias MailSDKDelegate = MailManagerDelegate

public final class MailSDKManager: NSObject {
    struct Keys {
        static let readFeedMessageIDs = "readFeedMessageIDs"
        static let sendVCNavigator = "MailSDK.MailNavigationController"
    }
    let launcher: Launcher
    let userContext: MailUserContext
    private(set) var manager: MailManager!
    weak var tabVC: MailTabBarController?
    var dataService: DataService? {
        return MailDataServiceFactory.commonDataService
    }
    var oauthLoadingVC: MailClientOAuthLoadingViewController?
    ///
    var vcDisposeBag: DisposeBag = DisposeBag()
    var accountDisposeBag: DisposeBag = DisposeBag()
    var commonDisposeBag: DisposeBag = DisposeBag()
    var loadingDisposeBag: DisposeBag = DisposeBag()
    var processingBag: DisposeBag = DisposeBag()
    var authLoadingDisposeBag: DisposeBag = DisposeBag()

    public init(userContext: MailUserContext, config: MailConfig, delegate: MailSDKDelegate) {
        self.userContext = userContext
        self.launcher = Launcher()
        super.init()
        // 在这里初始化 Manager, 注册JS 方法
        launcher.appendTask(LaunchTask(identifier: MailLaunchStatService.LaunchActionType.mailManager.rawValue, kickoff: { [weak self] in
            self?.manager = MailManager(config, userContext: userContext)
            self?.manager.delegate = delegate
        }))

        launcher.appendTask(LaunchTask(identifier: MailLaunchStatService.LaunchActionType.mailNetConfig.rawValue, kickoff: {
            MailNetConfig.configWith(additionHeader: config.infos)
            MailNetConfig.userID = userContext.user.userID
            MailNetConfig.authDelegate = delegate
        }))

        launcher.appendAsyncTask(LaunchTask(identifier: "offlineResource", kickoff: { [weak self] in
            // MailSDK的init流程影响整个mail的启动速度, 如果非关键业务相关, 请优先考虑放在asyncSetup中
            self?.asyncSetup()
        }))

        launcher.kickoff()
        // InjectionIII 动态注入工具，用于调试UI
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
    }

    func asyncSetup() {
        saveConfig()
    }

    private func saveConfig() {
        if let deviceId = self.manager.mailConfig.deviceID {
            let kvStore = MailKVStore(space: .global, mSpace: .global)
            kvStore.set(deviceId, forKey: UserDefaultKeys.deviceID)
        }
    }

    public func makeMailTabController() -> MailTabBarController {
        let tabVC = MailTabBarController(userContext: userContext)
        return tabVC
    }

    public func refreshUserProfile() {
        manager.refreshUserProfile()
    }

    public class func registerMailLogger(_ level: MailLogLevel, handler: MailLoggerHandler?, flag: Bool) {
        MailLogger.setLogger(level, handler: handler, flag: flag)
    }

    public class func sdkImage(named: String) -> UIImage {
        return Resources.image(named: named)
    }
}

extension MailSDKManager {
    static var isEnableRustHttp: Bool = {
        return true
    }()
}

public struct MailConfig {
    /// for all user agent and http headers
    public var infos = [String: String]()
//    public var navigationConfig: MailNavigationBar.Config?
    public var userDomain: String!
//    public var userCountry: MailDomainConfig.Country!
    public var deviceID: String?
    public init () {}
}

//MAKR:-
extension MailSDKManager {
    struct ShareInfo {
        var url: String
        var title: String
        var content: String
        var topic: String?
        init(url: String, title: String, content: String) {
            self.url = url
            self.title = title
            self.content = content
        }
    }
}

extension MailSDKManager {
    /// Assert 并上报数据
    public static func assertAndReportFailure(
        _ message: String,
        error: Error? = nil,
        ignoreLog: Bool = false,
        file: StaticString = #fileID,
        line: UInt = #line) {
            mailAssertionFailure(message, error: error, ignoreLog: ignoreLog, file: file, line: line)
        }
}
