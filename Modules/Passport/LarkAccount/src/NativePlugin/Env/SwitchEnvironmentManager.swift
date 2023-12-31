//
//  SwitchEnvironmentManager.swift
//  LarkAccount
//
//  Created by au on 2021/8/23.
//

import Foundation
import RxSwift
import LarkAccountInterface
import LarkContainer
import LarkEnv
import LarkReleaseConfig
import LKCommonsLogging

/// 新账号模型跨端技术方案
/// https://bytedance.feishu.cn/docs/doccnxOHP4Cm2XQt6d54nbVpIqc
/// Passport 跨端 Cookbook
/// https://bytedance.feishu.cn/docx/doxcnqhcRqYb3eZKeuKCl7tCUic

enum SwitchEnvironmentError: Error, CustomStringConvertible {

    case weakSelfNotFound
    case invalidDeviceInfo(String)
    case envManagerSwitchFailed(String)
    case fetchDeviceInfoFailed(String)
    case rustSetEnvFailed(String)
    case rustSetDeviceInfoFailed(String)

    var description: String {
        switch self {
        case .weakSelfNotFound:
            return "SwitchEnvironmentError.weakSelfNotFound"
        case .invalidDeviceInfo(let desc):
            return "SwitchEnvironmentError.invalidDeviceInfo - \(desc)"
        case .envManagerSwitchFailed(let desc):
            return "SwitchEnvironmentError.envManagerSwitchFailed - \(desc)"
        case .fetchDeviceInfoFailed(let desc):
            return "SwitchEnvironmentError.fetchDeviceInfoFailed - \(desc)"
        case .rustSetEnvFailed(let desc):
            return "SwitchEnvironmentError.rustSetEnvFailed - \(desc)"
        case .rustSetDeviceInfoFailed(let desc):
            return "SwitchEnvironmentError.rustSetDeviceInfoFailed - \(desc)"
        }
    }
}

struct SwitchEnvironmentInfo: CustomStringConvertible {

    /// 是否执行了环境切换
    let didSwitch: Bool

    let envBeforeSwitching: Env

    let envAfterSwitching: Env

    let deviceID: String

    let installID: String

    var description: String {
        return "SwitchEnvironmentInfo didSwitch:\(didSwitch). Before is:\(envBeforeSwitching), after is:\(envAfterSwitching), with did:\(deviceID), iid: \(installID)."
    }
}

typealias SwitchEnvironmentResult = Result<SwitchEnvironmentInfo, SwitchEnvironmentError>

final class SwitchEnvironmentManager: EnvironmentInterface {

    static let logger = Logger.plog(SwitchEnvironmentManager.self, category: "Env.SwitchEnvironmentManager")

    static let shared = SwitchEnvironmentManager()

    /// 当前服务环境
    var env: Env { EnvManager.env }
    
    var tenantBrand: TenantBrand {
        guard let value = UserDefaults.standard.string(forKey: EnvManager.tenantBrandKey) else {
            
            // 从 config 中获取开关，如果开启，启用修复
            if PassportStore.shared.configInfo?.config().getEnableBrandFromForegroundUser() ?? true { // user:current
                Self.logger.info("n_action_env_get_config_brand", method: .local)
                if let foregroundBrand = UserManager.shared.foregroundUser?.user.tenant.brand { // user:current
                    Self.logger.info("n_action_env_get_foreground_tenant_brand", additionalData: ["brand": foregroundBrand.rawValue], method: .local)
                    return foregroundBrand
                }
            }
            
            Self.logger.error("n_action_env_ud_get_brand_error", method: .local)
            return appBrand
        }
        guard let brand = TenantBrand(rawValue: value) else {
            Self.logger.error("n_action_env_enum_init_brand_error")
            return appBrand
        }
        Self.logger.info("n_action_env_get_ud_tenant_brand", additionalData: ["brand": brand.rawValue], method: .local)
        return brand
    }

    var tenantGeo: String? {
        if let tenantGeo = UserManager.shared.foregroundUser?.user.tenant.geo { // user:current
            Self.logger.info("n_action_env_get_foreground_tenant_geo", additionalData: ["tenantGeo": tenantGeo], method: .local)
            return tenantGeo
        } else {
            Self.logger.info("n_action_env_get_foreground_tenant_geo_empty", additionalData: ["tenantGeo": "nil"], method: .local)
            return nil
        }
    }

