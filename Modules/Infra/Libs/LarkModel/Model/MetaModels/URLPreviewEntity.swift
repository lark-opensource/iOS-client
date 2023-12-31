//
//  URLPreviewEntity.swift
//  LarkModel
//
//  Created by 袁平 on 2021/6/10.
//

import Foundation
import RustPB

// key: previewID
public typealias URLPreviewEntityBody = [String: URLPreviewEntity]

public struct URLPreviewEntityPair {
    // key: sourceID
    public var urlPreviewEntities: [String: URLPreviewEntityBody]

    public init(urlPreviewEntities: [String: URLPreviewEntityBody]) {
        self.urlPreviewEntities = urlPreviewEntities
    }

    public static func transform(from: Im_V1_PushMessagePreviewsRequest) -> URLPreviewEntityPair {
        URLPreviewEntityPair(urlPreviewEntities: from.previewEntities.mapValues { URLPreviewEntity.transform(from: $0) })
    }

    public static func transform(from: Im_V1_GetMessagePreviewsResponse) -> URLPreviewEntityPair {
        URLPreviewEntityPair(urlPreviewEntities: from.previewEntities.mapValues { URLPreviewEntity.transform(from: $0) })
    }

    public var tcDescription: String {
        var descriptions = ""
        for (_, entities) in urlPreviewEntities {
            for (_, entity) in entities {
                descriptions += entity.tcDescription
            }
        }
        return "\(descriptions)"
    }
}

public struct URLPreviewEntity: Equatable {
    public var version: Int32
    public var sourceID: String
    public var previewID: String
    public var appInfo: Basic_V1_UrlPreviewEntity.AppInfo
    public var url: Basic_V1_URL
    public var isLocalPreview: Bool // 是否是本地预览
    public var isOldPreview: Bool // 是否是未接入URL中台的预览，等旧预览下掉之后可去除该字段
    public var needReload: Bool // 是否需要主动触发拉取
    public var renderRouter: Basic_V1_RenderRouterEntity? // 多引擎渲染
    public var previewBody: Basic_V1_URLPreviewBody? // URL中台自建引擎
    public var localPreviewBody: URLLocalPreviewBody? // 本地爬虫
    // 本地构造的template，用于兼容旧版本的Components结构和本地抓取预览
    public var localTemplates: [String: Basic_V1_URLPreviewTemplate] = [:]

    public init(version: Int32,
                sourceID: String,
                previewID: String,
                appInfo: Basic_V1_UrlPreviewEntity.AppInfo,
                url: Basic_V1_URL,
                isLocalPreview: Bool,
                isOldPreview: Bool,
                needReload: Bool,
                renderRouter: Basic_V1_RenderRouterEntity?,
                previewBody: Basic_V1_URLPreviewBody?,
                localPreviewBody: URLLocalPreviewBody?) {
        self.version = version
        self.sourceID = sourceID
        self.previewID = previewID
        self.appInfo = appInfo
        self.url = url
        self.isLocalPreview = isLocalPreview
        self.isOldPreview = isOldPreview
        self.needReload = needReload
        self.renderRouter = renderRouter
        self.previewBody = previewBody
        self.localPreviewBody = localPreviewBody
    }

    public static func transform(from: Basic_V1_UrlPreviewEntity) -> URLPreviewEntity {
        return URLPreviewEntity(version: from.version,
                                sourceID: from.sourceID,
                                previewID: from.previewID,
                                appInfo: from.appInfo,
                                url: from.url,
                                isLocalPreview: from.isSdkPreview,
                                isOldPreview: false,
                                needReload: from.needReload,
                                renderRouter: from.hasRenderRouterEntity ? from.renderRouterEntity : nil,
                                previewBody: from.hasPreviewBody ? from.previewBody : nil,
                                localPreviewBody: from.isSdkPreview ? URLLocalPreviewBody.transform(from: from) : nil)
    }

