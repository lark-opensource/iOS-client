//
//  FeedCard.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedCardSubModule: String {
        case action
        case render
        case batch
    }

    enum FeedCardNode: String {
        case didSelectRow
        case tryShowFilterActionsSheet
        case setAvatarImage
    }

    struct FeedCard {
        static func action(node: FeedCardNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .action, node: node, info: info)
        }

        static func render(node: FeedCardNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .render, node: node, info: info)
        }

        static func batch(node: FeedCardNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .batch, node: node, info: info)
        }

        private static func post(subModule: FeedCardSubModule, node: FeedCardNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.feedcard.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
