//
//  RustClientDependency.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/8/4.
//

import Foundation
import LarkEnv

public protocol PassportRustClientDependency: AnyObject {

    // 使用 user scope 的 rust barrier
    func deployUserBarrier(userID: String, completionHandler: @escaping (@escaping (_ finish: Bool) -> Void) -> Void)
    // rust online
    func makeUserOnline(account: Account, completionHandler: @escaping (Result<Void, Error>) -> Void)
    // rust offline
    func makeUserOffline(completionHandler: @escaping (Result<Void, Error>) -> Void)
    // 更新rust的env信息
    func updateRustEnv(_ env: Env, brand: String, completionHandler: @escaping (Result<Void, Error>) -> Void)
    // 更新rust did，iid
    func updateDeviceInfo(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void)
    // 更新rust did，iid v2, 适配跨租户消息推送，命中时才可以调用
    func updateDeviceInfoV2(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void)
}
