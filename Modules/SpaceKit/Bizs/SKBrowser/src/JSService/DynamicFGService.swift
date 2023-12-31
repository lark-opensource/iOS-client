//
//  DynamicFGService.swift
//  SpaceKit
//
//  Created by 杨子曦 on 2019/11/20.
//
import SKCommon
import SKFoundation
import SKInfra

public final class MinaConfigChange: BaseJSService {
    static var callbacks: String = ""
}

extension MinaConfigChange: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.minaConfigChange]
    }
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .minaConfigChange :
            guard let callback = params["callback"] as? String else { return }
            MinaConfigChange.callbacks = callback
        default:
            DocsLogger.info(" enter default")
        }
    }
}

class FgConfigChange: BaseJSService {
    static var callbacks: String = ""
    static var featureGatingKeys = [String]()
    private var fgStatus: [String: Bool] = [:]
}

extension FgConfigChange: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.fgConfigChange]
    }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .fgConfigChange :
            guard let callback = params["callback"] as? String, let featureGatingKeys = params["featureGatingKeys"] as? [String] else { return }
            FgConfigChange.callbacks = callback
            FgConfigChange.featureGatingKeys = featureGatingKeys
            _fetchAllFGStatus()
        default:
            DocsLogger.info(" enter default")
        }
    }

    func getLarkFG(for key: String, default: Bool = false) -> Bool {
        return fgStatus[key] ?? `default`
    }

    private func _fetchAllFGStatus() {
        for key in FgConfigChange.featureGatingKeys {
            let res = _getLarkFG(for: key, defaultValue: false)
            fgStatus[key] = res
        }
        model?.jsEngine.callFunction(DocsJSCallBack(FgConfigChange.callbacks), params: fgStatus, completion: nil)
    }

    private func _getLarkFG(for key: String, defaultValue: Bool = false) -> Bool {
        if let debugValue = getValueForDebug(key: key) {
            return defaultValue
        }
        if let value = HostAppBridge.shared.call(GetLarkFeatureGatingService(key: key, isStatic: false, defaultValue: defaultValue)) as? Bool {
            DocsLogger.info("Get FeatureGate value success",
                            extraInfo: ["key": key, "value": value],
                            component: LogComponents.larkFeatureGate)
            return value
        }
        DocsLogger.error("Get FeatureGate value failed, fallback to defaultValue",
                         extraInfo: ["key": key, "defaultValue": defaultValue],
                         component: LogComponents.larkFeatureGate)
        return defaultValue
    }


    // 设置面板，修改fg
    private func getValueForDebug(key: String) -> Bool? {
        if key == "spacekit.mobile.pad_comment_redesign", CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.ipadCommentUseOldDebug) == true {
            return false
        }
        return nil
    }
}
