//   
//  LaunchGuideKeyValue.swift
//  LKLaunchGuide
//
//  Created by 李昊哲 on 2023/1/6.
//  

import Foundation
import LarkStorage

public extension KVStores {
    public struct LaunchGuide {
        static let domain = Domain.biz.core.child("LaunchGuide")

        /// 构建用户无关的 `KVStore`
        public static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }
    }
}

public extension KVKeys {
    struct LaunchGuide {
        public static let show = KVKey("show", default: false)
    }
}
