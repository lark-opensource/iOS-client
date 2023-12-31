//
//  AIFilePath+Base.swift
//  LarkInlineAI
//
//  Created by ByteDance on 2023/5/16.
//

import Foundation
import LarkStorage

extension AIFilePath {
    
    // 全局 inlineAI document 目录 : 相当于 document/Infra/InlineAI
    static var aiGlobalSandboxWithDocument: AIFilePath {
        aiGlobalSandbox(forType: .document)
    }
    
    // 全局 inlineAI library 目录 : 相当于 library/Infra/InlineAI
    static var aiGlobalSandboxWithLibrary: AIFilePath {
        aiGlobalSandbox(forType: .library)
    }
    
    // 全局 inlineAI cache 目录 : 相当于 library/cache/Infra/InlineAI
    static var aiGlobalSandboxWithCache: AIFilePath {
        aiGlobalSandbox(forType: .cache)
    }
    
    // 全局 inlineAI temporary 目录 : 相当于 tmp/Infra/InlineAI
    static var aiGlobalSandboxWithTemporary: AIFilePath {
        aiGlobalSandbox(forType: .temporary)
    }
    
    private static func aiGlobalSandbox(forType type: RootPathType.Normal) -> AIFilePath {
        let path = IsoPath
            .in(space: .global, domain: Domains.Business.infra)
            .build(forType: type, relativePart: "InlineAI")
        return .isoPath(path)
    }
    
}
