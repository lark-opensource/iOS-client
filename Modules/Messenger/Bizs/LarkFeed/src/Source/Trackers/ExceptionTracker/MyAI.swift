//
//  MyAI.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedMyaiSubModule: String {
        case onboarding
    }

    enum FeedMyaiNode: String {
        case shouldShowAiHeader
    }

    struct MyAI {
        static func onboarding(node: FeedMyaiNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .onboarding, node: node, info: info)
        }

        private static func post(subModule: FeedMyaiSubModule, node: FeedMyaiNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.myai.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
