//
//  LocationAuth.swift
//  LarkCoreLocationInterface
//
//  Created by © 2022 Bytedance.Inc. on 3/31/22.
//

import Foundation
import CoreLocation
import LarkSensitivityControl
/// 定位授权回调
public typealias LocationAuthorizationCallback = (LocationAuthorizationError?) -> Void
/// 定位错误
public enum LocationAuthorizationError: Error {
    /// 用户已明确拒绝对此应用程序的授权，或者位置服务在设置中被禁用。此时还未开始定位。
    case denied
    /// 此应用程序无权使用位置服务。用户不能改变状态，可能没有个人拒绝授权。此时还未开始定位。
    case restricted
    /// 定位服务不可用，此时还未开始定位。
    case serviceDisabled
    /// 租户管理员关闭了GPS服务 https://meego.feishu.cn/larksuite/story/detail/4520991?parentUrl=
    case adminDisabledGPS
    /// 用户还未决策此时应该使用 requestWhenInUseAuthorization(complete:) 请求定位权限认证
    case notDetermined
    /// 被PSDA禁用 https://bytedance.feishu.cn/wiki/wikcnA2XpS5GfeGEeJUKoXaxELb
    case psdaRestricted

    public var description: String {
        switch self {
        case .denied:
            return "user denied"
        case .restricted:
            return "user restricted"
        case .serviceDisabled:
            return "location service disabled"
        case .adminDisabledGPS:
            return "admin disabled gps"
        case .notDetermined:
            return "user notDetermined"
        case .psdaRestricted:
            return "psda status restricted"
        }
    }
}

/// location精度级别枚举 「unknown、full、reduced」
public enum AuthorizationAccuracy {
    /// 表示当前iOS版本非iOS14，没有CLAccuracyAuthorization选项
    case unknown
    /// 表示当前为iOS14+，且地图精度为CLAccuracyAuthorizationFullAccuracy
    case full
    /// 表示当前为iOS14+，且地图精度为CLAccuracyAuthorizationReducedAccuracy
    case reduced
}

/// 定位授权相关操作&状态
public protocol LocationAuthorization {
    /// 精度级别
    func authorizationAccuracy() -> AuthorizationAccuracy
    /// 系统定位是否可用
    func locationServicesEnabled() -> Bool
    /// 目前的定位授权状态
    func authorizationStatus() -> CLAuthorizationStatus
    /// 请求APP使用期间的定位权限 在主线程触发 complete 回调
//    func requestWhenInUseAuthorization(complete: @escaping LocationAuthorizationCallback)
    /// 请求在使用APP期间的定位权限  需要传入敏感API调用Token 在主线程触发 complete 回调
    func requestWhenInUseAuthorization(forToken: PSDAToken, complete: @escaping LocationAuthorizationCallback)
    /// 租户管理员是否允许GPS开关
    func isAdminAllowGPS() -> Bool
    /// 检验在使用App期间的权限认证包含了 系统定位是否可用 目前的定位授权状态
    func checkWhenInUseAuthorization() -> LocationAuthorizationError?
}

public extension LocationAuthorization {
    /// 检验APP是否拥有使用app期间的定位权限
    /// 这里会依次检测
    /// 1. 租户管理员是否关闭GPS（adminDisableGPS）https://bytedance.feishu.cn/docx/doxcnv0pTZdEpRC1FrpufOaEMaf。
    /// 2. iOS系统位置服务是否可用
    /// 3. iOS系统对于APP的授权是否为 authorizedAlways 或 authorizedWhenInUse
    func checkWhenInUseAuthorization() -> LocationAuthorizationError? {
        if !isAdminAllowGPS() {
            return .adminDisabledGPS
        }
       return checkWhenInUseAuthorizationWithoutAdminDisableGPS()
    }
    /// 检验APP是否拥有使用app期间的定位权限，
    /// 不包含  租户管理员是否关闭GPS（adminDisableGPS）https://bytedance.feishu.cn/docx/doxcnv0pTZdEpRC1FrpufOaEMaf。
    /// 这里会依次检测
    /// 1. iOS系统位置服务是否可用
    /// 2. iOS系统对于APP的授权是否为 authorizedAlways 或 authorizedWhenInUse
    func checkWhenInUseAuthorizationWithoutAdminDisableGPS() -> LocationAuthorizationError? {
        if !locationServicesEnabled() {
            return .serviceDisabled
        }
        switch authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return nil
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return nil
        }
    }
}
