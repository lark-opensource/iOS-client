//
//  KaPassportImpl.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/2/23.
//

import Foundation

#if canImport(LKPassportExternalAssembly)
import LKPassportExternal
import LarkContainer
import LarkAccountInterface

class KaPassportImpl: KAPassportProtocol {
    
    @Provider var deviceService: DeviceService
    @Provider var sessionService: UserSessionService
    
    /// 获取飞书设备唯一表示
    /// - Returns: device id
    func getDeviceId() -> String {
        deviceService.deviceId
    }
    
    /// 检查飞书当前用户的登录状态
    /// - Parameter onSuccess: 接口调用成功，block 返回值：登录态是否有效和额外说明
    /// - Parameter onFail: 接口调用成功，block 返回值：失败原因
    func checkLarkStatus(onSuccess: @escaping (Bool, String?) -> Void, onFail: @escaping(String) -> Void) {
        sessionService.checkForegroundUserSessionIsValid(onSuccess: onSuccess, onFail: onFail)
    }
}
#endif
