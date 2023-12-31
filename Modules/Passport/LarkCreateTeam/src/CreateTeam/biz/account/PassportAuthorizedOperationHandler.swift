//
//  PassportAuthorizedOperationHandler.swift
//  LarkCreateTeam
//
//  Created by Nix Wang on 2021/11/10.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import JsSDK
import TTMicroApp
import UIKit
import LarkOPInterface
import LarkOpenAPIModel
import OPPluginManagerAdapter

class PassportAuthorizedOperationHandler: JsAPIHandler {

    struct DataKey {
        static let data = "data"
        static let flowType = "flowType"
        static let configAuth = "configAuth"
        static let appId = "appId"
        static let userId = "userId"
        static let openId = "openId"
        static let deviceId = "deviceId"
        static let type = "type"
        static let userAccessToken = "user_access_token"
        static let sessionKey = "jssdk_session"
        static let session = "session"
        static let success = "success"
        static let code = "errCode"
        static let errorMsg = "errMsg"
        static let errCode = "errCode"
        static let errMsg = "errMsg"
        static let reqNo = "reqNo"
        static let ok = ":ok"
    }

    struct APIName {
        static let config = "config"
        static let startFaceVerify = "startFaceVerify"
        static let startFaceIdentify = "startFaceIdentify"
        static let getDeviceID = "getDeviceID"
    }

    @Provider var accountService: AccountService
    @Provider var openPlatformService: OpenPlatformService // user:checked (global-resolve)
    @Provider var dependency: PassportWebViewDependency

    private var pluginManager: OPPluginManagerAdapter?
    private var engine: PassportAuthorizedOperationEngine?

    private static let logger = Logger.log(PassportAuthorizedOperationHandler.self, category: "PassportAuthorizedOperationHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.authorizedOperation", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        Self.logger.info("n_action_authorized_op_start: logged in: \(accountService.isLogin)")

        guard let data = args[DataKey.data] as? [String: Any] else {
            Self.logger.error("n_action_authorized_op_fail: data not found", additionalData: ["args": "\(args.keys)"])
            callback.callbackSuccess(param: [
                DataKey.success: false,
                DataKey.code: -1,
                DataKey.errorMsg: "Invalid data"
            ])
            return
        }

        guard let flowType = data[DataKey.flowType] as? String,
              var configAuth = data[DataKey.configAuth] as? [String: Any] else {
            Self.logger.error("n_action_authorized_op_fail: Invalid params", additionalData: ["data": "\(data.keys)"])
                  callback.callbackSuccess(param: [
                    DataKey.success: false,
                    DataKey.code: -1,
                    DataKey.errorMsg: "Invalid params"
                  ])
            return
        }

        if !(flowType == APIName.startFaceVerify || flowType == APIName.startFaceIdentify || flowType == APIName.getDeviceID) {
            Self.logger.error("n_action_authorized_op_fail: Invalid flow type", additionalData: ["flowType": flowType])
            callback.callbackSuccess(param: [
                DataKey.success: false,
                DataKey.code: -1,
                DataKey.errorMsg: "Invalid flow type"
            ])
            return
        }

        guard let appId = configAuth[DataKey.appId] as? String,
              let openId = configAuth[DataKey.openId] as? String else {
                  Self.logger.error("n_action_authorized_op_fail: invalid auth config", additionalData: ["configAuth": "\(args.keys)"])
                  callback.callbackSuccess(param: [
                    DataKey.success: false,
                    DataKey.code: -1,
                    DataKey.errorMsg: "Invalid config auth params"
                  ])
            return
        }

        Self.logger.info("n_action_init_container_start")
        setup(appID: appId, bridgeController: api)
        Self.logger.info("n_action_init_container_end")

        configAuth[DataKey.deviceId] = accountService.deviceService.deviceId
        configAuth[DataKey.type] = DataKey.userAccessToken

        Self.logger.info("n_action_invoke_config_start: flowType: \(flowType)")

        invokeAPI(apiName: APIName.config, params: configAuth) { [weak self] (status, data) in
            guard let `self` = self else { return }

            if status != .success {
                Self.logger.error("n_action_invoke_config_fail: Config failed")
                Self.logger.error("n_action_authorized_op_fail")
                callback.callbackSuccess(param: [
                    DataKey.success: false,
                    DataKey.code: -1,
                    DataKey.errorMsg: "Config failed"
                ])
                return
            }

            if flowType == APIName.getDeviceID {
                Self.logger.error("n_action_invoke_getDeviceID")
                self.getDeviceID(callback: callback)
                return
            }

            guard let configData = data, let h5Session = self.parseConfigSession(configData: configData) else {
                Self.logger.error("n_action_invoke_config_fail: Failed to get session")
                Self.logger.error("n_action_authorized_op_fail")
                callback.callbackSuccess(param: [
                    DataKey.success: false,
                    DataKey.code: -1,
                    DataKey.errorMsg: "Failed to get session"
                ])
                return
            }

            Self.logger.info("n_action_invoke_config_succ")
            Self.logger.info("n_action_invoke_open_api_start: flowType: \(flowType)")

            let params = [DataKey.userId: openId,
                          DataKey.session: h5Session]
            self.invokeAPI(apiName: flowType, params: params) { (status, data) in
                let response = data as? [String: Any] ?? [String: Any]()
                if status != .success {
                    Self.logger.error("n_action_invoke_open_api_fail")
                    Self.logger.error("n_action_authorized_op_fail")
                    // 由于 Android JSB 设计限制，只能回调 success
                    callback.callbackSuccess(param: [
                        DataKey.success: false,
                        DataKey.code: response[DataKey.errCode] ?? -1,
                        DataKey.errorMsg: response[DataKey.errMsg] ?? "Unknown error"
                    ])
                    return
                }

                Self.logger.info("n_action_invoke_open_api_succ")
                Self.logger.info("n_action_authorized_op_succ")
                callback.callbackSuccess(param: [
                    DataKey.success: true,
                    DataKey.errMsg: flowType + DataKey.ok,
                    DataKey.reqNo: response[DataKey.reqNo] ?? ""
                ])
            }

        }
    }

