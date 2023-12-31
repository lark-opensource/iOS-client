//
//  ECOCookieDependencyAssembly.swift
//  EEMicroAppSDK_Example
//
//  Created by Meng on 2021/2/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import ECOInfra
import TTMicroApp
import EEMicroAppSDK
import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkAssembler

class ECOInfraDependencyAssembly: LarkAssemblyInterface {
    func registContainer(container: Swinject.Container) {
        container.register(ECOFoundationDependency.self) { _ in
            return ECOFoundationDependencyImpl()
        }

        container.register(ECOConfigDependency.self) { _ in
            return ECOConfigDependencyImpl()
        }

        container.register(ECOCookieDependency.self) { _ in
            return ECOCookieDependencyImpl()
        }
        
        container.register(ECONetworkDependency.self) { _ in
            return ECONetworkDependencyImpl()
        }

        container.register(ECOSettingsFetchingService.self) { _ in
            return  ECOSettingsFetchingServiceImpl()
        }.inObjectScope(.container)
        container.register(ECOConfigService.self) { r in
            return r.resolve(EMAConfigManager.self)!
        }

        container.register(EMAConfigManager.self) { _ in
            return EMAConfigManager()
        }.inObjectScope(.user)
    }
    func registLarkAppLink(container: Swinject.Container) {
        EMAConfigManager.setSettingsFetchServiceProviderWith({
            return container.resolve(ECOSettingsFetchingService.self)!
        })
        DispatchQueue.main.async {
            EMAConfigManager.registeLegacyKey()
        }
    }

}

class ECOFoundationDependencyImpl: ECOFoundationDependency {
    func _BDPLog(level: BDPLogLevel, tag: String?, tracing: String?, fileName: String?, funcName: String?, line: Int32, content: String?) {
        TTMicroApp._BDPLog(level, tag, tracing, fileName, funcName, line, content)
    }
}

class ECOConfigDependencyImpl: ECOConfigDependency {
    var urlSession: URLSession {
        return EMANetworkManager.shared().urlSession
    }

    var needStableJsDebug: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigIDUseStableJSSDK)?.boolValue ?? false
    }

    var noCompressDebug: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigIDDoNotCompressJS)?.boolValue ?? false
    }

    var userId: String {
        return EERoute.shared().userID ?? ""
    }
    
    var configDomain: String {
        return EMAAppEngine.current()?.config?.domainConfig.configDomain ?? ""
    }

    func requestConfigParams() -> [String: Any] {
        return ["userId": "", "larkVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""]
    }

    //接入飞书统一FG
    func getFeatureGatingBoolValue(for key: String, defaultValue: Bool) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
    func checkFeatureGating(for key: String, completion: @escaping (Bool) -> Void) {
        completion(FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)))
    }
    func getStaticFeatureGatingBoolValue(for key: String) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
}

class ECOCookieDependencyImpl: ECOCookieDependency {
    var userId: String {
        return EERoute.shared().userID ?? ""
    }

    var requestCookieURLWhiteListForWebview: [String] {
        return []
    }

    @discardableResult
    func setGadgetId(_ gadgetId: GadgetCookieIdentifier, for monitor: OPMonitor) -> OPMonitor {
        if let uniqueId = gadgetId as? OPAppUniqueID {
            return monitor.setUniqueID(uniqueId)
        } else {
            return monitor
        }
    }
}

class ECONetworkDependencyImpl: ECONetworkDependency {

    func deviceID() -> String {
        guard let userPlugin = BDPTimorClient.shared().userPlugin.sharedPlugin() as? BDPUserPluginDelegate, let deviceId = userPlugin.bdp_deviceId() else {
            return ""
        }
        return deviceId
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

class ECOSettingsFetchingServiceImpl: ECOSettingsFetchingService {
    static let logger = Logger.log(ECOSettingsFetchingService.self, category: "ECOSettingsFetchingService")

    @Provider private var client: RustService
    private let disposeBag = DisposeBag()

    func fetchSettingsConfig(withKeys keys: [String], completion compleletion: @escaping EMASettingsFetchCompletion) {
        Self.logger.info("start fetch settings config", additionalData: ["keys": "\(keys)"])
        let monitor = OPMonitor(EPMClientOpenPlatformCommonConfigCode.fetch_settings_config_result).timing()
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = keys
        client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).do(onNext: { (dict) in
            monitor
                .setResultTypeSuccess()
                .addCategoryValue("key_count", dict.count)
                .timing()
                .flush()
            compleletion(dict, true)
        }, onError: { (error) in
            monitor
                .setResultTypeFail()
                .setError(error)
                .timing()
                .flush()
            compleletion([:], false)
        })
        .subscribe()
        .disposed(by: disposeBag)
    }
}
