//
//  ECOInfraDependencyAssembly.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/2/26.
//

import Foundation
import Swinject
import ECOInfra
import EEMicroAppSDK
import LarkFeatureGating
import LarkSDKInterface
import ECOProbe
import LarkAccountInterface
import LarkFoundation
import TTMicroApp
import LKCommonsLogging
import LarkContainer
import LarkAssembler
import OPFoundation

final class ECOInfraDependencyAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Container) {
        let userGraph = container.inObjectScope(OPUserScope.userGraph)
        userGraph.register(ECOConfigDependency.self) { _ in
            return ECOConfigDependencyImpl()
        }
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

final class ECOFoundationDependencyImpl: ECOFoundationDependency {
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

final class ECOConfigDependencyImpl: ECOConfigDependency {
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
        return LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }

    func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void) {
        completion(LarkFeatureGating.shared.getFeatureBoolValue(for: key))
    }

    func getStaticFeatureGatingBoolValue(for key: String) -> Bool {
        return LarkFeatureGating.shared.getStaticBoolValue(for: key)
    }
}

final class ECOCookieDependencyImpl: ECOCookieDependency {
    @discardableResult
    func setGadgetId(_ gadgetId: GadgetCookieIdentifier, for monitor: OPMonitor) -> OPMonitor {
        if let uniqueId = gadgetId as? OPAppUniqueID {
            return monitor.setUniqueID(uniqueId)
        } else {
            return monitor
        }
    }
}

final class ECONetworkDependencyImpl: ECONetworkDependency {

    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func deviceID() -> String {
        guard let service = resolver.resolve(DeviceService.self) else {
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
