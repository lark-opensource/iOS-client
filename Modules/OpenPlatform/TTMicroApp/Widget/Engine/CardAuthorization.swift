//
//  CardAuthorization.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/12.
//

import Foundation

//  卡片引擎API权限校验器
@objcMembers
class CardAuthorization: NSObject, BDPJSBridgeAuthorizationProtocol {
    
    /// 卡片API权限校验方法
    /// - Parameters:
    ///   - method: API方法
    ///   - engine: 卡片引擎实体
    ///   - completion: 权限回调
    func checkAuthorization(_ method: BDPJSBridgeMethod?, engine: BDPJSBridgeEngine?, completion: ((BDPAuthorizationPermissionResult) -> Void)? = nil) {
        //  一期权限开放
        completion?(.enabled)
    }
}
