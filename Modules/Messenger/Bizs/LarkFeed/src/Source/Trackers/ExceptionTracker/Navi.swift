//
//  Navi.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedNaviSubModule: String {
        case push
        case action
        case syncStatus
    }

    enum FeedNaviNode: String {
        case onDefaultAvatarTapped
        case loadFeed
    }

    struct Navi {
        static func push(node: FeedNaviNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .push, node: node, info: info)
        }

        static func action(node: FeedNaviNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .action, node: node, info: info)
        }

        static func syncStatus(node: FeedNaviNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .syncStatus, node: node, info: info)
        }

        private static func post(subModule: FeedNaviSubModule, node: FeedNaviNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.navi.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