    var isCrossUnit: Bool { return env != defaultEnv }

    /// 默认环境，逻辑见 init()
    private let defaultEnv: Env
    
    var appBrand: TenantBrand {
        return ReleaseConfig.isLark ? TenantBrand.lark : TenantBrand.feishu
    }

    @Provider private var loginService: V3LoginService
    @Provider private var deviceService: InternalDeviceServiceProtocol
    @Provider private var setDeviceInfoAPI: SetDeviceInfoAPI // user:checked (global-resolve)

    private let disposeBag = DisposeBag()

    private init() {
        defaultEnv = EnvManager.getPackageEnv()
    }

    /// 更新环境，同时获取新环境下 deviceID、installID 并存储
    /// Result 如果是失败的情景，内部`不包含`重置逻辑，需要外部使用方根据需要自行回退
    func switchEnvAndUpdateDeviceInfo(
        futureEnv: Env,
        brand: TenantBrand,
        completion: ((SwitchEnvironmentResult) -> Void)? = nil) {

        let presentEnv = env
        let presentBrand = tenantBrand
        let payload = [EnvPayloadKey.brand: brand.rawValue]

        // 两个环境相等，不切
        if futureEnv == presentEnv && brand == presentBrand {
            Self.logger.info("Future env - \(futureEnv) is equal to present env - \(presentEnv), brand - \(brand).")
            let did = deviceService.deviceId
            let iid = deviceService.installId
            let info = SwitchEnvironmentInfo(didSwitch: false, envBeforeSwitching: presentEnv, envAfterSwitching: futureEnv, deviceID: did, installID: iid)
            if DeviceInfo.isDeviceIDValid(did), DeviceInfo.isInstallIDValid(iid) {
                completion?(.success(info))
            } else {
                completion?(.failure(SwitchEnvironmentError.invalidDeviceInfo("Device ID: \(did); Install ID: \(iid)")))
            }
            return
        }

        Self.logger.info("n_action_update_env_start", body: "Current env: \(presentEnv), future env: \(futureEnv)")

            switchEnvTo(futureEnv, payload: payload) { [weak self] success in
            guard let self = self else {
                let error = SwitchEnvironmentError.weakSelfNotFound
                Self.logger.error("n_action_update_env_fail", error: error)
                completion?(.failure(error))
                return
            }
            guard success else {
                let error = SwitchEnvironmentError.envManagerSwitchFailed(BundleI18n.suiteLogin.Lark_Passport_CBLoginInitNetworkError)
                Self.logger.error("n_action_update_env_fail", error: error)
                completion?(.failure(error))
                return
            }
            // 获取新 DID
            self.deviceService.fetchDeviceId { deviceResult in
                Self.logger.info("n_action_get_cross_did", additionalData: ["result": "\(deviceResult)"])
                switch deviceResult {
                case .success(let deviceInfo):
                    self.loginService.refreshLoginConfig()
                    Self.logger.info("n_action_fetch_config")
                    // 更新 Rust DID
                    self.setDeviceInfoAPI
                        .setDeviceInfo(deviceId: deviceInfo.deviceId, installId: deviceInfo.installId)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            let info = SwitchEnvironmentInfo(didSwitch: true, envBeforeSwitching: presentEnv, envAfterSwitching: futureEnv, deviceID: deviceInfo.deviceId, installID: deviceInfo.installId)
                            Self.logger.info("n_action_update_env_succ", additionalData: ["did": deviceInfo.deviceId, "iid": deviceInfo.installId])
                            completion?(.success(info))
                        }, onError: { error in
                            // Rust 设置 device info 错误
                            let wrappedError = SwitchEnvironmentError.rustSetDeviceInfoFailed(error.localizedDescription)
                            Self.logger.error("n_action_update_env_fail", error: wrappedError)
                            completion?(.failure(wrappedError))
                        })
                        .disposed(by: self.disposeBag)

                case .failure(let error):
                    // 新环境下获取 device info 错误
                    let wrappedError = SwitchEnvironmentError.fetchDeviceInfoFailed(error.localizedDescription)
                    Self.logger.error("n_action_update_env_fail", error: wrappedError)
                    completion?(.failure(wrappedError))
                }
            }

        }
    }

    /// 重置回包环境
    /// ALPHA (Debug、Inhouse) 使用动态环境
    /// BETA、RELEASE 使用包环境
    /// 在`没有` foregroundUser 时的 CP 输入首页及退出登录全部时使用
    func resetEnv(completion: ((Bool) -> Void)? = nil) {
        Self.logger.info("n_action_reset_env",
                         additionalData: ["defaultEnv": defaultEnv.description,
                                          "defaultBrand": appBrand.rawValue],
                         method: .local)
        let payload = [EnvPayloadKey.brand: appBrand.rawValue]
        switchEnvTo(defaultEnv, payload: payload) { [weak self] _ in
            guard let self = self else { return }
            self.setDeviceInfoAPI
                .setDeviceInfo(deviceId: self.deviceService.deviceId, installId: self.deviceService.installId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    Self.logger.info("n_action_reset_env_and_did_succ", additionalData: ["did": self.deviceService.deviceId, "iid": self.deviceService.installId])
                    completion?(true)
                }, onError: { error in
                    // Rust 重置 device info 错误
                    let wrappedError = SwitchEnvironmentError.rustSetDeviceInfoFailed(error.localizedDescription)
                    Self.logger.error("n_action_reset_env_and_did_fail", error: wrappedError)
                    completion?(false)
                })
                .disposed(by: self.disposeBag)
        }
    }

    /// 恢复到切之前 User 的环境
    /// 在`有` foregroundUser 发生切换失败时使用
    func recoverEnv(completion: ((Bool) -> Void)? = nil) {
        // 恢复的环境和前台 user 保持一致，如果不存在前台 user 就回滚到包环境
        var backupEnv = defaultEnv
        var backupBrand = appBrand

        Self.logger.info("n_action_recover_env",
                         additionalData: ["backupEnv": backupEnv.description,
                                          "backupBrand": backupBrand.rawValue])
        // 如果有前台用户，使用前台用户的数据进行恢复
        if let userUnit = UserManager.shared.foregroundUser?.user.unit, // user:current
           let userGeo = UserManager.shared.foregroundUser?.user.geo, // user:current
           let tenantBrand = UserManager.shared.foregroundUser?.user.tenant.brand { // user:current
            backupEnv = Env(unit: userUnit, geo: userGeo, type: EnvManager.env.type)
            backupBrand = tenantBrand
            Self.logger.info("n_action_recover_env",
                             additionalData: ["backupEnvUsingForegroundUser": backupEnv.description,
                                              "backupBrandUsingForegroundUser": backupBrand.rawValue])
        }
        let payload = [EnvPayloadKey.brand: backupBrand.rawValue]

        switchEnvTo(backupEnv, payload: payload) { [weak self] _ in
            guard let self = self else { return }
            self.setDeviceInfoAPI
                .setDeviceInfo(deviceId: self.deviceService.deviceId, installId: self.deviceService.installId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    Self.logger.info("n_action_recover_env_and_did_succ", additionalData: ["did": self.deviceService.deviceId, "iid": self.deviceService.installId])
                    completion?(true)
                }, onError: { error in
                    // Rust 重置 device info 错误
                    let wrappedError = SwitchEnvironmentError.rustSetDeviceInfoFailed(error.localizedDescription)
                    Self.logger.error("n_action_recover_env_and_did_fail", error: wrappedError)
                    completion?(false)
                })
                .disposed(by: self.disposeBag)
        }
    }

    /// 更新环境
    private func switchEnvTo(_ futureEnv: Env, payload: [AnyHashable: Any], completion: ((Bool) -> Void)? = nil) {
        EnvManager
            .switchEnv(futureEnv, payload: payload)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    let error = SwitchEnvironmentError.weakSelfNotFound
                    Self.logger.error("n_action_update_env_fail", error: error)
                    completion?(false)
                    return
                }
                completion?(true)
            }, onError: { error in
                Self.logger.error("Switch env error in EnvManager.switchEnv", error: error)
                completion?(false)
            })
            .disposed(by: disposeBag)
    }
}
