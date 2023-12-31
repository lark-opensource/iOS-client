//
//  OPLarkCoreLocationMock.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/16.
//

import LarkCoreLocation
import CoreLocation
import Swinject
import LarkAssembler

final class OPMockLocationAuthorizationAssembly: LarkAssemblyInterface {
    public init() {}
    public func registContainer(container: Swinject.Container) {
        container.register(LocationAuthorization.self) { _ in
            OPMockLocationAuthorization()
        }.inObjectScope(.container)
    }
}

final class OPMockLocationAuthorization: LocationAuthorization {
    
    var requestLocationAuthorizationResult: LocationAuthorizationError?
    var checkWhenInUseAuthorizationResult: LocationAuthorizationError?
    /// 精度级别
    func authorizationAccuracy() -> AuthorizationAccuracy {
        AuthorizationAccuracy.full
    }
    /// 系统定位是否可用
    func locationServicesEnabled() -> Bool {
        return true
    }
    /// 目前的定位授权状态
    func authorizationStatus() -> CLAuthorizationStatus {
        return CLAuthorizationStatus.authorizedWhenInUse
    }
    /// 请求APP使用期间的定位权限 在主线程触发 complete 回调
    //    func requestWhenInUseAuthorization(complete: @escaping LocationAuthorizationCallback)
    /// 请求在使用APP期间的定位权限  需要传入敏感API调用Token 在主线程触发 complete 回调
    func requestWhenInUseAuthorization(forToken: PSDAToken, complete: @escaping LocationAuthorizationCallback) {
        DispatchQueue.main.async {
            complete(self.requestLocationAuthorizationResult)
        }
        
    }
    /// 租户管理员是否允许GPS开关
    func isAdminAllowGPS() -> Bool {
        return true
    }
    /// 检验在使用App期间的权限认证包含了 系统定位是否可用 目前的定位授权状态
    func checkWhenInUseAuthorization() -> LocationAuthorizationError? {
        return nil
    }
}
