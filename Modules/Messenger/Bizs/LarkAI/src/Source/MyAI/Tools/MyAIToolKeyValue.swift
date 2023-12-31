//
//  MyAIToolKeyValue.swift
//  LarkAI
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation
import LarkStorage
import RustPB

extension KVStores {
    public struct MyAITool {
        public static let domain = Domain.biz.core.child("MyAITool")

        /// 构建用户维度的 `KVStore`
        public static func build(forUser userId: String) -> KVStore {
            return KVStores.udkv(space: .user(id: userId), domain: domain)
        }

        /// 构建进程共享的 `KVStore`
        public static func buildShared() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain, mode: .shared)
        }
    }
}

extension KVKeys {
    public struct MyAITool {
        // model type
        public static let myAIModelType = KVKey("my_ai_tool_model_type", default: true)
    }
}
