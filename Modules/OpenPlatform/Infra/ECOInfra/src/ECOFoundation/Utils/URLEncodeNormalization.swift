//
//  URLEncodeNormalization.swift
//  ECOInfra
//
//  Created by zhaojingxin on 2022/9/27.
//

import Foundation
import LarkSetting
import LarkContainer

public final class URLEncodeNormalization {
    
    public enum Scene: String {
        case api_openSchema
        case api_mailTo
    }
    
    private let resolver: UserResolver
    public init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    private lazy var config: Set<String> = {
        do {
            let config = try resolver.settings.setting(with: [String].self, key: .make(userKeyLiteral: "opURLEncodeNormalization"))
            return Set(config)
        } catch {
            return []
        }
    }()
    
    public func enabled(in scene: Scene) -> Bool {
        return config.contains(scene.rawValue)
    }
}
