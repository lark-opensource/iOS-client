//
//  URLPreviewAPI.swift
//  TangramService
//
//  Created by 袁平 on 2021/6/22.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import LarkContainer
import LarkRustClient
import LKCommonsLogging

public protocol URLPreviewAPI {
    func getMessagePreviews(
        messagePreviewMap: [String: Im_V1_GetMessagePreviewsRequest.PreviewPair],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePair: InlinePreviewEntityPair, urlPreviewPair: URLPreviewEntityPair, messageLinks: [String: Basic_V1_MessageLink])>

    /// previewIDs need match sourceID
    func getMessagePreviews(
        sourceID: String,
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePair: InlinePreviewEntityPair, urlPreviewPair: URLPreviewEntityPair, messageLinks: [String: Basic_V1_MessageLink])>

    // 根据template id拉取template
    // SDK策略：优先返回本地数据，如果本地缺失数据，从服务端拉取后同本地数据一同返回
    func getUrlPreviewTemplates(templatedIDs: [String]) -> Observable<Url_V1_GetURLPreviewTemplatesByIdsResponse>

    /// generate preview for url
    func generateUrlPreviewEntity(url: String) -> Observable<(inlineEntity: InlinePreviewEntity?, urlPreviewEntity: URLPreviewEntity?)>

    /// get url preview from text
    func getUrlPreviewEntries(requests: [Url_V1_GetUrlPreviewRequest],
                              syncDataStrategy: Basic_V1_SyncDataStrategy) -> Observable<([InlinePreviewEntries], [URLPreviewEntries], UInt64)>

    /// 多场景：获取临时预览
    func getTempPreview(appID: Int64, url: String, appScene: Url_V1_AppScene) -> Observable<(inlineEntity: InlinePreviewEntity?, urlPreviewEntity: URLPreviewEntity?)>

    /// 多场景：获取Inline，用于只接入Inline的业务方
    func getInlinePreview(
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<[String: InlinePreviewEntity]>

    /// 多场景：获取Inline + Card
    /// 不支持获取本地爬虫数据
    func getPreview(
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePreviewEntities: [String: InlinePreviewEntity], urlPreviewEntities: [String: URLPreviewEntity])>

    /// 多场景：拉取inline + card
    /// 获取后端预览和本地爬虫数据，缺失的预览会触发本地爬虫或从后端拉取之后通过URLPreviewScenePush推送给客户端
    /// @params  previewID2SourceIds - 用于决定本地爬虫时URLPreviewEntity里的sourceID，如果客户端不需要sourceID的话可不传
    func getPreviewByHangPoints(
        hangPoints: [Basic_V1_PreviewHangPoint],
        previewID2SourceIds: [String: String]
    ) -> Observable<(inlinePreviewEntities: [String: InlinePreviewEntity], urlPreviewEntities: [String: URLPreviewEntity])>
}

final class RustURLPreviewAPI: URLPreviewAPI {
    static let logger = Logger.log(RustURLPreviewAPI.self, category: "RustURLPreviewAPI")

    private let client: RustService
    init(client: RustService) {
        self.client = client
    }

    private func getRawMessagePreviews(messagePreviewMap: [String: Im_V1_GetMessagePreviewsRequest.PreviewPair],
                                       syncDataStrategy: Basic_V1_SyncDataStrategy) -> Observable<Im_V1_GetMessagePreviewsResponse> {
        var request = Im_V1_GetMessagePreviewsRequest()
        request.messagePreviewMap = messagePreviewMap
        request.syncDataStrategy = syncDataStrategy
        return client.sendAsyncRequest(request)
    }

    func getMessagePreviews(
        messagePreviewMap: [String: Im_V1_GetMessagePreviewsRequest.PreviewPair],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePair: InlinePreviewEntityPair, urlPreviewPair: URLPreviewEntityPair, messageLinks: [String: Basic_V1_MessageLink])> {
        return getRawMessagePreviews(messagePreviewMap: messagePreviewMap, syncDataStrategy: syncDataStrategy).map { response in
            let inlinePair = InlinePreviewEntityPair.transform(from: response)
            let urlPreviewPair = URLPreviewEntityPair.transform(from: response)
            let reqInfo = messagePreviewMap.map({ "\($0.key): \($0.value.previewIds)" }).joined(separator: ";")
            Self.logger.info("[URLPreview] GetMessagePreviewsRequest: requestInfo = { \(reqInfo) } -> inlinesInfo = \(inlinePair.tcDescription) -> entityInfo = \(urlPreviewPair.tcDescription)")
            return (inlinePair, urlPreviewPair, response.messageLinks)
        }
    }