    private func parseConfigSession(configData: [AnyHashable: Any]) -> String? {
        guard let data = configData[DataKey.data] as? [AnyHashable: Any],
              let innerData = data[DataKey.data] as? [AnyHashable: Any] else {
            return nil
        }

        return innerData[DataKey.sessionKey] as? String
    }

    private func setup(appID: String, bridgeController: UIViewController) {
        let uniqueID = BDPUniqueID(appID: appID,
                                   identifier: appID,
                                   versionType: .current,
                                   appType: .webApp)
        let engine = PassportAuthorizedOperationEngine(uniqueID: uniqueID, bridgeController: bridgeController)
        self.engine = engine
        pluginManager = OPPluginManagerAdapter(with: engine, type: .webApp, bizDomain: .passport)
    }

    private func invokeAPI(apiName: String, params: [String: Any]?, completion: @escaping BDPJSBridgeCallback) {
        guard let engine = engine else {
            Self.logger.info("n_action_authorized_operation_falied: engine is nil")
            completion(.failed, nil)
            return
        }

        guard let pluginManager = pluginManager else {
            Self.logger.info("n_action_authorized_operation_falied: pluginManager is nil")
            completion(.failed, nil)
            return
        }

        let parentTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let trace = OPTraceService.default().generateTrace(withParent: parentTrace, bizName: apiName)

        OPMonitor(name: "op_api_invoke", code: APIMonitorCodeCommon.native_receive_invoke)
            .setUniqueID(engine.uniqueID)
            .addMap(["api_name": apiName,
                     "params.count": params?.count ?? 0])
            .flushTo(trace)

        let method = BDPJSBridgeMethod(name: apiName, params: params)
        pluginManager.invokeAPI(method: method, trace: trace, engine: engine, callback: { (status, data) in
            let callbackJS = OPMonitor(name: "kEventName_op_api_invoke", code: APIMonitorCodeCommon.native_callback_invoke)
            OPAPIReportResult(status, data, callbackJS.monitorEvent)
            callbackJS.flushTo(trace)
            trace.finish()

            completion(status, data)
        })

    }

    private func getDeviceID(callback: WorkaroundAPICallBack) {
        let did = openPlatformService.getOpenPlatformDeviceID()
        //did 空或是space
        guard !did.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            callback.callbackSuccess(param: [
                DataKey.success: false,
                DataKey.errMsg: "deviceId is empty!"])
            return
        }
        var succData = OpenPluginDeviceResult(deviceID: did).toJSONDict()
        succData[DataKey.errMsg] = APIName.getDeviceID + DataKey.ok
        succData[DataKey.success] = true
        callback.callbackSuccess(param: succData)
    }
}

//@objcMembers
class PassportAuthorizedOperationEngine: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol {
    /// 引擎唯一标示符，appID要取config成功的那个AppID
    let uniqueID: BDPUniqueID

    /// 开放平台 JSBridge 方法类型
    let bridgeType: BDPJSBridgeMethodType = [.webApp]

    /// API权限校验器：这个要有，不能为nil
    var authorization: BDPJSBridgeAuthorizationProtocol? = PassportAuthorizedOperationAuthorization()

    /// 调用 API 所在的 ViewController 环境
    var bridgeController: UIViewController?

    /// session
    var h5Session: String?

    init(uniqueID: BDPUniqueID, bridgeController: UIViewController?) {
        self.uniqueID = uniqueID
        self.bridgeController = bridgeController
    }

    //  下面方法都是主动执行JS
    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {

    }

    public func bdp_fireEventV2(_ event: String, data: [AnyHashable: Any]?) {

    }

    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable: Any]?) {

    }

    public func getSession() -> String? {
        return h5Session
    }
}

class PassportAuthorizedOperationAuthorization: NSObject, BDPJSBridgeAuthorizationProtocol {

    /// API 权限校验方法
    /// - Parameters:
    ///   - method: API 方法
    ///   - engine: 引擎实体
    ///   - completion: 权限回调
    func checkAuthorization(_ method: BDPJSBridgeMethod?, engine: BDPJSBridgeEngine?, completion: ((BDPAuthorizationPermissionResult) -> Void)? = nil) {
        //  一期权限开放
        completion?(.enabled)
    }
}
