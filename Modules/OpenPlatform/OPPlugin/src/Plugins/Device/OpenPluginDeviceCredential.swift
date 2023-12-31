//
//  OpenPluginDeviceCredential.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import LocalAuthentication
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import OPFoundation
import LarkContainer
class OpenPluginDeviceCredential: OpenBasePlugin {

    public func startDeviceCredential(params: OpenPluginStartDeviceCredentialRequest, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard !params.authContent.isEmpty else {
            context.apiTrace.warn("authContent is empty")
            DispatchQueue.main.async {
                let error = OpenAPIError(code: StartDeviceCredentialErrorCode.authContentEmpty)
                    .setOuterMessage(BundleI18n.OPPlugin.auth_content_must_non_null())
                    .setOuterCode(40003)
                    .setErrno(OpenAPICredentialErrno.startdevicecredentialAuthcontentEmpty)
                callback(.failure(error: error))
            }
            return
        }
        let laContext = LAContext()
        var error: NSError?
        let policy = LAPolicy.deviceOwnerAuthentication

        //首先使用canEvaluatePolicy 判断设备支持状态
        if !laContext.canEvaluatePolicy(policy, error: &error) {
            context.apiTrace.warn("LAPolicyDeviceOwnerAuthentication user might not have password, err=\(String(describing: error))")
            DispatchQueue.main.async {
                let error = OpenAPIError(code: StartDeviceCredentialErrorCode.passwordNotSet)
                    .setOuterMessage(BundleI18n.OPPlugin.not_set_lock_screen_password())
                    .setOuterCode(40000)
                    .setErrno(OpenAPICredentialErrno.startdevicecredentialPasswordNotSet)
                callback(.failure(error: error))
            }
            return
        }
        //支持指纹验证
        OPSensitivityEntry.evaluatePolicy(forToken: .openPluginDeviceCredentialStartDeviceCredential, laContext: laContext, policy: policy, localizedReason: params.authContent, reply: {
            (success: Bool, error: Error?) in
            DispatchQueue.main.async {
                if success {
                    callback(.success(data: nil))
                    return
                }
                if let error = error as? OpenAPIError {
                    callback(.failure(error: error))
                    return
                }
                guard let err = error as NSError? else {
                    let error = OpenAPIError(code: StartDeviceCredentialErrorCode.unlockFail)
                        .setMonitorMessage("unlock fail has nil error")
                        .setOuterMessage(BundleI18n.OPPlugin.unlock_falied)
                        .setOuterCode(40002)
                        .setErrno(OpenAPICredentialErrno.startdevicecredentialUnlockFail)
                    callback(.failure(error: error))
                    return
                }
                context.apiTrace.error("evaluatePolicy error, err=\(err)")
                switch err.code {
                // 切换到其他APP，系统取消验证Touch ID
                // 用户取消验证Touch ID
                // 用户选择手动输入密码
                case LAError.systemCancel.rawValue, LAError.userCancel.rawValue, LAError.userFallback.rawValue:
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage(BundleI18n.OPPlugin.unlock_falied())
                        .setOuterCode(40002)
                        .setErrno(OpenAPICredentialErrno.startdevicecredentialUnlockFail)
                    callback(.failure(error: error))
                default:
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage(BundleI18n.OPPlugin.unlock_falied())
                        .setOuterCode(40002)
                        .setErrno(OpenAPICredentialErrno.startdevicecredentialUnlockFail)
                    callback(.failure(error: error))
                }
            }

        })
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "startDeviceCredential", pluginType: Self.self, paramsType: OpenPluginStartDeviceCredentialRequest.self) { (this, params, context, callback) in
            
            this.startDeviceCredential(params: params, context: context, callback: callback)
        }
    }

}