    func getMessagePreviews(
        sourceID: String,
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePair: InlinePreviewEntityPair, urlPreviewPair: URLPreviewEntityPair, messageLinks: [String: Basic_V1_MessageLink])> {
        var pair = Im_V1_GetMessagePreviewsRequest.PreviewPair()
        pair.previewIds = previewIDs
        return getMessagePreviews(messagePreviewMap: [sourceID: pair], syncDataStrategy: syncDataStrategy)
    }

    func getUrlPreviewTemplates(templatedIDs: [String]) -> Observable<Url_V1_GetURLPreviewTemplatesByIdsResponse> {
        var request = Url_V1_GetURLPreviewTemplatesByIdsRequest()
        request.templateIds = templatedIDs
        return client.sendAsyncRequest(request).do(onNext: { response in
            let tcDescription = response.templates.values.map({ $0.tcDescription }).joined(separator: ";")
            Self.logger.info("[URLPreview] GetURLPreviewTemplatesByIdsRequest: templatedIDs = \(templatedIDs); templatesInfo = \(tcDescription)")
        })
    }

    func generateUrlPreviewEntity(url: String) -> Observable<(inlineEntity: InlinePreviewEntity?, urlPreviewEntity: URLPreviewEntity?)> {
        var request = Im_V1_GenerateUrlPreviewEntityRequest()
        request.url = url
        return client.sendAsyncRequest(request).map { (response: Im_V1_GenerateUrlPreviewEntityResponse) in
            guard response.hasPreviewEntity else { return (nil, nil) }
            let inlineEntity = InlinePreviewEntity.transform(from: response.previewEntity)
            var urlPreviewEntity: URLPreviewEntity?
            if response.previewEntity.hasPreviewBody {
                urlPreviewEntity = URLPreviewEntity.transform(from: response.previewEntity)
            }
            return (inlineEntity, urlPreviewEntity)
        }.do(onNext: { inlineEntity, urlPreviewEntity in
            Self.logger.info("[URLPreview] GenerateUrlPreviewEntityRequest: url = \(url.count) -> inlineInfo = \(inlineEntity?.tcDescription) -> entityInfo = \(urlPreviewEntity?.tcDescription)")
        })
    }

    func getUrlPreviewEntries(requests: [Url_V1_GetUrlPreviewRequest],
                              syncDataStrategy: Basic_V1_SyncDataStrategy) -> Observable<([InlinePreviewEntries], [URLPreviewEntries], UInt64)> {
        var request = Url_V1_MGetUrlPreviewRequest()
        request.syncDataStrategy = syncDataStrategy
        request.reqs = requests
        return client.sendAsyncRequest(request).map { (response: Url_V1_MGetUrlPreviewResponse) in
            guard !response.resps.isEmpty else { return ([], [], 0) }
            let inlineEntries = InlinePreviewEntries.transform(from: response)
            let urlEntries = URLPreviewEntries.transform(from: response)
            return (inlineEntries, urlEntries, response.netCostMs)
        }.do(onNext: { inlineEntries, urlEntries, _ in
            let reqInfo = requests.map({ $0.tcDescription}).joined(separator: ";")
            let inlineInfos = inlineEntries.map({ $0.tcDescription }).joined(separator: ";")
            let entityInfos = urlEntries.map({ $0.tcDescription }).joined(separator: ";")
            Self.logger.info("[URLPreview] MGetUrlPreviewRequest: reqInfo = \(reqInfo) -> inlineInfos = \(inlineInfos) -> entityInfos = \(entityInfos)")
        })
    }

