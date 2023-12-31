//
//  InviteStorageService.swift
//  LarkInterface
//
//  Created by zhenning on 2020/04/21.
//

import Foundation
import LarkStorage

/// Messenger业务场景中全局使用的一些邀请相关的存储配置
public struct InviteInfo {
    public let enableShow: Bool
    public let bannerStatus: Int

    public init(enableShow: Bool, bannerStatus: Int) {
        self.enableShow = enableShow
        self.bannerStatus = bannerStatus
    }
}

public enum InviteStorageServiceType: String {
    case feedBanner
}

public protocol InviteStorageService {

    func setInviteInfo<V: KVValue>(value: V, key: KVKey<V>)

    func getInviteInfo<V: KVValue>(key: KVKey<V>) -> V
}
