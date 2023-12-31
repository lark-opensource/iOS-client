//
//  LarkJSEngineFactory.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2021/12/2.
//

import Foundation

public final class LarkJSEngineFactory {
    public static func createJSEngine(type: LarkJSEngineType) -> LarkJSEngineProtocol {
        switch type {
        case .jsCore:
            return LarkJSCore()
        case .vmsdkJSCore:
            return LarkVmSdkJSEngine(useJSCore: true)
        case .vmsdkQuickJS:
           return LarkVmSdkJSEngine(useJSCore: false)
        }
    }
}
