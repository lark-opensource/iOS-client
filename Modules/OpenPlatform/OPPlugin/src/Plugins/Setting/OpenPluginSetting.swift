//
//  OpenPluginSetting.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginSetting: OpenBasePlugin {

    // implemention of api handlers
    func getSetting(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIGetSettingResult>) -> Void) {
        guard let auth = gadgetContext.authorization else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("gadgetContext auth is nil")
                .setOuterMessage("auth env error")
            callback(.failure(error: error))
            return
        }
        var authInfo = auth.usedScopesDict()
        if let authPlugin = BDPTimorClient.shared().authorizationPlugin.sharedPlugin() as? BDPAuthorizationPluginDelegate,
           let info = authPlugin.bdp_customGetSettingUsedScopesDict(authInfo) {
            context.apiTrace.info("get auth config by custom, infoKeys:\(info.keys)")
            authInfo = info
        }
        callback(.success(data: OpenAPIGetSettingResult(with: dictToSettingData(authInfo: authInfo))))
    }

    func openSetting(context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetSettingResult>) -> Void) {
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
              let controller = gadgetContext.controller else {
                  let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                      .setMonitorMessage("gadgetContext or controller is nil")
                  callback(.failure(error: error))
                  return
        }
        guard let auth = gadgetContext.authorization else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("gadgetContext auth is nil")
            callback(.failure(error: error))
            return
        }
        guard let navi = controller.navigationController else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("can not push permission vc without navigation")
            callback(.failure(error: error))
            return
        }
        guard let permissionVC = BDPPermissionController(callback: { [weak self] (status, data) in
            guard let self = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage("self is nil When call API")
                callback(.failure(error: error))
                return
            }
            switch status {
            case .success:
                let authSetting = data?["authSetting"] as? [AnyHashable: Any] ?? [:]
                callback(.success(data: OpenAPIGetSettingResult(with: self.dictToSettingData(authInfo: authSetting))))
            // 这里的status 只可能返回success 故不对其他case做处理
            default:
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("BDPPermissionController callback error type \(status.rawValue)")
                callback(.failure(error: error))
            }
        }, authProvider: auth) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("permission vc init error")
            callback(.failure(error: error))
            return
        }
        navi.pushViewController(permissionVC, animated: true)
    }

    private func dictToSettingData(authInfo: [AnyHashable: Any]) -> SettingData {
        var settingData = SettingData()
        for info in authInfo {
            if let scopeName = info.key as? String,
               let scope = Scope(rawValue: scopeName),
               let state = info.value as? Int,
               let scopeState = ScopeState(rawValue: state) {
                switch scope {
                case .userInfo:
                    settingData.userInfo = scopeState
                case .userLocation:
                    settingData.userLocation = scopeState
                case .record:
                    settingData.record = scopeState
                case .writePhotosAlbum:
                    settingData.writePhotosAlbum = scopeState
                case .clipboard:
                    settingData.clipboard = scopeState
                case .appBadge:
                    settingData.appBadge = scopeState
                case .runData:
                    settingData.runData = scopeState
                case .bluetooth:
                    settingData.bluetooth = scopeState
                case .camera:
                    settingData.camera = scopeState
                }
            }
        }
        return settingData
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // register your api handlers here
        registerInstanceAsyncHandler(for: "openSetting", pluginType: Self.self, resultType: OpenAPIGetSettingResult.self) { (this, _, context, callback) in
            
            this.openSetting(context: context, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "getSetting", pluginType: Self.self, resultType: OpenAPIGetSettingResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.getSetting(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

enum Scope: String {
    case userInfo = "scope.userInfo"
    case userLocation = "scope.userLocation"
    case record = "scope.record"
    case writePhotosAlbum = "scope.writePhotosAlbum"
    case clipboard = "scope.clipboard"
    case appBadge = "scope.appBadge"
    case runData = "scope.runData"
    case bluetooth = "scope.bluetooth"
    case camera = "scope.camera"
}

enum ScopeState: Int {
    case notOpr = -1   // 未操作
    case unAuth = 0    // 未授权
    case auth = 1      // 已授权
}

extension ScopeState {
    var isAuth: Bool? {
        switch self {
        case .unAuth:
            return false
        case .auth:
            return true
        case .notOpr:
            return nil
        }
    }
}

struct SettingData {
    var userInfo = ScopeState.notOpr
    var userLocation = ScopeState.notOpr
    var record = ScopeState.notOpr
    var writePhotosAlbum = ScopeState.notOpr
    var clipboard = ScopeState.notOpr
    var appBadge = ScopeState.notOpr
    var runData = ScopeState.notOpr
    var bluetooth = ScopeState.notOpr
    var camera = ScopeState.notOpr
}
