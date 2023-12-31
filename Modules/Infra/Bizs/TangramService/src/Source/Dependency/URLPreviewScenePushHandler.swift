//
//  URLPreviewScenePushHandler.swift
//  TangramService
//
//  Created by Ping on 2023/1/9.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer
import LarkRustClient
import LKCommonsLogging

public struct URLPreviewScenePush: PushMessage {
    public var type: URLPreviewPushType
    public var inlinePreviewEntities: [String: InlinePreviewEntity]
    public var urlPreviewEntities: [String: URLPreviewEntity]
    public var needLazyLoadPreviews: [Url_V1_PushNeedLazyLoadPreview]

    public init(type: URLPreviewPushType,
                inlinePreviewEntities: [String: InlinePreviewEntity],
                urlPreviewEntities: [String: URLPreviewEntity],
                needLazyLoadPreviews: [Url_V1_PushNeedLazyLoadPreview]) {
        self.type = type
        self.inlinePreviewEntities = inlinePreviewEntities
        self.urlPreviewEntities = urlPreviewEntities
        self.needLazyLoadPreviews = needLazyLoadPreviews
    }
}

/// 多场景Push
public final class URLPreviewScenePushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static let logger = Logger.log(URLPreviewScenePushHandler.self, category: "TangramService.URLPreviewScenePushHandler")

    public func process(push message: Url_V1_PushPreviewsRequest) {
        let inlinePreviewEntities = message.previewEntities.mapValues({ InlinePreviewEntity.transform(from: $0) })
        let urlPreviewEntities = message.previewEntities.mapValues({ URLPreviewEntity.transform(from: $0) })
        let push = URLPreviewScenePush(
            type: .sdk,
            inlinePreviewEntities: inlinePreviewEntities,
            urlPreviewEntities: urlPreviewEntities,
            needLazyLoadPreviews: message.needLazyLoadPreviews
        )
        pushCenter?.post(push)
        // swiftlint:disable:next line_length
        let needLazyLoadPreviews = message.needLazyLoadPreviews.map({ "\($0.appID)_\($0.appSceneType)_\($0.previewID)" })
        Self.logger.info("[URLPreview] pushPreviews: entityInfo = \(urlPreviewEntities.mapValues({ $0.tcDescription })) -> inlineInfo = \(inlinePreviewEntities.values.map({ $0.tcDescription })) -> needLazyLoadPreviews = \(needLazyLoadPreviews)")
    }
}
