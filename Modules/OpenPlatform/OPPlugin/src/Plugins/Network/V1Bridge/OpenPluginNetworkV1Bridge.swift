//
//  OpenPluginNetworkV1Bridge.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/27.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginNetworkV1Bridge: OpenBasePlugin {
    
    enum SyncAPI: String, CaseIterable {
        case createRequestTask
        case createUploadTask
        case createDownloadTask
        
        case createSocketTask
        case operateSocketTask
        
        var mirror: OpenPluginNetworkV1Bridge.SyncAPIHandler {
            switch self {
            case .createRequestTask:
                return OpenPluginNetworkV1Bridge.createRequestTask
            case .createUploadTask:
                return OpenPluginNetworkV1Bridge.createUploadTask
            case .createDownloadTask:
                return OpenPluginNetworkV1Bridge.createDownloadTask
            case .createSocketTask:
                return OpenPluginNetworkV1Bridge.createSocketTask
            case .operateSocketTask:
                return OpenPluginNetworkV1Bridge.operateSocketTask
            }
        }
    }
    
    enum AsyncAPI: String, CaseIterable {
        case operateRequestTask
        case operateUploadTask
        case operateDownloadTask
        
        var mirror: OpenPluginNetworkV1Bridge.AsyncAPIHandler {
            switch self {
            case .operateRequestTask:
                return OpenPluginNetworkV1Bridge.operateRequestTask
            case .operateUploadTask:
                return OpenPluginNetworkV1Bridge.operateUploadTask
            case .operateDownloadTask:
                return OpenPluginNetworkV1Bridge.operateDownloadTask
            }
        }
    }
    
    lazy var networkPlugin: TMAPluginNetwork = { TMAPluginNetwork() }()
    lazy var socketPlugin: TMAPluginWebSocket = { TMAPluginWebSocket() }()
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        guard !OPSDKFeatureGating.apiNetworkV1DispatchFromPMDisable() else {
            return
        }
        SyncAPI.allCases.forEach { registerSync(apiName: $0, handler: $0.mirror) }
        AsyncAPI.allCases.forEach { registerAsync(apiName: $0, handler: $0.mirror) }
    }
}

// MARK: Sync Impl

extension OpenPluginNetworkV1Bridge {
    func createRequestTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        OpenPluginAPIAdapter.syncExportHandlerAdapter(gadgetContext) { callback, engine, controller in
            networkPlugin.createRequestTask(withParam: params.params, callback: callback, engine: engine, controller: controller)
        }
    }
    
    func createUploadTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        OpenPluginAPIAdapter.syncExportHandlerAdapter(gadgetContext) { callback, engine, controller in
            networkPlugin.createUploadTask(withParam: params.params, callback: callback, engine: engine, controller: controller)
        }
    }
    
    func createDownloadTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        OpenPluginAPIAdapter.syncHandlerAdapter(gadgetContext) { callback, pluginContext in
            networkPlugin.createDownloadTask(withParam: params.params, callback: callback, context: pluginContext)
        }
    }
    
    func createSocketTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        OpenPluginAPIAdapter.syncExportHandlerAdapter(gadgetContext) { callback, engine, controller in
            socketPlugin.createSocketTask(withParam: params.params, callback: callback, engine: engine, controller: controller)
        }
    }
    
    func operateSocketTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenPluginAPIAdapterResult> {
        OpenPluginAPIAdapter.syncExportHandlerAdapter(gadgetContext) { callback, engine, controller in
            socketPlugin.operateSocketTask(withParam: params.params, callback: callback, engine: engine, controller: controller)
        }
    }
}

// MARK: Async Impl

extension OpenPluginNetworkV1Bridge {
    
    func operateRequestTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        OpenPluginAPIAdapter.asyncHandlerAdapter(gadgetContext, callback: callback) { callback, pluginContext in
            networkPlugin.operateRequestTask(withParam: params.params, callback: callback, context: pluginContext)
        }
    }
    
    func operateUploadTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        OpenPluginAPIAdapter.asyncHandlerAdapter(gadgetContext, callback: callback) { callback, pluginContext in
            networkPlugin.operateUploadTask(withParam: params.params, callback: callback, context: pluginContext)
        }
    }
    
    func operateDownloadTask(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        OpenPluginAPIAdapter.asyncHandlerAdapter(gadgetContext, callback: callback) { callback, pluginContext in
            networkPlugin.operateDownloadTask(withParam: params.params, callback: callback, context: pluginContext)
        }
    }
}

// MARK: Register

extension OpenPluginNetworkV1Bridge {
    
    typealias SyncAPIHandler = (
        _ this: OpenPluginNetworkV1Bridge
    ) -> OpenBasePlugin.SyncHandlerGadget<OpenPluginAPIAdapterParams, OpenPluginAPIAdapterResult>
    
    typealias AsyncAPIHandler = (
        _ this: OpenPluginNetworkV1Bridge
    ) -> OpenBasePlugin.AsyncHandlerGadget<OpenPluginAPIAdapterParams, OpenPluginAPIAdapterResult>
    
    private func registerSync(apiName: SyncAPI, handler: @escaping SyncAPIHandler) {
        registerInstanceSyncHandlerGadget(for: apiName.rawValue, pluginType: Self.self, paramsType: OpenPluginAPIAdapterParams.self, resultType: OpenPluginAPIAdapterResult.self) { try handler($0)($1, $2, $3) }
    }
    
    private func registerAsync(apiName: AsyncAPI, handler: @escaping AsyncAPIHandler) {
        registerInstanceAsyncHandlerGadget(for: apiName.rawValue, pluginType: Self.self, paramsType: OpenPluginAPIAdapterParams.self, resultType: OpenPluginAPIAdapterResult.self) { try handler($0)($1, $2, $3, $4) }
    }
}
