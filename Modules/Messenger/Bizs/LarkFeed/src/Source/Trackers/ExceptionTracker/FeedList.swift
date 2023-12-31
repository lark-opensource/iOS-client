//
//  FeedList.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedListSubModule: String {
        case asyncBind
        case findUnread
        case loading
    }

    enum FeedListNode: String {
        case currentFeedCursor
        case getCursor
    }

    struct FeedList {
        static func asyncBind(node: FeedListNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .asyncBind, node: node, info: info)
        }

        static func findUnread(node: FeedListNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .findUnread, node: node, info: info)
        }

        static func loading(node: FeedListNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .loading, node: node, info: info)
        }

        private static func post(subModule: FeedListSubModule, node: FeedListNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.feedlist.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
