//
//  UtilKeyValueService.swift
//  SpaceKit
//
//  Created by 段晓琛 on 2019/5/24.
//  通用小型数据接口：前端通过调取 biz.util.setPreference 和 biz.util.getPreference 两个接口来设置/获取 native 的 UserDefaults key-value 值

import Foundation
import SKCommon
import SKFoundation

public let positionkKey = "RECENT_POSITION"

public final class UtilSetKeyValueService: BaseJSService {}

extension UtilSetKeyValueService: DocsJSServiceHandler {

    public var handleServices: [DocsJSService] {
        return [.setKeyValue]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let key = params["key"] as? String else { return }
        guard let val = params["value"] as? String else { return }
        CCMKeyValue.globalUserDefault.set(val, forKey: key)
        if key.contains(positionkKey) {
            DocsLogger.info("setPreference position called")
        }
    }
}




class UtilGetKeyValueService: BaseJSService {}

extension UtilGetKeyValueService: DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        return [.getKeyValue]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let key = params["key"] as? String else { return }
        guard let callback = params["callback"] as? String else { return }
        if let val = CCMKeyValue.globalUserDefault.string(forKey: key) {
            if key.contains(positionkKey) {
                DocsLogger.info("getPreference position called")
            }
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["value": val], completion: nil)
        } else {
            if key.contains(positionkKey) {
                DocsLogger.info("getPreference position called but value is nil")
            }
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: [:], completion: nil)
        }
    }
}
