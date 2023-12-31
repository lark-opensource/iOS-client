//
//  Tabbar.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedTabbarSubModule: String {
        case tabBadge
    }

    enum FeedTabbarNode: String {
        case updateBadge
    }

    struct Tabbar {
        static func tabBadge(node: FeedTabbarNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .tabBadge, node: node, info: info)
        }

        private static func post(subModule: FeedTabbarSubModule, node: FeedTabbarNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.tabbar.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
