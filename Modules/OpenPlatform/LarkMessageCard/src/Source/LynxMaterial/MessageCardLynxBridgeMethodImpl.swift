//
//  MessageCardLynxBridgeMethodImpl.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/11/6.
//

import Foundation
import LarkLynxKit
import Lynx
import LarkOpenPluginManager
import ECOProbe
import LarkOpenAPIModel

public struct MessageCardLynxContext {
    public var lynxContext: LynxContext?
    public var bizContext: Any?
    
    public init(lynxContext: LynxContext? = nil, bizContext: Any? = nil) {
        self.lynxContext = lynxContext
        self.bizContext = bizContext
    }
}

public final class MessageCardLynxBridgeMethodImpl: LarkLynxBridgeMethodProtocol {
    private var pluginManager: OpenPluginManager
    
    public init() {
        self.pluginManager = OpenPluginManager(bizDomain: .openPlatform, bizType: .messageCard, bizScene: "")
    }
    
    public func invoke(apiName: String!, params: [AnyHashable : Any]!, lynxContext: LynxContext?, bizContext: LynxContainerContext?, callback: LynxCallbackBlock?) {
        var apiRename = apiName.replacingOccurrences(of: "universal", with: "msg")
        let responseWapper: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void = { (response) in
            switch response {
            case let .failure(error: error):
                let data = try? error.errnoInfo.convertToJsonStr()
                callback?(data ?? "")
            case let .success(data: data):
                let res = try? data?.toJSONDict().convertToJsonStr()
                callback?(res ?? "")
            case .continue(event: _, data: let data):
                let res = try? data?.toJSONDict().convertToJsonStr()
                callback?(res ?? "")
            @unknown default:
                break
            }
        }
        let msgContext = MessageCardLynxContext(lynxContext: lynxContext, bizContext: bizContext?.bizExtra?["bizContext"])
        let additionalInfo: [AnyHashable: Any] = ["msgContext": msgContext]
        let context = OpenAPIContext(trace: OPTrace(traceId: apiRename), dispatcher: pluginManager, additionalInfo: additionalInfo)
        let isSync = isSyncAPI(apiName: apiRename)
        if (isSync) {
            let response = pluginManager.syncCall(apiName: apiRename, params: params, canUseInternalAPI: false, context: context)
            responseWapper(response)
        } else {
            pluginManager.asyncCall(apiName: apiRename, params: params, canUseInternalAPI: false, context: context, callback: responseWapper)
        }
    }
    
    private func isSyncAPI(apiName: String) -> Bool {
        if let isSync = self.pluginManager.defaultPluginConfig[apiName]?.isSync {
            return isSync
        }
        return false
    }
    
}
