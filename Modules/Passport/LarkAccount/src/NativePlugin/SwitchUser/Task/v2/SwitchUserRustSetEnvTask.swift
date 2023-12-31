//
//  SwitchUserRustSetEnvTask.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/9.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import LarkEnv
import ECOProbeMeta

class SwitchUserRustSetEnvTask: NewSwitchUserTask {

    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    @Provider private var envManager: EnvironmentInterface

    override func run() {

        guard let toUser = switchContext.switchUserInfo else {
            logger.error(SULogKey.switchCommon, body: "rust set env task fail with no target userInfo")
            failCallback(AccountError.notFoundTargetUser)
            assertionFailure("something wrong, please contact passport")
            return
        }

        guard let toUnit = toUser.user.unit else {
            logger.error("n_action_switch_cross_switch_fail", body: "Selected user's unit is nil.")
            self.failCallback(AccountError.notFoundTargetUser)
            assertionFailure("Something wrong, please contact passport")
            return
        }

        let toEnv = Env(unit: toUnit, geo: toUser.user.geo, type: envManager.env.type)

        logger.info("n_action_switch_rust_set_env_start", body: "env \(toEnv)", method: .local)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvStart, categoryValueMap: ["request_type": "default"], timerStart: .rustSetEnv, context: monitorContext)

        rustDependency.updateRustEnv(toEnv, brand: toUser.user.tenant.brand.rawValue) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.logger.info("n_action_switch_rust_set_env_succ", body: "env \(toEnv)", method: .local)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvResult, categoryValueMap: ["request_type": "default"], timerStop: .rustSetEnv, isSuccessResult: true, context: self.monitorContext)

                self.getCachedDeviceInfo(unit: toUnit)
            case .failure(let error):
                //日志和监控
                self.logger.error("n_action_switch_rust_set_env_fail", body: "env \(toEnv)", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvResult, categoryValueMap: ["request_type": "default"], timerStop: .rustSetEnv, isFailResult: true, context: self.monitorContext, error: error)

                self.failCallback(AccountError.switchUserRustFailed(rawError: error))
            }
        }
    }

    func getCachedDeviceInfo(unit: String) {
        guard let deviceInfo = switchContext.deviceInfo else {
            logger.info(SULogKey.switchCommon, body: "rust set env task no device info")
            failCallback(AccountError.switchUserDeviceInfoError)
            return
        }
        updateRustDeviceInfo(did: deviceInfo.deviceId, iid: deviceInfo.installId)
    }

    func updateRustDeviceInfo(did: String, iid: String) {

        logger.info("n_action_switch_rust_set_deviceinfo_start", method: .local)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoStart, categoryValueMap: ["request_type": "default"], timerStart: .rustSetDeviceInfo, context: monitorContext)


        rustDependency.updateDeviceInfo(did: did, iid: iid) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.logger.info("n_action_switch_rust_set_deviceinfo_succ", method: .local)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoResult, categoryValueMap: ["request_type": "default"], timerStop: .rustSetDeviceInfo, isSuccessResult: true, context: self.monitorContext)


                self.succCallback()
            case .failure(let error):
                //日志和埋点
                self.logger.error("n_action_switch_rust_set_deviceinfo_fail", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoResult, categoryValueMap: ["request_type": "default"], timerStop: .rustSetDeviceInfo, isFailResult: true, context: self.monitorContext, error: error)

                self.failCallback(AccountError.switchUserRustFailed(rawError: error))
            }
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        //set env不回滚，相关回滚逻辑统一放在offline的回滚逻辑里面
        finished(.success(()))
    }
}
