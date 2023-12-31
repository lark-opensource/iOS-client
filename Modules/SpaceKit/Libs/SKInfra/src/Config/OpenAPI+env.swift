//
//  OpenAPI+env.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/11.
//  从 OpenAPI+Docs 迁移过来

import Foundation
import LarkEnv

public extension OpenAPI {
    
    struct DocsDebugEnv: Hashable {
        
        public static var env: Env = EnvManager.env
        
        public static var current: Env.TypeEnum = env.type
        
        /// 历史遗留的host，不要动这个
        public static var legacyHost: String {
            switch Self.current {
            case .staging:      return "docs-staging.bytedance.net"
            case .preRelease:   return "docs.bytedance.net"
            case .release:      return "docs.bytedance.net"
            @unknown default: fatalError("unknown type")
            }
        }
        
        public static var geckoAccessKey: String {
            switch Self.current {
            case .staging:      return "ded3766bfe7bbc722fb5eb534ad4b11e"
            case .preRelease:   return "170fde123c7a011616dd5e6856ec443b"
            case .release:      return "170fde123c7a011616dd5e6856ec443b"
            @unknown default: fatalError("unknown type")
            }
        }
        
        public static var nameForH5: String {
            switch Self.current {
            case .staging: return "staging"
            case .preRelease: return "prod"
            case .release: return "prod"
            @unknown default: fatalError("unknown type")
            }
        }
        
    }
}
