//
//  URLPreviewPushHandler.swift
//  TangramService
//
//  Created by 袁平 on 2021/6/9.
//

import Foundation
import LarkRustClient
import RustPB
import LarkModel
import LarkContainer
import LKCommonsLogging

// Template 数据来源
public enum URLPreviewTemplatePushSourceType {
    case message /// 消息场景
    case widget /// 群 widget 场景
    case pinCard /// New Pin
}

public struct URLPreviewTemplatePush: PushMessage {
    public var templates: [String: Basic_V1_URLPreviewTemplate]
    // sourceID: templateIDs
    public var missingTemplateIDs: [String: Set<String>]
    public let sourceType: URLPreviewTemplatePushSourceType

    public init(templates: [String: Basic_V1_URLPreviewTemplate] = [:],
                missingTemplateIDs: [String: Set<String>] = [:],
                sourceType: URLPreviewTemplatePushSourceType) {
        self.templates = templates
        self.missingTemplateIDs = missingTemplateIDs
        self.sourceType = sourceType
    }
}

// Push数据来源
public enum URLPreviewPushType {
    case sdk // SDK Push数据
    case client // 端上主动拉取的数据
}

public struct URLPreviewPush: PushMessage {
    public var type: URLPreviewPushType
    public var inlinePreviewEntityPair: InlinePreviewEntityPair
    public var urlPreviewEntityPair: URLPreviewEntityPair
    public var messageLinks: [String: Basic_V1_MessageLink] // key: previewID
    public var needLoadIDs: [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]

    public init(type: URLPreviewPushType,
                inlinePreviewEntityPair: InlinePreviewEntityPair,
                urlPreviewEntityPair: URLPreviewEntityPair,
                messageLinks: [String: Basic_V1_MessageLink],
                needLoadIDs: [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]) {
        self.type = type
        self.inlinePreviewEntityPair = inlinePreviewEntityPair
        self.urlPreviewEntityPair = urlPreviewEntityPair
        self.messageLinks = messageLinks
        self.needLoadIDs = needLoadIDs
    }
}

public final class URLPreviewPushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static let logger = Logger.log(URLPreviewPushHandler.self, category: "TangramService.URLPreviewPushHandler")

    public func process(push message: Im_V1_PushMessagePreviewsRequest) throws {
        let inlineEntityPair = InlinePreviewEntityPair.transform(from: message)
        let urlPreviewEntityPair = URLPreviewEntityPair.transform(from: message)
        let push = URLPreviewPush(type: .sdk,
                                  inlinePreviewEntityPair: inlineEntityPair,
                                  urlPreviewEntityPair: urlPreviewEntityPair,
                                  messageLinks: message.messageLinks,
                                  needLoadIDs: message.needLoadIds)
        pushCenter?.post(push)
        // swiftlint:disable:next line_length
        Self.logger.info("[URLPreview] pushMessagePreviews: entityInfo = \(urlPreviewEntityPair.tcDescription) -> inlineInfo = \(inlineEntityPair.tcDescription) -> needLoadIds = \(message.needLoadIds.mapValues({ $0.previewIds }))")
    }
}
