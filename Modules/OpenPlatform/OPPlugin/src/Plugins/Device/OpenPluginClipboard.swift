//
//  OpenPluginClipboard.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import UIKit
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import ECOInfra
import OPPluginManagerAdapter
import LarkContainer
import OPFoundation
import LarkEMM
import LarkSetting

final class OpenPluginClipboard: OpenBasePlugin {
    
    func legacyPreCheck<Result: OpenAPIBaseResult>(
        gadgetContext: GadgetAPIContext,
        callback: (OpenAPIBaseResponse<Result>) -> Void
    ) -> Bool {
        if (Injected<ECOConfigService>().wrappedValue.getBoolValue(for: "preventAccessClipBoardInBackground")) {
            switch gadgetContext.uniqueID.appType {
            case .gadget:
                guard let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID) else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return false
                }
                guard common.isReady, common.isActive else {
                    let error = OpenAPIError(code: OpenAPISetClipboardDataErrorCode.inovkeInBackground)
                        .setErrno(OpenAPIClipboardErrno.invokeInBackground)
                    callback(.failure(error: error))
                    return false
                }
            case .webApp, .block, .widget:
                // 网页应用暂时不提供 「前后台状态」，block 不能调用该 API，widget 与 block 保持一致
                guard UIApplication.shared.applicationState == .active else {
                    let error = OpenAPIError(code: OpenAPISetClipboardDataErrorCode.inovkeInBackground)
                        .setErrno(OpenAPIClipboardErrno.invokeInBackground)
                    callback(.failure(error: error))
                    return false
                }
            case .unknown:
                assertionFailure("unknown application type")
                guard UIApplication.shared.applicationState == .active else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return false
                }
            default:
                assertionFailure("wait to be handled default application type")
                guard UIApplication.shared.applicationState == .active else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return false
                }
            }
        }
        return true
    }

    func setClipboardData(
        params: OpenPluginSetClipboardDataRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: (OpenAPIBaseResponse<OpenPluginSetClipboardDataResponse>) -> Void
    ) {
        guard legacyPreCheck(gadgetContext: gadgetContext, callback: callback) else {
            return
        }
        pr_setClipboardData(params: params, whiteListKey: gadgetContext.uniqueID.appID, callback: callback)
    }
    
    func setClipboardData(
        params: OpenPluginSetClipboardDataRequest,
        context: OpenAPIContext,
        apiExtension: OpenAPIClipboardDataExtension,
        callback: (OpenAPIBaseResponse<OpenPluginSetClipboardDataResponse>) -> Void
    ) {
        if let preCheck = apiExtension.preCheck() {
            context.apiTrace.error("preCheck error: \(preCheck.description)")
            callback(.failure(error: preCheck))
            return
        }
        pr_setClipboardData(params: params, whiteListKey: apiExtension.alertWhiteListKey, callback: callback)
    }
    
    func pr_setClipboardData(
        params: OpenPluginSetClipboardDataRequest,
        whiteListKey: String,
        callback: (OpenAPIBaseResponse<OpenPluginSetClipboardDataResponse>) -> Void
    ) {
        var didAssign = false
        let syncLock = DispatchSemaphore(value: 0)
        let globalQueue = DispatchQueue.global(qos: .default)
        globalQueue.async {
            let token = OPSensitivityEntryToken.openPluginClipboardSetClipboardData
            SCPasteboard.opApiGeneral(token: token, appID: whiteListKey).string = params.data
            didAssign = true
            syncLock.signal()
        }
        _ = syncLock.wait(timeout: (DispatchTime.now() + .seconds(3)))
        
        if didAssign {
            let result = OpenPluginSetClipboardDataResponse(data: params.data)
            callback(.success(data: result))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("set clipboard failed")
                .setAddtionalInfo(["data":""])
            callback(.failure(error: error))
        }
    }

    func getClipboardData(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: (OpenAPIBaseResponse<OpenPluginGetClipboardDataResponse>) -> Void
    ) {
        guard legacyPreCheck(gadgetContext: gadgetContext, callback: callback) else {
            return
        }
        pr_getClipboardData(callback: callback)
    }
    
    func getClipboardData(
        context: OpenAPIContext,
        apiExtension: OpenAPIClipboardDataExtension,
        callback: (OpenAPIBaseResponse<OpenPluginGetClipboardDataResponse>) -> Void
    ) {
        if let preCheck = apiExtension.preCheck() {
            context.apiTrace.error("preCheck error: \(preCheck.description)")
            callback(.failure(error: preCheck))
            return
        }
        pr_getClipboardData(callback: callback)
    }
    
    func pr_getClipboardData(callback: (OpenAPIBaseResponse<OpenPluginGetClipboardDataResponse>) -> Void) {
        var data: String?
        var didAssign = false
        let syncLock = DispatchSemaphore(value: 0)

        let globalQueue = DispatchQueue.global(qos: .default)
        globalQueue.async {
            let config = PasteboardConfig(token: OPSensitivityEntryToken.openPluginClipboardGetClipboardData.psdaToken)
            data = SCPasteboard.general(config).string
            didAssign = true
            syncLock.signal()
        }
        _ = syncLock.wait(timeout: (DispatchTime.now() + .seconds(3)))
        if didAssign {
            let result = OpenPluginGetClipboardDataResponse(data: data ?? "")
            callback(.success(data: result))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("get clipboard failed")
                .setAddtionalInfo(["data":""])
            callback(.failure(error: error))
        }
    }
    
    @FeatureGatingValue(key: "openplatform.api.extension.decouple.with.ttmicro")
    var apiExtensionEnable: Bool

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        if apiExtensionEnable {
            let extensionInfo = OpenAPIExtensionInfo(type: OpenAPIClipboardDataExtension.self, defaultCanBeUsed: true)
            registerAsync(for: "setClipboardData", registerInfo: .init(pluginType: Self.self, paramsType: OpenPluginSetClipboardDataRequest.self, resultType: OpenPluginSetClipboardDataResponse.self), extensionInfo: extensionInfo) {
                Self.setClipboardData($0)
            }
            registerAsync(for: "getClipboardData", registerInfo: .init(pluginType: Self.self, resultType: OpenPluginGetClipboardDataResponse.self), extensionInfo: extensionInfo) {
                Self.getClipboardData($0)
            }
        } else {
            registerInstanceAsyncHandlerGadget(for: "setClipboardData", pluginType: Self.self, paramsType: OpenPluginSetClipboardDataRequest.self, resultType: OpenPluginSetClipboardDataResponse.self) { (this, params, context, gadgetContext, callback) in
                
                this.setClipboardData(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
            registerInstanceAsyncHandlerGadget(for: "getClipboardData", pluginType: Self.self,paramsType: OpenAPIBaseParams.self, resultType: OpenPluginGetClipboardDataResponse.self) { (this, params, context, gadgetContext, callback) in
                
                this.getClipboardData(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
    }

}
