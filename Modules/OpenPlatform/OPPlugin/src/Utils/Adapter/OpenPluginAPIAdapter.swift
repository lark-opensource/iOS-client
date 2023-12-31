//
//  OpenPluginAPIAdapter.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter


// MARK: Adapter

final class OpenPluginAPIAdapter {
    // BDP_EXPORT_HANDLER
    static func syncExportHandlerAdapter(
        _ gadgetContext: GadgetAPIContext,
        _ pluginCallBlock: (@escaping BDPJSBridgeCallback, BDPJSBridgeEngine, UIViewController?) -> Void)
    -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        var status: BDPJSBridgeCallBackType?
        var response: [AnyHashable: Any]?
        let callback: BDPJSBridgeCallback = { callbackType, data in
            status = callbackType
            response = data
        }
        gadgetContext.exportHandlerCallback(pluginCallBlock: pluginCallBlock, callback: callback)
        return .postProcess(status, response)
    }
    
    // BDP_HANDLER
    static func syncHandlerAdapter(
        _ gadgetContext: GadgetAPIContext,
        _ pluginCallBlock: (@escaping BDPJSBridgeCallback, BDPPluginContext) -> Void)
    -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        
        var status: BDPJSBridgeCallBackType?
        var response: [AnyHashable: Any]?
        let callback: BDPJSBridgeCallback = { callbackType, data in
            status = callbackType
            response = data
        }
        gadgetContext.handlerCallback(pluginCallBlock: pluginCallBlock, callback: callback)
        return .postProcess(status, response)
    }
    
    // BDP_HANDLER
    static func asyncHandlerAdapter(
        _ gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void,
        pluginCallBlock: (@escaping BDPJSBridgeCallback, BDPPluginContext) -> Void)
    {
        gadgetContext.handlerCallback(pluginCallBlock: pluginCallBlock) { callbackType, data in
            callback(.postProcess(callbackType, data))
        }
    }
}

extension OpenAPIBaseResponse where Result == OpenPluginAPIAdapterResult {
    static func postProcess(_ status: BDPJSBridgeCallBackType?, _ response: [AnyHashable: Any]?) -> OpenAPIBaseResponse<Result> {
        let status = status ?? .failed
        if case .success = status {
            return .success(data: .init(result: response ?? [:]))
        }
        // outerMessage 对应 BDPErrorMessageForStatus()方法内，status的枚举情况
        let outerMessage = BDPErrorMessageForStatus(status) ?? ""
        let error = OpenAPIError(code: status.code)
            .setOuterMessage(outerMessage)
            .setAddtionalInfo(response ?? [:])
        return .failure(error: error)
    }
}

// 和 OpenAPIError.status相反
extension BDPJSBridgeCallBackType {
    var code: OpenAPICommonErrorCode {
        switch self {
        case .noHandler:
            return .unable
        case .noSystemPermission:
            return .systemAuthDeny
        case .noUserPermission:
            return .userAuthDeny
        case .paramError:
            return .invalidParam
        default:
            return .internalError
        }
    }
}
