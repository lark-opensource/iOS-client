//
//  ECOInfraDependencyAssembly.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/2/26.
//

#if canImport(LarkOpenPlatform)
import Foundation
import Swinject
import ECOInfra
import EEMicroAppSDK
import LarkSetting
import LarkSDKInterface
import ECOProbe
import LarkAccountInterface
import LarkFoundation
import TTMicroApp
import LKCommonsLogging
import LarkContainer
import LarkAssembler
import OPFoundation
import SpaceInterface

final class DemoOpenPlatformAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Container) {
        let user = container.inObjectScope(OPUserScope.userGraph)
        user.register(ECOConfigDependency.self) { _ in
            return ECOConfigDependencyImpl()
        }
        user.register(OPProbeConfigDependency.self) { resolver in
            return OPProbeConfigDependencyImpl(resolver: resolver)
        }
        #if !canImport(CCMMod)
        user.register(SKEditorDocsViewCreateInterface.self) { _ in
            return DemoSKEditorDocsViewImpl()
        }
        #endif
        container.register(ECOFoundationDependency.self) { _ in
            return ECOFoundationDependencyImpl()
        }.inObjectScope(.container)
        container.register(ECOCookieDependency.self) { _ in
            return ECOCookieDependencyImpl()
        }.inObjectScope(.container)
        container.register(ECONetworkDependency.self) { resolver in
            return ECONetworkDependencyImpl(resolver: resolver)
        }.inObjectScope(.container)
    }
}

private final class ECOFoundationDependencyImpl: ECOFoundationDependency {
    func _BDPLog(
        level: BDPLogLevel,
        tag: String?,
        tracing: String?,
        fileName: String?,
        funcName: String?,
        line: Int32,
        content: String?
    ) {
        OPFoundation._BDPLog(level, tag, tracing, fileName, funcName, line, content)
    }
}

private final class ECOConfigDependencyImpl: ECOConfigDependency {
    static let logger = Logger.log(ECOConfigDependency.self)

    var urlSession: URLSession {
        return EMANetworkManager.shared().urlSession
    }

    var needStableJsDebug: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigIDUseStableJSSDK)?.boolValue ?? false
    }

    var noCompressDebug: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigIDDoNotCompressJS)?.boolValue ?? false
    }

    var configDomain: String {
        return EMAAppEngine.current()?.config?.domainConfig.configDomain ?? ""
    }

    func requestConfigParams() -> [String: Any] {
        let currentAccount = AccountServiceAdapter.shared
        return ["userId": currentAccount.currentChatterId, "larkVersion": LarkFoundation.Utils.appVersion]
    }

    func getFeatureGatingBoolValue(for key: String, defaultValue: Bool) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key))
    }

    func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void) {
        completion(FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key)))
    }

    func getStaticFeatureGatingBoolValue(for key: String) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: key))
    }
}

private final class ECOCookieDependencyImpl: ECOCookieDependency {
    @discardableResult
    func setGadgetId(_ gadgetId: GadgetCookieIdentifier, for monitor: OPMonitor) -> OPMonitor {
        if let uniqueId = gadgetId as? OPAppUniqueID {
            return monitor.setUniqueID(uniqueId)
        } else {
            return monitor
        }
    }
}

private final class ECONetworkDependencyImpl: ECONetworkDependency {

    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func deviceID() -> String {
        guard let service = try? resolver.resolve(assert: DeviceService.self) else {
            return ""
        }
        return service.deviceId
    }

    func getUserAgentString() -> String {
        return BDPUserAgent.getString()
    }

    func networkMonitorEnable() -> Bool {
        return EMAAppEngine.current()?.onlineConfig?.networkMonitorEnable() ?? false
    }

    func localLibVersionString() -> String {
        return BDPVersionManager.localLibVersionString() ?? ""
    }

    func localLibGreyHash() -> String {
        return BDPVersionManager.localLibGreyHash() ?? ""
    }

    func commonConfiguration() -> ECONetworkCommonConfiguration.Type? {
        return EMANetworkCommonConfiguration.self
    }

    func networkTempDirectory() -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

/// FIXME: OPProbe 需要移除对 EMAAppEngine/EMAFeatureGating 的隐式调用依赖
private final class OPProbeConfigDependencyImpl: NSObject, OPProbeConfigDependency {
    private let resolver: UserResolver
    init(resolver: UserResolver) {
        self.resolver = resolver
        super.init()
    }
    var isAfterLoginStage: Bool = false

    func getFeatureGatingBoolValue(for key: String) -> Bool {
        guard isAfterLoginStage else {
            // 登录成功前始终返回 False，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return false
        }
        return EMAFeatureGating.boolValue(forKey: key)
    }
    func getFeatureGatingBoolValueFastly(for key: String) -> Bool {
        guard isAfterLoginStage, let service = try? resolver.resolve(assert: FeatureGatingService.self) else {
            // 登录成功前始终返回 False，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return false
        }
        return service.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
    }

    func readMinaConfig(for key: String) -> [String: Any] {
        guard isAfterLoginStage else {
            // 登录成功前始终返回空字典，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return [:]
        }
        return EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: key) ?? [:]
    }
    func getRealTimeSetting(for key: String) -> [String: Any]? {
        return ECOConfig.service().getLatestDictionaryValue(for: key)
    }
}

#if !canImport(CCMMod)
private final class DemoSKEditorDocsViewImpl: SKEditorDocsViewCreateInterface {
    func createEditorDocsView(jsEngine: LarkWebView?,
                              uiContainer: UIView,
                              delegate: SKEditorDocsViewRequestProtocol? ,
                              bridgeName: String) -> SKEditorDocsViewObserverProtocol {
        return SKEditorDocsViewObserverImpl()
    }

    private final class SKEditorDocsViewObserverImpl: SKEditorDocsViewObserverProtocol {
        func startObserver() {}
        func removeObserver() {}
    }
}
#endif

#endif
