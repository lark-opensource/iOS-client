//
//  RustLogoutAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import LarkRustClient
import RustPB
import LarkContainer
import RxSwift
import LKCommonsLogging
import ECOProbeMeta
import LarkAccountInterface

typealias MakeUserOfflineRequest = RustPB.Tool_V1_MakeUserOfflineRequest
typealias MakeUserOfflineResponse = RustPB.Tool_V1_MakeUserOfflineResponse

class RustLogoutAPI: LogoutAPI {

    static let logger = Logger.plog(RustLogoutAPI.self, category: "SuiteLogin.RustLogoutAPI")

    @Provider var globalRustService: GlobalRustService
    @Provider var userRustService: RustService // user:checked (global-resolve)
    @Provider var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    private let nativeLogoutAPI = NativeLogoutAPI()
    private let internalContext = UniContextCreator.create(.logout)

    func logout(sessionKeys: [String], makeOffline: Bool, logoutType: CommonConst.LogoutType, context: UniContextProtocol) -> Observable<Void> {
        ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutRequestFlow)
        PassportMonitor.flush(PassportMonitorMetaLogout.startLogoutRequest,
                              eventName: ProbeConst.monitorEventName,
                              context: context)
        return nativeLogoutAPI
            .logout(sessionKeys: sessionKeys, makeOffline: makeOffline, logoutType: logoutType, context: context)
            .do(onNext: { [weak self] _ in
                self?.monitorLogoutRequestResult(isSucceeded: true, context: context)
            }, onError: { [weak self] error in
                self?.monitorLogoutRequestResult(isSucceeded: false, context: context, error: error)
            })
            .flatMap({ _ -> Observable<Void> in
                Self.logger.info("n_action_logout_rust_offline")
                return makeOffline ? self.syncLogout(context: context) : .just(())
            })
    }
    
    func makeOffline() -> Observable<Void> {
        return syncLogout(context: internalContext)
    }

    /// 同步登出
    /// 不请求Passport Server，只清理本地 Session，DB等缓存
    private func syncLogout(context: UniContextProtocol) -> Observable<Void> {
        ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutRustFlow)
        PassportMonitor.flush(PassportMonitorMetaLogout.startLogoutRustTaskHandle,
                              eventName: ProbeConst.monitorEventName,
                              context: context)
        let request = MakeUserOfflineRequest()
        return globalRustService
            .sendAsyncRequestBarrier(request)
            .do(onNext: { [weak self] _ in
                Self.logger.info("n_action_logout_rust_offline_succ")
                self?.monitorLogoutRustResult(isSucceeded: true, context: context)
            }, onError: { [weak self] error in
                Self.logger.error("n_action_logout_rust_offline_fail", error: error)
                self?.monitorLogoutRustResult(isSucceeded: false, context: context, error: error)
            })
            .trace("SyncLogout")
    }

    /// 栅栏请求，防止登出时发起Rust请求导致意外踢出
    /// UserScope: 接口先行改造成外部显式传入 userID，保证获取的 userResolver 和调用方一致且不可变
    /// userRustService barrier 起到屏蔽用户态与全局态其它请求的作用
    func barrier(
        userID: String,
        enter: @escaping (_ leave: @escaping (_ finish: Bool) -> Void) -> Void
    ) {
        Self.logger.info("logout start barrier")

        if PassportUserScope.enableUserScopeTransitionRust || MultiUserActivitySwitch.enableMultipleUser {
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_rust_offline_start, context: internalContext)
            rustDependency.deployUserBarrier(userID: userID) { leaveHanlder in
                PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_rust_offline_succ, context: self.internalContext)
                enter(leaveHanlder)
            }
        } else {
            let allowMessage: Set<String> = [
                MakeUserOfflineRequest.protoMessageName,
                Basic_V1_SetEnvRequest.protoMessageName,
                Passport_V1_ResetRequest.protoMessageName,
                // 安全文件加解密
                Security_V1_FileSecurityQueryStatusV2Request.protoMessageName,
                Security_V1_FileSecurityEncryptDirV2Request.protoMessageName,
                Security_V1_FileSecurityEncryptV2Request.protoMessageName,
                Security_V1_FileSecurityDecryptDirV2Request.protoMessageName,
                Security_V1_FileSecurityDecryptV2Request.protoMessageName,
                Security_V1_FileSecurityWriteBackV2Request.protoMessageName
            ]
            Self.logger.info("logout start barrier")
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_rust_offline_start, context: internalContext)
            // 登出或者切换租户，需要销毁前一个RustClient，并且重新生成RustClient。
            // 必须获取持有当前client对象
            let client = self.userRustService
            client.barrier(allowRequest: { (packet) -> Bool in
                let messageName = type(of: packet.message).protoMessageName
                let allow = allowMessage.contains(messageName)
                if !allow {
                    Self.logger.warn("not allow request while barrier, may cause stuck on logout", additionalData: [
                        "messageName": messageName
                    ])
                }
                return allow
            }, enter: { leave in
                Self.logger.info("logout enter barrier")
                enter({ finish in
                    Self.logger.info(
                        "logout finish barrier",
                        additionalData: [
                            "finish": String(describing: finish)
                        ])
                    if finish {
                        // dispose current client
                        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_rust_offline_succ, context: self.internalContext)
                        client.dispose()
                    }
                    leave()
                })
            })
        }

    }

    // MARK: - Monitor

    // 登出网络请求
    private func monitorLogoutRequestResult(isSucceeded: Bool, context: UniContextProtocol, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutRequestFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutRequestResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: internalContext)

        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail()
            if let error = error {
                _ = monitor.setPassportErrorParams(error: error)
            }
            let message = errorMsg ?? "logout request flow error"
            monitor.setErrorMessage(message).flush()
        }
    }

    // 登出 rust 请求
    private func monitorLogoutRustResult(isSucceeded: Bool, context: UniContextProtocol, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutRustFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutRustTaskHandleResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: internalContext)

        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail()
            let message: String? = (errorMsg != nil) ? errorMsg : "logout rust flow error \(error?.localizedDescription ?? "")"
            if let error = error {
                _ = monitor.setPassportErrorParams(error: error)
            }
            monitor.setErrorMessage(message).flush()
        }
    }

}
