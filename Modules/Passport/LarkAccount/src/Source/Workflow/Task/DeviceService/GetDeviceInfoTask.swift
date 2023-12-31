//
//  GetDeviceInfoTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation
import LarkEnv
import LarkAccountInterface

func getDeviceInfoTask(context: UniContextProtocol) -> Task<(Env, TenantBrand), DeviceInfoTuple, Error> {

    Task { env in

        let toUnit = env.0.unit

        let deviceService: SwitchUserDeviceServiceProtocol
        if  PassportStore.shared.universalDeviceServiceUpgraded {
            deviceService = PassportUniversalDeviceService.shared
        } else {
            deviceService = SwitchUserDeviceService(unit: toUnit)
        }

        func internalGetDeviceInfoTask() -> Task<String, DeviceInfoTuple, Error> {
            Task { host in
                return SideEffect { successCallback, failCallback in
                    //监控
                    PassportMonitor.flush(PassportMonitorMetaMonad.getDeviceInfoStart, context: context)

                    //更新applog的did配置
                    AppLogIntegrator.updateAppLog(unit: toUnit, host: host)
                    //获取统一did
                    deviceService.fetchDeviceId({ result in
                        switch result {
                        case .success(let deviceInfo):
                            //监控：成功
                            PassportMonitor.monitor(PassportMonitorMetaMonad.getDeviceInfoResult, context: context).setResultTypeSuccess()

                            successCallback(deviceInfo)
                        case .failure(let error):
                            //监控：失败
                            PassportMonitor.monitor(PassportMonitorMetaMonad.getDeviceInfoResult, context: context, error: error).setResultTypeFail()

                            failCallback(error)
                        }
                    })
                }
            } rollback: { _ in
                return SideEffect(success: ())
            }
        }

        return (getApplogDeviceRegistHostTask(context: context) --> internalGetDeviceInfoTask()).runnable(env)

    } rollback: { _ in
        //回滚applog deviceRegister 域名配置，回滚到前台用户环境的配置
        AppLogIntegrator.updateAppLog()
        return SideEffect(success: ())
    }
}

//获取设备注册域名
private func getApplogDeviceRegistHostTask(context: UniContextProtocol) -> Task<(Env, TenantBrand), String, Error> {

    Task { env in

        let toUnit = env.0.unit

        let deviceService: SwitchUserDeviceServiceProtocol
        if  PassportStore.shared.universalDeviceServiceUpgraded {
            deviceService = PassportUniversalDeviceService.shared
        } else {
            deviceService = SwitchUserDeviceService(unit: toUnit)
        }

        if let deviceRegisterHost = deviceService.getDidHost() {
            return SideEffect(success: deviceRegisterHost)
        } else {
            return asyncGetDomainTask(context: context).runnable((env,.ttApplog))
        }

    } rollback: { _ in
        return SideEffect(success:())
    }
}
