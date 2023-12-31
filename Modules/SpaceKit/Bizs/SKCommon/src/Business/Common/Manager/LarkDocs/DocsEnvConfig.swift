//
//  DocsEnvConfig.swift
//  SpaceKit
//
//  Created by nine on 2020/2/17.
//

import Foundation

public struct EnvConfig {
    public struct ShouldHideChat: DocsEnvConfigProtocol {
        public typealias Value = Bool
        public static func getValue(environment: DocsEnvironmenKey) -> Bool {
            let openEnvList: [DocsEnvironmenKey] = [.singleProductUserInLarkDocs,
                                                    .standardUserInLarkDocs,
                                                    .larkSimpleUserInLarkDocs]
            return openEnvList.contains(environment)
        }
    }

    public struct CanShowExternalTag: DocsEnvConfigProtocol {
        public typealias Value = Bool
        public static func getValue(environment: DocsEnvironmenKey) -> Bool {
            // 仅套件企业版用户才会显示外部标签
            let openEnvList: [DocsEnvironmenKey] = [.standardUserInLarkDocs, .standardUserInLark]
            return openEnvList.contains(environment)
        }
    }
}