    /// 多场景：获取临时预览
    func getTempPreview(appID: Int64, url: String, appScene: Url_V1_AppScene) -> Observable<(inlineEntity: InlinePreviewEntity?, urlPreviewEntity: URLPreviewEntity?)> {
        var request = Url_V1_GetTempPreviewRequest()
        request.appID = appID
        request.url = url
        request.appScene = appScene
        return client.sendAsyncRequest(request).map { (response: Url_V1_GetTempPreviewResponse) in
            guard response.hasPreviewEntity else { return (nil, nil) }
            let inlineEntity = InlinePreviewEntity.transform(from: response.previewEntity)
            var urlPreviewEntity = URLPreviewEntity.transform(from: response.previewEntity)
            return (inlineEntity, urlPreviewEntity)
        }.do(onNext: { inlineEntity, urlPreviewEntity in
            Self.logger.info("[URLPreview] GetTempPreviewRequest: appID = \(appID), url = \(url.count) -> inlineInfo = \(inlineEntity?.tcDescription) -> entityInfo = \(urlPreviewEntity?.tcDescription)")
        })
    }

    func getInlinePreview(
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<[String: InlinePreviewEntity]> {
        var request = Url_V1_GetInlinePreviewRequest()
        request.previewIds = previewIDs
        request.syncDataStrategy = syncDataStrategy
        return client.sendAsyncRequest(request).map { (response: Url_V1_GetInlinePreviewResponse) in
            return response.previewEntityMap.mapValues({ InlinePreviewEntity.transform(from: $0) })
        }.do(onNext: { inlineEntities in
            Self.logger.info("[URLPreview] GetInlinePreviewRequest: previewIDs = \(previewIDs) -> inlineInfo = \(inlineEntities.values.map({ $0.tcDescription }))")
        })
    }

    func getPreview(
        previewIDs: [String],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(inlinePreviewEntities: [String: InlinePreviewEntity], urlPreviewEntities: [String: URLPreviewEntity])> {
        var request = Url_V1_GetPreviewRequest()
        request.previewIds = previewIDs
        request.syncDataStrategy = syncDataStrategy
        return client.sendAsyncRequest(request).map { (response: Url_V1_GetPreviewResponse) in
            let inlinePreviewEntities = response.previewEntityMap.mapValues({ InlinePreviewEntity.transform(from: $0) })
            let urlPreviewEntities = response.previewEntityMap.mapValues({ URLPreviewEntity.transform(from: $0) })
            return (inlinePreviewEntities, urlPreviewEntities)
        }.do(onNext: { (inlineEntities, urlPreviewEntities) in
            Self.logger.info("[URLPreview] GetPreviewRequest: previewIDs = \(previewIDs) -> inlineInfo = \(inlineEntities.values.map({ $0.tcDescription })) -> entityInfo = \(urlPreviewEntities.values.map({ $0.tcDescription }))")
        })
    }

    func getPreviewByHangPoints(
        hangPoints: [Basic_V1_PreviewHangPoint],
        previewID2SourceIds: [String: String]
    ) -> Observable<(inlinePreviewEntities: [String: InlinePreviewEntity], urlPreviewEntities: [String: URLPreviewEntity])> {
        let previewIDs = hangPoints.map { $0.previewID }
        var request = Url_V1_GetPreviewByHangPointsRequest()
        request.previewHangPoints = hangPoints
        request.previewID2SourceIds = previewID2SourceIds
        return client.sendAsyncRequest(request).map { (response: Url_V1_GetPreviewByHangPointsResponse) in
            let inlinePreviewEntities = response.previewEntityMap.mapValues({ InlinePreviewEntity.transform(from: $0) })
            let urlPreviewEntities = response.previewEntityMap.mapValues({ URLPreviewEntity.transform(from: $0) })
            return (inlinePreviewEntities, urlPreviewEntities)
        }.do(onNext: { (inlineEntities, urlPreviewEntities) in
            Self.logger.info("[URLPreview] GetPreviewByHangPointsResponse: previewIDs = \(previewIDs) -> inlineInfo = \(inlineEntities.values.map({ $0.tcDescription })) -> entityInfo = \(urlPreviewEntities.values.map({ $0.tcDescription }))")
        })
    }
}

private extension Basic_V1_URLPreviewTemplate {
    var tcDescription: String {
        return "{ templateID = \(self.templateID); rootComponentID = \(self.rootComponentID); elementsKeys = \(self.elements.keys) }"
    }
}

private extension Url_V1_GetUrlPreviewRequest {
    var tcDescription: String {
        return "{ \(sourceID); \(sourceType.rawValue); \(sourceTextMd5) }"
    }
}
