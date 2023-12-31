//
//  OpenPluginDevice.swift
//  OPPlugin
//
//  Created by bytedance on 2021/4/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginDevice: OpenBasePlugin {
    /// OpenAPI：登录
    public func getDeviceID(params: OpenAPIBaseParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginDeviceResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        var orgAuthMap = [:] as [AnyHashable: Any]
        if let authorization = gadgetContext.authorization {
            orgAuthMap = authorization.source.orgAuthMap
        } else {
            context.apiTrace.info("authorization is nil")
        }
        let orgAuthMapState: EMAOrgAuthorizationMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
        
        let hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "getDeviceID")
        OPMonitor(kEventName_mp_organization_api_invoke)
            .setUniqueID(uniqueID)
            .addCategoryValue("api_name", "getDeviceID")
            .addCategoryValue("auth_name", "deviceID")
            .addCategoryValue("has_auth", hasAuth ? 1 : 0)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        guard hasAuth else {
            context.apiTrace.error("no deviceID authorization")
            let error = OpenAPIError(code: GetDeviceIDErrorCode.authDeny)
                .setOuterMessage("no deviceID authorization")
            callback(.failure(error: error))
            return
        }
        context.apiTrace.info("has permission to getDeviceID")
        guard let delegate = EMAProtocolProvider.getEMADelegate() else {
            context.apiTrace.error("delegate is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("delegate is nil")
            callback(.failure(error: error))
            return
        }
        let deviceID = delegate.hostDeviceID()
        guard !deviceID.isEmpty else {
            context.apiTrace.error("deviceId is nil!")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("deviceId is empty!")
            callback(.failure(error: error))
            return
        }
        callback(.success(data: OpenPluginDeviceResult(deviceID: deviceID)))
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "getDeviceID", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginDeviceResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getDeviceID(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
