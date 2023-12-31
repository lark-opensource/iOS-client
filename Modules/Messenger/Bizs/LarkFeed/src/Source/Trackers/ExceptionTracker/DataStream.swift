//
//  DataStream.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedDataStreamSubModule: String {
        case pushFeed
        case feedCard
        case authData
        case onscreen
        case render
        case updateFeeds
        case removeFeeds
        case output
        case nextCursor
        case dirtyFeed
        case findUnread
        case filter
    }

    enum FeedDataStreamNode: String {
        case buildFeedCard
        case verifyKey
        case cellForRow
        case diff
        case checkErrorFeeds
        case checkOldFeeds
        case tracklogForOutput
        case isShouldUpdateCursor
        case tryUpdateHighPriorityField
        case updateNextCursor
        case checkFilterType
    }

    struct DataStream {
        static func pushFeed(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .pushFeed, node: node, info: info)
        }

        static func feedCard(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .feedCard, node: node, info: info)
        }

        static func authData(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .authData, node: node, info: info)
        }

        static func onscreen(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .onscreen, node: node, info: info)
        }

        static func render(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .render, node: node, info: info)
        }

        static func updateFeeds(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .updateFeeds, node: node, info: info)
        }

        static func removeFeeds(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .removeFeeds, node: node, info: info)
        }

        static func output(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .output, node: node, info: info)
        }

        static func nextCursor(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .nextCursor, node: node, info: info)
        }

        static func dirtyFeed(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .dirtyFeed, node: node, info: info)
        }

        static func findUnread(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .findUnread, node: node, info: info)
        }

        static func filter(node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .filter, node: node, info: info)
        }

        private static func post(subModule: FeedDataStreamSubModule, node: FeedDataStreamNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.dataStream.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
