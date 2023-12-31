//
//  NativeAppAuthorization.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/26.
//

import Foundation
import OPJSEngine
import OPFoundation

@objcMembers
class NativeAppAuthorization: NSObject, BDPJSBridgeAuthorizationProtocol {
    
    /// NativeApp API权限校验方法
    /// - Parameters:
    ///   - method: API方法
    ///   - engine: NativeApp引擎实体
    ///   - completion: 权限回调
    func checkAuthorization(_ method: BDPJSBridgeMethod?, engine: BDPJSBridgeEngine?, completion: ((BDPAuthorizationPermissionResult) -> Void)? = nil) {
        //  一期权限开放
        completion?(.enabled)
    }
}