    public static func transform(from: Message) -> [String: URLPreviewEntity]? {
        var urlPreviews: [PreviewUrlContent] = []
        if from.type == .text, let content = from.content as? TextContent {
            urlPreviews = content.previewUrls
        } else if from.type == .post, let content = from.content as? PostContent {
            urlPreviews = content.previewUrls
        }
        // 判断条件和老的URL预览保持一致
        let uniquePreviewUrls = urlPreviews.map({ $0.url }).lf_unique(by: { $0 })
        // 多个不同url不展示预览(多个相同url不算)且url未隐藏预览且title非空
        guard uniquePreviewUrls.count == 1, let urlContent = urlPreviews.first, !urlContent.isHidden, !urlContent.title.isEmpty else { return nil }
        var url = Basic_V1_URL()
        url.url = urlContent.url
        let localPreviewBody = URLLocalPreviewBody(faviconUrl: urlContent.icon.thumbnail.urls.first ?? urlContent.icon.origin.urls.first,
                                                   iconUrl: nil,
                                                   title: urlContent.title,
                                                   description: urlContent.summary,
                                                   domain: URL(string: urlContent.url)?.host ?? urlContent.url,
                                                   iframeUrl: urlContent.videoInfo.hasIframeURL ? urlContent.videoInfo.iframeURL : nil,
                                                   siteName: nil,
                                                   siteType: .unknown,
                                                   videoID: urlContent.videoInfo.hasVid ? urlContent.videoInfo.vid : nil,
                                                   cardURL: url)
        // 卡片支持关闭后，previewID需要唯一，未接入中台的只有单url时展示卡片，此处暂时用messageID替代
        let previewID = "LocalPreview_\(from.id)"
        let entity =  URLPreviewEntity(version: 0,
                                       sourceID: from.id,
                                       previewID: previewID,
                                       appInfo: Basic_V1_UrlPreviewEntity.AppInfo(),
                                       url: url,
                                       isLocalPreview: true,
                                       isOldPreview: true,
                                       needReload: false,
                                       renderRouter: nil,
                                       previewBody: nil,
                                       localPreviewBody: localPreviewBody)
        return [previewID: entity]
    }

    public static func transform(from: Basic_V1_PreviewEntityPair) -> URLPreviewEntityBody {
        return from.previewEntity.mapValues { transform(from: $0) }
    }

    // swiftlint:disable line_length
    public var tcDescription: String {
        return "{ sourceID = \(sourceID); previewID = \(previewID); isLocalPreview = \(isLocalPreview); isOldPreview = \(isOldPreview); needReload = \(needReload); version = \(version); previewBodyInfo = \(previewBody?.tcDescription); renderRouterInfo = \(renderRouter?.tcDescription) }"
    }
    // swiftlint:enable line_length
}

public struct URLLocalPreviewBody: Equatable {
    public var faviconUrl: String?
    public var iconUrl: String?
    public var title: String
    public var description: String
    public var domain: String
    public var iframeUrl: String?
    // 网站名称
    public var siteName: String?
    // 网站类型，视频播放时使用
    public var siteType: Basic_V1_URLPreviewComponent.VideoProperty.Site
    // YouTube等需要video_id
    public var videoID: String?
    public var cardURL: Basic_V1_URL?

    public init(faviconUrl: String?,
                iconUrl: String?,
                title: String,
                description: String,
                domain: String,
                iframeUrl: String?,
                siteName: String?,
                siteType: Basic_V1_URLPreviewComponent.VideoProperty.Site,
                videoID: String?,
                cardURL: Basic_V1_URL?) {
        self.faviconUrl = faviconUrl
        self.iconUrl = iconUrl
        self.title = title
        self.description = description
        self.domain = domain
        self.iframeUrl = iframeUrl
        self.siteName = siteName
        self.siteType = siteType
        self.videoID = videoID
        self.cardURL = cardURL
    }

    public static func transform(from: Basic_V1_UrlPreviewEntity) -> URLLocalPreviewBody {
        return URLLocalPreviewBody(faviconUrl: from.hasSdkFaviconURL ? from.sdkFaviconURL : nil,
                                   iconUrl: from.hasSdkIconURL ? from.sdkIconURL : nil,
                                   title: from.sdkTitle,
                                   description: from.sdkDescription,
                                   domain: from.sdkDomain,
                                   iframeUrl: from.hasSdkIframeURL ? from.sdkIframeURL : nil,
                                   siteName: from.hasSdkSiteName ? from.sdkSiteName : nil,
                                   siteType: from.sdkSiteType,
                                   videoID: from.hasSdkVideoID ? from.sdkVideoID : nil,
                                   cardURL: from.url)
    }
}

extension Sequence {
    /// deduplicate Element by same identity, keep order and first Element
    func lf_unique<T: Hashable>(by identity: (Element) throws -> T) rethrows -> [Element] {
        var saw = Set<T>(minimumCapacity: self.underestimatedCount)
        return try self.filter { saw.insert( try identity($0) ).inserted }
    }
}

extension Basic_V1_URLPreviewBody {
    var tcDescription: String {
        let statesInfo = states.map({ "\($0.key) = { \($0.value.tcDescription) }" })
        return "{ componentsCount = \(components.elements.count); currentStateID = \(currentStateID); statesInfo = \(statesInfo) }"
    }
}

extension Basic_V1_URLPreviewState {
    var tcDescription: String {
        return "{ templateID = \(templateID) }"
    }
}

extension Basic_V1_RenderRouterEntity {
    var tcDescription: String {
        return "{ componentsCount = \(elements.count); engineEntityCount = \(engineEntities.count) }"
    }
}

public func += (_ left: inout URLPreviewEntityBody, _ right: URLPreviewEntityBody) {
    left.merge(right) { old, new in
        // 当version相等时也需要更新：超大群懒加载时，SDKPush的数据和端上主动pull的数据version可能相同
        return new.version >= old.version ? new : old
    }
}
