//
//  OpenBasePlugin+Gadget.swift
//  OPPluginManagerAdapter
//
//  Created by baojianjun on 2022/12/20.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager

// async register with gadgetContext
extension OpenBasePlugin {
    
    public typealias AsyncHandlerGadget<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ params: Param,
        _ context: OpenAPIContext,
        _ gadgetContext: GadgetAPIContext,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void
    
    public typealias AsyncHandlerInstanceGadget<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ this: PluginType,
        _ params: Param,
        _ context: OpenAPIContext,
        _ gadgetContext: GadgetAPIContext,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void
    
    public func registerAsyncHandlerGadget<Param, Result>(
        for apiName: String,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping AsyncHandlerGadget<Param, Result>
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerAsyncHandler(for: apiName, paramsType: paramsType, resultType: resultType) {
            params, context, callback in
            guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                    .setErrno(OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
                return
            }
            try handler(params, context, gadgetContext, callback)
        }
    }
    
    public func registerInstanceAsyncHandlerGadget<PluginType, Param, Result>(
        for apiName: String,
        pluginType: PluginType.Type = PluginType.self,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping AsyncHandlerInstanceGadget<PluginType, Param, Result>
    ) where PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerInstanceAsyncHandler(for: apiName, pluginType: pluginType, paramsType: paramsType, resultType: resultType) {
            this, params, context, callback in
            guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                    .setErrno(OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
                return
            }
            try handler(this, params, context, gadgetContext, callback)
        }
    }
}

// sync register with gadgetContext
extension OpenBasePlugin {
    
    public typealias SyncHandlerGadget<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ params: Param,
        _ context: OpenAPIContext,
        _ gadgetContext: GadgetAPIContext
    ) throws -> OpenAPIBaseResponse<Result>
    
    public typealias SyncHandlerInstanceGadget<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ this: PluginType,
        _ params: Param,
        _ context: OpenAPIContext,
        _ gadgetContext: GadgetAPIContext
    ) throws -> OpenAPIBaseResponse<Result>
    
    public func registerSyncHandlerGadget<Param, Result>(
        for apiName: String,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping SyncHandlerGadget<Param, Result>
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerSyncHandler(for: apiName, paramsType: paramsType, resultType: resultType) { (params, context) -> OpenAPIBaseResponse<Result> in
            guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                    .setErrno(OpenAPICommonErrno.unknown)
                return .failure(error: error)
            }
            return try handler(params, context, gadgetContext)
        }
    }
    
    public func registerInstanceSyncHandlerGadget<PluginType, Param, Result>(
        for apiName: String,
        pluginType: PluginType.Type = PluginType.self,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping SyncHandlerInstanceGadget<PluginType, Param, Result>
    ) where PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerInstanceSyncHandler(for: apiName, pluginType: pluginType, paramsType: paramsType, resultType: resultType) { (this, params, context) -> OpenAPIBaseResponse<Result> in
            guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                    .setErrno(OpenAPICommonErrno.unknown)
                return .failure(error: error)
            }
            return try handler(this, params, context, gadgetContext)
        }
    }
}
