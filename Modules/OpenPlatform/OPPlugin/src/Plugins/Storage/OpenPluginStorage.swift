//
//  OpenPluginStorage.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/11/30.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOInfra
import OPFoundation
import LarkContainer

final class OpenPluginStorage: OpenBasePlugin {

    // MARK: - setStorage
    func setStorageSync(
        params: OpenPluginSetStorageParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        guard let checker = BDPRouteMediator.sharedManager()?.setStorageLimitCheck else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("checker is nil")
            return .failure(error: error)
        }
        let uniqueID = gadgetContext.uniqueID
        guard let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self),
              let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("sandbox not found")
            return .failure(error: error)
        }
        let sizeInBytes: UInt = UInt(params.data.lengthOfBytes(using: .utf8))
        let sizeInMB: Double = (Double(sizeInBytes) / 1024.0) / 1024.0
        if (sizeInMB - 1.0 > Double.ulpOfOne) {
            let errMsg = "exceed storage item max length"
            let error = OpenAPIError(code: OpenAPISetStorageErrorCode.valueSizeExceedLimit)
                .setErrno(OpenAPISetStorageErrno.storageExceed)
                .setMonitorMessage("sizeInMB: \(sizeInMB)")
            context.apiTrace.error(errMsg, additionalData: ["sizeInMB": "\(sizeInMB)"])
            return .failure(error: error)
        }
        guard let localStorage = sandbox.localStorage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("localStorage is nil")
            return .failure(error: error)
        }
        let storageSieInMB = (Double(localStorage.storageSizeInBytes()) / 1024.0) / 1024.0
        let limitedSizeInMB = (Double(localStorage.limitSize()) / 1024.0) / 1024.0
        let exceed = (storageSieInMB + sizeInMB - limitedSizeInMB > Double.ulpOfOne)
        if (exceed) {
            let monitor = BDPMonitorEvent(
                service: nil,
                name: kEventName_mp_set_storage_size,
                monitorCode: nil
            )
            monitor
                .setUniqueID()(uniqueID)
                .addCategoryValue()("size", (storageSieInMB + sizeInMB))
                .flush();
        }
        // BOOL check = BDPRouteMediator.sharedManager.setStorageLimitCheck && BDPRouteMediator.sharedManager.setStorageLimitCheck();
        var check = false
        check = checker()
        if (check && exceed) {
            let errorMessage = "exceed storage max size 10Mb"
            context.apiTrace.error(errorMessage, additionalData: [
                "check": "\(check)",
                "storageSieInMB": "\(storageSieInMB)",
                "sizeInMB": "\(sizeInMB)",
                "limitedSizeInMB": "\(limitedSizeInMB)"
            ])
            let error = OpenAPIError(code: OpenAPISetStorageErrorCode.totalStorageExceedLimit)
                .setErrno(OpenAPISetStorageErrno.totalStorageExceed)
            return .failure(error: error)
        }
        let value = [
            "data": params.data,
            "dataType": params.dataType
        ]
        if (!localStorage.setObject(value, forKey: params.key)) {
            // 缓存写入失败
            let errMsg = "localStorage setObject failed"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage(errMsg)
            context.apiTrace.error(errMsg, additionalData: [
                "dataLength": "\(BDPSafeString(params.data).count)",
                "key": "\(BDPSafeString(params.key))"])
            return .failure(error: error)
        }
        return .success(data: nil)
    }

    func setStorage(
        params: OpenPluginSetStorageParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let response = setStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        callback(response)
    }


    // MARK: - getStorage
    func getStorageSync(
        params: OpenPluginGetStorageParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext
    ) -> OpenAPIBaseResponse<OpenPluginGetStorageResult> {
        let uniqueID = gadgetContext.uniqueID
        guard let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self),
              let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setErrno(OpenAPICommonErrno.unknown)
                            .setOuterMessage("sandbox not found")
            return .failure(error: error)
        }
        guard let localStorage = sandbox.localStorage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setErrno(OpenAPICommonErrno.unknown)
                            .setMonitorMessage("localStorage is nil")
            return .failure(error: error)
        }
        guard let object = localStorage.object(forKey: params.key) as? [String: Any] else {
            let error = OpenAPIError(code: OpenAPIGetStorageErrorCode.emptyValue)
                .setErrno(OpenAPIGetStorageErrno.keyNotFound(key: params.key))
            return .failure(error: error)
        }
        return .success(data: OpenPluginGetStorageResult(storageDict: object))
    }

    func getStorage(
        params: OpenPluginGetStorageParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetStorageResult>) -> Void
    ) {
        let response = getStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        callback(response)
    }


    // MARK: - removeStorage
    func removeStorageSync(
        params: OpenPluginRemoveStorageRequest,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        let uniqueID = gadgetContext.uniqueID
        guard let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self),
              let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("sandbox not found")
            return .failure(error: error)
        }
        guard let localStorage = sandbox.localStorage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("localStorage is nil")
            return .failure(error: error)
        }
        if (!localStorage.removeObject(forKey: params.key)) {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPIRemoveStorageErrno.unableToRemoveKey(key: params.key))
                .setOuterMessage("localStorage removeObjectForKey failed")
            return .failure(error: error)
        }
        return .success(data: nil)
    }

    func removeStorage(
        params: OpenPluginRemoveStorageRequest,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let response = removeStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        callback(response)
    }


    // MARK: - clearStorage
    func clearStorageSync(
        context: OpenAPIContext, gadgetContext: GadgetAPIContext
    ) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        
        let uniqueID = gadgetContext.uniqueID
        guard let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self),
              let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("sandbox not found")
            return .failure(error: error)
        }
        guard let localStorage = sandbox.localStorage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("localStorage is nil")
            return .failure(error: error)
        }
        if (!localStorage.removeAllObjects()) {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPIClearStorageErrno.clearStorageFail)
                .setOuterMessage("localStorage removeAllObjects failed")
            return .failure(error: error)
        }
        return .success(data: nil)
    }

    func clearStorage(context: OpenAPIContext,
                             gadgetContext: GadgetAPIContext,
                             callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let response = clearStorageSync(context: context, gadgetContext: gadgetContext)
        callback(response)
    }


    // MARK: - getStorageInfo
    func getStorageInfoSync(
        context: OpenAPIContext, gadgetContext: GadgetAPIContext
    ) -> OpenAPIBaseResponse<OpenPluginGetStorageInfoResponse> {
        let uniqueID = gadgetContext.uniqueID
        guard let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self),
              let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("sandbox not found")
            return .failure(error: error)
        }
        guard let localStorage = sandbox.localStorage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("localStorage is nil")
            return .failure(error: error)
        }
        let keys: [String] = localStorage.allKeys() ?? []
        let sizeInKiloByte: Double = Double(localStorage.storageSizeInBytes()) / 1024.0
        let limitSizeInKiloByte: Double = Double(localStorage.limitSize()) / 1024.0
        return .success(data: OpenPluginGetStorageInfoResponse(
            keys: keys,
            currentSize: sizeInKiloByte,
            limitSize: limitSizeInKiloByte)
        )
    }

    func getStorageInfo(
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetStorageInfoResponse>) -> Void
    ) {
        let response = getStorageInfoSync(context: context, gadgetContext: gadgetContext)
        callback(response)
    }


    // MARK: init
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // setStorage
        registerInstanceSyncHandlerGadget(for: "setStorageSync", pluginType: Self.self,
                            paramsType: OpenPluginSetStorageParams.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            return this.setStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "setStorage", pluginType: Self.self,
                             paramsType: OpenPluginSetStorageParams.self) { (this, params, context, gadgetContext, callback) in
            
            this.setStorage(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        // getStorage
        registerInstanceSyncHandlerGadget(for: "getStorageSync", pluginType: Self.self,
                            paramsType: OpenPluginGetStorageParams.self,
                            resultType: OpenPluginGetStorageResult.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenPluginGetStorageResult> in
            
            return this.getStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "getStorage", pluginType: Self.self,
                             paramsType: OpenPluginGetStorageParams.self,
                             resultType: OpenPluginGetStorageResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getStorage(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        // removeStorage
        registerInstanceSyncHandlerGadget(for: "removeStorageSync", pluginType: Self.self,
                            paramsType: OpenPluginRemoveStorageRequest.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            return this.removeStorageSync(params: params, context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "removeStorage", pluginType: Self.self,
                             paramsType: OpenPluginRemoveStorageRequest.self) { (this, params, context, gadgetContext, callback) in
            
            this.removeStorage(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        // clearStorage
        registerInstanceSyncHandlerGadget(for: "clearStorageSync", pluginType: Self.self) { (this, _, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            return this.clearStorageSync(context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "clearStorage", pluginType: Self.self) { (this, _, context, gadgetContext, callback) in
            
            this.clearStorage(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        // getStorageInfo
        registerInstanceSyncHandlerGadget(for: "getStorageInfoSync", pluginType: Self.self,
                            resultType: OpenPluginGetStorageInfoResponse.self) { (this, _, context, gadgetContext) -> OpenAPIBaseResponse<OpenPluginGetStorageInfoResponse> in
            
            return this.getStorageInfoSync(context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "getStorageInfo", pluginType: Self.self,
                             resultType: OpenPluginGetStorageInfoResponse.self) { (this, _, context, gadgetContext, callback) in
            
            this.getStorageInfo(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }

    // MARK: util
    private static func makeRegisterErrMsg(
        apiName: String
    ) -> String {
        return "Plugin: self is nil When call \(apiName) API"
    }

}
