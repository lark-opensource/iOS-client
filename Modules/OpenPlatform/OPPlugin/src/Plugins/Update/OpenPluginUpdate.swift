//
//  OpenPluginUpdate.swift
//  OPPlugin
//
//  Created by yinyuan on 2021/5/10.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import OPSDK
import TTMicroApp
import LarkContainer
import OPPluginManagerAdapter

final class OpenPluginUpdate: OpenBasePlugin {
    
    private static let errorMsgHasNoUpdate = "has no update"
    
    private enum APIName: String {
        case applyUpdate
        case triggerCheckUpdate
    }

    func applyUpdate(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        // 主导航栏小程序调用applyUpdate接口报错,对齐Android
        if !OPSDKFeatureGating.enableTabGadgetUpdate(), OPSDKFeatureGating.tabGadgetDisableApplyUpdate(), OPGadgetRotationHelper.isTabGadget(uniqueID) {
            let error = OpenAPIError(code: TriggerCheckUpdateErrorCode.noNeedUpdate)
                .setOuterMessage(Self.errorMsgHasNoUpdate)
                .setErrno(OpenAPIUiWindowErrno.tabGadgetNotSupport)
            callback(.failure(error: error))
            return
        }

        // 新容器逻辑
        let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID)
        //如果 FG 开启，则走新逻辑
        if OPSDKFeatureGating.enableApplyUpdateImprove() {
            if container?.updater?.applyUpdateIfNeeded({
                callback(.success(data: nil))
                OPMonitor(GDMonitorCode.apply_update).setUniqueID(uniqueID).flush()
            }) == true {
                    context.apiTrace.info("enableApplyUpdateImprove is true, and block executed")
            } else {
                let errorMsg = Self.errorMsgHasNoUpdate
                let error = OpenAPIError(code: TriggerCheckUpdateErrorCode.noNeedUpdate).setMonitorMessage(errorMsg).setOuterMessage(errorMsg)
                if OPSDKFeatureGating.packageAPIUnifiedEnable() {
                    error.setErrno(OpenAPIGetUpdateManagerErrno.notNeedUpdate)
                }
                callback(.failure(error: error))
            }
            return
        }
        if container?.updater?.applyUpdateIfNeeded(nil) == true {
            callback(.success(data: nil))
            OPMonitor(GDMonitorCode.apply_update).setUniqueID(uniqueID).flush()
        } else {
            let errorMsg = Self.errorMsgHasNoUpdate
            let error = OpenAPIError(code: TriggerCheckUpdateErrorCode.noNeedUpdate).setMonitorMessage(errorMsg).setOuterMessage(errorMsg)
            if OPSDKFeatureGating.packageAPIUnifiedEnable() {
                error.setErrno(OpenAPIGetUpdateManagerErrno.notNeedUpdate)
            }
            callback(.failure(error: error))
        }
    }
    
    func triggerCheckUpdate(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        // 本 API 代码全量后可删掉 BDPLifeCyclePluginDelegate.bdp_checkUpdate 的逻辑
        EMAAppAboutUpdateManager.shared().fetchMetaAndDownload(with: uniqueID, statusChanged: { (status, latestVersion) in
            EMAAppAboutUpdateManager.shared().handle(status, uniqueID: uniqueID)
        })
        callback(.success(data: nil))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        registerInstanceAsyncHandlerGadget(for: APIName.applyUpdate.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.applyUpdate(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.triggerCheckUpdate.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.triggerCheckUpdate(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
