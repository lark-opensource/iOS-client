//
//  JSRuntimeTypeUtils.swift
//  OPJSEngine
//
//  Created by qsc on 2023/2/7.
//

import Foundation
import LarkJSEngine
import LarkFeatureGating
import LarkSetting


public extension OPRuntimeType {
    func toLarkJSEngineType() -> LarkJSEngineType? {
        switch self {
        case .jscore, .unknown:
            return .jsCore
        case .vmsdkJscore:
            return .vmsdkJSCore
        case .vmsdkQjs:
            return .vmsdkQuickJS
//        case .oldJsCore:
//            return nil
        @unknown default:
            assertionFailure("convert OPRuntimeType to LarkJSEngineType not all covered!")
            return nil
        }
    }
    
    func isVMSDK() -> Bool {
        switch self {
        case .vmsdkQjs, .vmsdkJscore:
            return true
        case .jscore, .unknown : // .oldJsCore
            return false
        @unknown default:
            assertionFailure("check OPRuntimeType is vmsdk enum not all covered!")
            return false
        }
    }
}

public final class GeneralJSRuntimeTypeFg: NSObject {
    public static let shared = GeneralJSRuntimeTypeFg()
    /// 预加载使用的 runtimeType
    public var runtimeType: OPRuntimeType = .jscore
    
    private lazy var vmsdkEnabled: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with:  "openplatform.worker.vmsdk")
    }()

    private lazy var workerConfig: WorkerRemoteConfig? = {
        return try? SettingManager.shared.setting(with: WorkerRemoteConfig.self)
    }()

    override init() {
        super.init()
        self.setupFg()
    }
    // 启动跑一次
    func setupFg() {
        if let debugRuntimeType = OPJSEngineService.shared.utils?.debugRuntimeType(), debugRuntimeType != OPRuntimeType.unknown {
            runtimeType = debugRuntimeType
            workerConfig = nil // 本地强制指定 worker 情况下，清空远程配置
            return
        }
        
        runtimeType = .jscore

        if(vmsdkEnabled) {
            let config = workerConfig
            if config?.vmsdk?.openToAll ?? false {
                runtimeType = .vmsdkJscore
            }
        }
    }
    
    // 每次进入，供appid级别降级使用
    @objc public class func setupSettings(appID: String) -> OPRuntimeType {
        if GeneralJSRuntimeTypeFg.shared.vmsdkEnabled, let config = GeneralJSRuntimeTypeFg.shared.workerConfig {
            if config.shouldUseVmsdkWorker(for: appID) {
                // 需要使用 vmsdk 的情况下，且全局开启 vmsdk，返回 .unknown 使用预加载的 worker
                return GeneralJSRuntimeTypeFg.shared.runtimeType == .vmsdkJscore ? .unknown : .vmsdkJscore
            } else {
                return GeneralJSRuntimeTypeFg.shared.runtimeType == .jscore ? .unknown : .jscore
            }
        }
        
        if let jscoreApps =  GeneralJSRuntimeTypeFg.shared.workerConfig?.workerType.jscoreWhitelist as? [String], jscoreApps.contains(appID) {
             return .jscore
        }
        
        return .unknown
    }
}
