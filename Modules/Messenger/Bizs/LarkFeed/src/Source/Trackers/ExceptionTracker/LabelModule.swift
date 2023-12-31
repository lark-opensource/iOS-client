//
//  Label.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedLabelSubModule: String {
        case updateChildIndexData
        case updateLabels
        case removeLabel
        case updateFeedEntity
        case removeFeeds
        case updateFeedList
        case createLabel
        case updateLabel
    }

    enum FeedLabelNode: String {
        case indexOutOfRange
        case checkExpiredFeeds
        case checkLocalLabel
        case checkFeedId
        case checkErrorFeeds
        case getChildIndexData
    }

    struct Label {
        static func updateChildIndexData(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateChildIndexData, node: node, info: info)
        }

        static func updateLabels(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateLabels, node: node, info: info)
        }

        static func removeLabel(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .removeLabel, node: node, info: info)
        }

        static func updateFeedEntity(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateFeedEntity, node: node, info: info)
        }

        static func removeFeeds(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .removeFeeds, node: node, info: info)
        }

        static func updateFeedList(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateFeedList, node: node, info: info)
        }

        static func createLabel(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .createLabel, node: node, info: info)
        }

        static func updateLabel(node: FeedLabelNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateLabel, node: node, info: info)
        }

        private static func post(subModule: FeedLabelSubModule, node: FeedLabelNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.label.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
