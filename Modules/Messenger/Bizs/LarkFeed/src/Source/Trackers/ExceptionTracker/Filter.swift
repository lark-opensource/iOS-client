//
//  Filter.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedFilterSubModule: String {
        case changeTab
        case threeColumns
        case setting
        case fixedTab
        case getSubTabUnreadNum
    }

    enum FeedFilterNode: String {
        case saveFilterEditor
        case changeViewTab
        case removeTab
        case getItemsByTab
        case bind
        case setAvatarImage
        case getSubTabUnreadNum
    }

    struct Filter {
        static func changeTab(node: FeedFilterNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .changeTab, node: node, info: info)
        }

        static func threeColumns(node: FeedFilterNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .threeColumns, node: node, info: info)
        }

        static func setting(node: FeedFilterNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .setting, node: node, info: info)
        }

        static func fixedTab(node: FeedFilterNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .fixedTab, node: node, info: info)
        }

        private static func post(subModule: FeedFilterSubModule, node: FeedFilterNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.filter.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
