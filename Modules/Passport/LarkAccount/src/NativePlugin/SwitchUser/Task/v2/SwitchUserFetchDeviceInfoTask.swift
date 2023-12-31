//
//  SwitchUserFetchDidTask.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/9.
//

import Foundation
import LarkAccountInterface
import LarkEnv
import LarkContainer
import LarkSetting
import ECOProbeMeta

class SwitchUserFetchDeviceInfoTask: NewSwitchUserTask {

    var deviceService: SwitchUserDeviceServiceProtocol?

    @Provider private var envManager: EnvironmentInterface

    let serverInfoProvider = ServerInfoProvider()

    override func run() {

        guard let toUser =  switchContext.switchUserInfo,
              let toUnit = toUser.user.unit else {
            logger.error(SULogKey.switchCommon, body: "fetch did task fail with no target userInfo")
            failCallback(AccountError.notFoundTargetUser)
            assertionFailure("something wrong, please contact passport")
            return
        }

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getDeviceInfoStart, timerStart: .getDeviceInfo, context: monitorContext)

        if  PassportStore.shared.universalDeviceServiceUpgraded {
            deviceService = PassportUniversalDeviceService.shared
        } else {
            deviceService = SwitchUserDeviceService(unit: toUnit)
        }

        //更新applog配置
        if toUnit != EnvManager.env.unit {

            func updateAppLogAndFetchDeviceInfo(host: String) {
                //更新applog的did配置
                AppLogIntegrator.updateAppLog(unit: toUnit, host: host)
                //获取deviceInfo
                fetchDeviceinfo()
            }

            //如果已经有对应的域名，直接使用
            if let applogDomain = deviceService?.getDidHost() {
                logger.info(SULogKey.switchCommon, body: "fetch did task already have applogDomain")
                updateAppLogAndFetchDeviceInfo(host: applogDomain)
                return
            }

            logger.info("n_action_switch_rust_get_domain_start", body: "unit: \(toUnit)")

            let toEnv = Env(unit: toUnit, geo: toUser.user.geo, type: envManager.env.type)
            serverInfoProvider.asyncGetDomain(toEnv, brand: toUser.user.tenant.brand.rawValue, key: .ttApplog) { [weak self] domainValue in
                guard let self = self else { return }

                guard let applogDomain = domainValue.value else {
                    self.logger.error("n_action_switch_rust_get_domain_fail", body: "unit: \(toUnit)")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getDeviceInfoResult, timerStop: .getDeviceInfo, isFailResult: true, context: self.monitorContext, error: AccountError.switchUserGetDeviceDomainError)

                    self.failCallback(AccountError.switchUserGetDeviceDomainError)
                    return
                }

                self.logger.info("n_action_switch_rust_get_domain_succ", body: "unit: \(toUnit) host: \(applogDomain)")
                updateAppLogAndFetchDeviceInfo(host: applogDomain)
            }
        } else {
            //直接获取对应unit的did
            fetchDeviceinfo()
        }
    }

    func fetchDeviceinfo() {

        let toUnit = switchContext.switchUserInfo?.user.unit
        logger.info("n_action_switch_did_get_start", body: "unit: \(toUnit)", method: .local)

        //初始化did服务
        deviceService?.fetchDeviceId({ [weak self] result in

            guard let self = self else { return }

            switch result {
            case .success(let deviceInfo):
                self.logger.info(SULogKey.switchCommon, body: "fetch did task succ", method: .local)
                guard DeviceInfo.isDeviceIDValid(deviceInfo.deviceId) else {
                    self.logger.error(SULogKey.switchCommon, body: "fetch did task did invalid")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getDeviceInfoResult, timerStop: .getDeviceInfo,
                                                  isFailResult: true, context: self.monitorContext, error: AccountError.switchUserDeviceInfoError)

                    self.failCallback(AccountError.switchUserDeviceInfoError)
                    return
                }
                self.logger.info("n_action_switch_did_get_succ", body: "did: \(deviceInfo.deviceId) iid: \(deviceInfo.installId)")
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getDeviceInfoResult, timerStop: .getDeviceInfo, isSuccessResult: true, context: self.monitorContext)

                self.switchContext.deviceInfo = deviceInfo
                self.succCallback()
            case .failure(let error):
                //日志和监控
                self.logger.error("n_action_switch_did_get_fail", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getDeviceInfoResult, timerStop: .getDeviceInfo,
                                              isFailResult: true, context: self.monitorContext, error: error)

                self.failCallback(error)
            }
        })
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {

        logger.info("n_action_switch_fetch_did_applog_config_rollback")

        //还原applog为当前域名环境
        AppLogIntegrator.updateAppLog()
        finished(.success(()))
    }
}
