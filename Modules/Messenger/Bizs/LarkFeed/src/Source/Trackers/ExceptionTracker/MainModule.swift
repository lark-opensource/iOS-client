//
//  Main.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedMainSubModule: String {
        case life
    }

    enum FeedMainNode: String {
        case objcCount
    }

    struct Main {
        static func life(node: FeedMainNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .life, node: node, info: info)
        }

        private static func post(subModule: FeedMainSubModule, node: FeedMainNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.main.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
