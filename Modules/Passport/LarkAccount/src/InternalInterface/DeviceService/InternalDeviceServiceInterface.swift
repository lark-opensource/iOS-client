//
//  DeviceServiceInterface.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/10/21.
//

import Foundation
import LarkAccountInterface

typealias DeviceInfoFetchResult = Result<DeviceInfoTuple, Error>

protocol InternalDeviceServiceProtocol: DeviceService {
    /// 拉取device id
    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void)
    /// 拿到当前所有的 deviceID，unit 作为 key
    func fetchDeviceIDMap() -> [String: String]?
    ///  统一did
    func universalDeviceID() -> String?
    /// 清空deivce id 缓存
    func reset()
    /// 更新device login id
    func updateDeviceLoginId(_ deviceLoginId: String?)
    /// 缓存获取 DeviceID 的 host 和 unit
    func cacheDeviceIDUnit(_ unit: String, with host: String)
}
