//
//  RustClientLauncherDelegate.swift
//  LarkRustClient
//
//  Created by Yiming Qu on 2021/2/2.
//

import Foundation
import LarkAccountInterface
import AppContainer
import LarkPerf
import LarkContainer
import BootManager
import LKCommonsLogging
import LarkFoundation
import LarkTTNetInitializor
import RustPB
import LarkTracker
import LarkSetting
import LarkEnv
import RxSwift

final class RustClientLauncherDelegate: LauncherDelegate {

    private static let logger = Logger.log(
        RustClientLauncherDelegate.self,
        category: "LarkRustClientAssembly.RustClientLauncherDelegate"
    )
    let name: String = "RustService"

    @InjectedLazy var client: LarkRustClient

    @Provider var dependency: RustClientDependency

    @Provider var accountService: AccountService

    // 传值true会dispose掉client
    private static var rustBarrierDisposeClientBlock: ((_ finish: Bool) -> Void)?

    func beforeSwitchSetAccount(_ account: Account) {

        guard accountService.isExecutingSwitchUserV2() == false else { return }

        Self.logger.info("before switch set account update rust service", additionalData: [
            "uid": account.userID
        ])
        self.client.updateRustService(userId: account.userID)
    }

    func beforeSetAccount(_ account: Account) {
        guard accountService.isExecutingSwitchUserV2() == false else { return }
        guard accountService.isNewEnterAppProcess() == false else { return }
        _beforeSetAccount(account)
    }

    private func _beforeSetAccount(_ account: Account) {

        Self.logger.info("before set account update reset rust service", additionalData: [
            "uid": account.userID
        ])
        let mergedAccount = account
        AppStartupMonitor.shared.start(key: .rustSDK)
        let id2 = TimeLogger.shared.logBegin(eventName: "ResetClient")
        self.client.reset(
            with: mergedAccount.userID,
            tenantID: mergedAccount.tenant.tenantID,
            tenantTag: TenantTag(rawValue: account.tenantInfo.tenantTag ?? -1) ?? .standard,
            accessToken: mergedAccount.accessToken,
            logoutToken: mergedAccount.logoutToken,
            isLightlyActive: NewBootManager.shared.context.isLightlyActive,
            isFastLogin: NewBootManager.shared.context.isFastLogin,
            isGuest: mergedAccount.isGuestUser,
            avatarPath: dependency.avatarPath,
            leanModeInfo: account.leanModeInfo
        )
        TimeLogger.shared.logEnd(identityObject: id2, eventName: "ResetClient")
        AppStartupMonitor.shared.end(key: .rustSDK)
    }

    func afterLogout(context: LauncherContext, conf: LogoutConf) {
        Self.logger.info("after logout update rust service", additionalData: [
            "uid": String(describing: context.currentUserID)
        ])
        self.client.updateRustService(userId: nil)
    }

    // barrier逻辑
    func beforeSwitchAccout() {

        guard accountService.isExecutingSwitchUserV2() else { return }

        // passport侧 barrier 如果开启了异步等待，beforeSwitchAccout的逻辑不再执行
        // 异步等待的barrier逻辑参考 switchUserEnterBarrier() 方法
        guard !accountService.enableSwitchUserEnterBarrierTask() else { return }

        DispatchQueue.global().async { [weak self] in
            self?.barrier { leaveBlock in
                Self.rustBarrierDisposeClientBlock = leaveBlock
            }
        }
    }

    func afterSwitchAccout(error: Error?) -> Observable<Void> {

        guard accountService.isExecutingSwitchUserV2() else { return .just(()) }

        // 切换成功后才dispose掉当前rustClient
        Self.rustBarrierDisposeClientBlock?((error != nil) ? false : true)
        Self.rustBarrierDisposeClientBlock = nil
        return .just(())
    }
}

extension RustClientLauncherDelegate: RustImplProtocol {

    func rustOnlineRequest(account: Account) {
        _beforeSetAccount(account)
    }

