import Foundation
import LarkAccountInterface
import Swinject
import KAEMMService
import LKCommonsLogging
import LarkSetting
import LarkContainer
import LarkOPInterface
import RxSwift
import CryptoSwift
import LarkReleaseConfig

final public class KAEMMCustomLauncherDelegate: LauncherDelegate {
    public var name: String { "KAEMMLauncherDelegate-Custom" }
    static let logger = Logger.log(KAEMMLauncherDelegate.self, category: "Module.LarkCustomKAEMM")
    @InjectedOptional var service: KAEMMServiceProtocol?
    @InjectedLazy private var opLogin: OPApiLogin
    private var disposeBag = DisposeBag()
    private lazy var accountService: AccountService = AccountServiceAdapter.shared
    init(container: Container) {
        Self.logger.info("KAEMMLauncherDelegate start init")
        container.register(KAEMMDependencyProtocol.self) { _ in
            EMMDependency()
        }
        container.register(KAEMMServiceLoggerProtocol.self) { _ in
            EMMLog()
        }
        Self.logger.info("KAEMMLauncherDelegate finish init")
        service?.onAppFinishLaunch()
    }
    public func afterSetAccount(_ account: Account) {
        opLogin.onGadgetEngineReady { [weak self] isReady in
            guard isReady else { return }
            self?.service?.onLogin()
        }
    }
    public func beforeSwitchSetAccount(_ account: Account) {
        service?.onLogout()
    }
    public func afterSwitchSetAccount(_ account: Account) {
        opLogin.onGadgetEngineReady { [weak self] isReady in
            guard isReady else { return }
            self?.service?.onLogin()
        }
    }
    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        service?.onLogout()
    }
}

final private class EMMDependency: KAEMMDependencyProtocol {
    @InjectedLazy private var deviceService: DeviceService
    @InjectedLazy private var opLogin: OPApiLogin
    func getDeviceId() -> String {
        deviceService.deviceId
    }
    func getGroupId() -> String {
        ReleaseConfig.groupId
    }
    func getLoginToken(appId: String, result: @escaping (String) -> Void) {
        opLogin.gadgetLogin(appId) { [weak self] response in
            switch response {
            case .success(let code):
                self?.logger.info(tag: "KAEMM", "getLoginToken success, code: \(code), appId: \(appId)")
                result(code)
            case .failure(let error):
                self?.logger.error(tag: "KAEMM", "getLoginToken failed, appId: \(appId)")
                result("")
            }
        }
        opLogin.offGadgetEngineReady()
    }
    @InjectedLazy var logger: KAEMMServiceLoggerProtocol
    init() {
    }
    func getConfig(space: String, key: String) -> [String: Any] {
        let spaceKey = "\(space)_\(key)"
        let dic = (try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ka_delivery_config"))) ?? [:]
        logger.info(tag: "KAEMM", "settings is: \(dic)")
        guard let config = dic[spaceKey] as? [String: Any] else {
            logger.error(tag: "KAEMM", "delivery_config not find \(spaceKey)'s value")
            return [:]
        }
        logger.info(tag: "KAEMM", "config_type: \(config["config_type"])")
        guard let type = config["config_type"] as? Int else {
            logger.error(tag: "KAEMM", "config_type not find")
            return [:]
        }
        var key = type == 1 ? "general" : AccountServiceAdapter.shared.currentTenant.tenantId
        logger.info(tag: "KAEMM", "config_key: \(key)")
        guard var ret = config[key] as? [String: Any] else {
            logger.error(tag: "KAEMM", "emm config not find \(key)'s value, config: \(config)")
            return [:]
        }
        return ret
    }
    func logoutFeishu() {
        let conf = LogoutConf.default
        conf.trigger = .emm
        AccountServiceAdapter.shared.relogin(conf: conf) { _ in
        } onSuccess: {
        } onInterrupt: {
        }
    }
}
final public class EMMLog: KAEMMServiceLoggerProtocol {
    let logger = Logger.log(KAEMMLauncherDelegate.self, category: "Module.LarkKACustomEMM")
    public func verbose(tag: String, _ msg: String) {
        logger.log(level: .low, msg, tag: tag, additionalData: nil, error: nil)
    }
    public func debug(tag: String, _ msg: String) {
        logger.debug(msg, tag: tag, additionalData: nil, error: nil)
    }
    public func info(tag: String, _ msg: String) {
        logger.info(msg, tag: tag, additionalData: nil, error: nil)
    }
    public func warning(tag: String, _ msg: String) {
        logger.warn(msg, tag: tag, additionalData: nil, error: nil)
    }
    public func error(tag: String, _ msg: String) {
        logger.error(msg, tag: tag, additionalData: nil, error: nil)
    }
}
