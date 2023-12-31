//
//  File.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/12/22.
//

import Foundation
import RxSwift
import LarkEnv
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer
import LarkReleaseConfig

protocol EnvironmentInterface: AnyObject {
    /// 当前服务环境
    var env: Env { get }
    
    var tenantBrand: TenantBrand { get }

    var tenantGeo: String? { get }

    /// 更新环境、拉取设备信息
    func switchEnvAndUpdateDeviceInfo(
        futureEnv: Env,
        brand: TenantBrand,
        completion: ((SwitchEnvironmentResult) -> Void)?)

    /// 重置环境，回到包环境
    func resetEnv(completion: ((Bool) -> Void)?)

    /// 恢复环境，切换用户错误时回到上一个用户环境
    func recoverEnv(completion: ((Bool) -> Void)?)
}