    func barrier(enter: @escaping (@escaping (_ finish: Bool) -> Void) -> Void) {
        if MultiUserActivitySwitch.enableMultipleUser {
            // 多用户使用新栅栏流程，拦截所有当前用户的请求
            self.client.barrier { (dofinish) in
                enter { _ in dofinish() }
            }
            return
        }

        // 保证切换账户和创建新RustClient的原子性。切换后旧的push都会被cancel掉.
        // 必须获取持有当前client对象
        let client = self.client.unwrapped
        let allowMessage: Set<String> = [
            // FIXME: 这是调用链上的一个barrier调用，但已经在barrier里了，异步并不会再阻塞其它调用。
            // 但如果本身控制了异步串行的话，应该影响不大。
            Tool_V1_MakeUserOfflineRequest.protoMessageName,
            Tool_V1_MakeUserOnlineRequest.protoMessageName,
            Basic_V1_SetEnvRequest.protoMessageName,
            Device_V1_GetDeviceIdRequest.protoMessageName,
            Device_V1_SetDeviceRequest.protoMessageName,
            Tool_V1_GetCaptchaEncryptedTokenRequest.protoMessageName,
            // SwitchUser，本地没有对应user时，拉取user列表会调用此方法
            Device_V1_SetDeviceSettingRequest.protoMessageName,
            Openplatform_V1_IsAppLinkEnableRequest.protoMessageName,
            Settings_V1_GetCommonSettingsRequest.protoMessageName,
            Passport_V1_ResetRequest.protoMessageName,
            Basic_V1_SetClientStatusRequest.protoMessageName, // 网络状态设置，本身应该是全局接口，待迁移。但现在跟随用户态使用..
            // 安全文件加解密
            Security_V1_FileSecurityQueryStatusV2Request.protoMessageName,
            Security_V1_FileSecurityEncryptDirV2Request.protoMessageName,
            Security_V1_FileSecurityEncryptV2Request.protoMessageName,
            Security_V1_FileSecurityDecryptDirV2Request.protoMessageName,
            Security_V1_FileSecurityDecryptV2Request.protoMessageName,
            Security_V1_FileSecurityWriteBackV2Request.protoMessageName

        ]
        Self.logger.info("switch user start barrier")
        client.barrier(allowRequest: { (packet) -> Bool in
            let messageName = type(of: packet.message).protoMessageName
            let allow = allowMessage.contains(messageName)
            if !allow {
                Self.logger.warn("not allow request while barrier, may cause stuck on switch user", additionalData: [
                    "messageName": messageName
                ])
            }
            return allow
        }, enter: { leave in // NOTE: leave must be called
            Self.logger.info("switch user enter barrier")
            enter({ finish in
                Self.logger.info("switch user finish barrier", additionalData: ["finish": String(describing: finish)])
                if finish {
                    // client生命周期结束，强制释放，取消掉后续请求。
                    client.dispose()
                }
                leave()
            })
        })
    }
}

extension RustClientLauncherDelegate: PassportRustClientDependency {

    func deployUserBarrier(userID: String, completionHandler: @escaping (@escaping (_ finish: Bool) -> Void) -> Void) {
        barrier { leaveHandler in
            Self.rustBarrierDisposeClientBlock = leaveHandler
            completionHandler(leaveHandler)
        }
    }

    func makeUserOnline(account: Account, completionHandler: @escaping (Result<Void, Error>) -> Void) {

        Self.logger.info("PassportRustClientDependency makeUserOnline", additionalData: [
            "uid": account.userID
        ])
        AppStartupMonitor.shared.start(key: .rustSDK)
        let id2 = TimeLogger.shared.logBegin(eventName: "ResetClient")
        self.client.reset(
            with: account.userID,
            tenantID: account.tenant.tenantID,
            tenantTag: TenantTag(rawValue: account.tenantInfo.tenantTag ?? -1) ?? .standard,
            accessToken: account.accessToken,
            logoutToken: account.logoutToken,
            isLightlyActive: NewBootManager.shared.context.isLightlyActive,
            isGuest: account.isGuestUser,
            avatarPath: dependency.avatarPath,
            leanModeInfo: account.leanModeInfo,
            completionHandler: completionHandler
        )
        TimeLogger.shared.logEnd(identityObject: id2, eventName: "ResetClient")
        AppStartupMonitor.shared.end(key: .rustSDK)
    }

    func makeUserOffline(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        self.client.makeUserOffline(completionHandler: completionHandler)
    }

    func updateDeviceInfo(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        self.client.setDeviceInfo(did: did, iid: iid, completionHandler: completionHandler)
    }

    func updateDeviceInfoV2(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        self.client.setDeviceInfoV2(did: did, iid: iid, completionHandler: completionHandler)
    }

    func updateRustEnv(_ env: Env, brand: String, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
        rustEnv.unit = env.unit
        rustEnv.type = env.type.transform()
        rustEnv.brand = brand
        self.client.setEnv(rustEnv, completionHandler: completionHandler)
    }

}
