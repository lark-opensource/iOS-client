//
//  InlinePreviewEntity.swift
//  LarkModel
//
//  Created by 袁平 on 2021/6/8.
//

import Foundation
import RustPB

// key: previewID
public typealias InlinePreviewEntityBody = [String: InlinePreviewEntity]

public struct InlinePreviewEntityPair {
    public static var empty: InlinePreviewEntityPair {
        return InlinePreviewEntityPair(inlinePreviewEntities: [:])
    }

    // key: sourceID
    public var inlinePreviewEntities: [String: InlinePreviewEntityBody]

    public init(inlinePreviewEntities: [String: InlinePreviewEntityBody]) {
        self.inlinePreviewEntities = inlinePreviewEntities
    }

    public static func transform(from: Im_V1_PushMessagePreviewsRequest) -> InlinePreviewEntityPair {
        InlinePreviewEntityPair(inlinePreviewEntities: from.previewEntities.mapValues { InlinePreviewEntity.transform(from: $0) })
    }

    public static func transform(from: Im_V1_GetMessagePreviewsResponse) -> InlinePreviewEntityPair {
        InlinePreviewEntityPair(inlinePreviewEntities: from.previewEntities.mapValues { InlinePreviewEntity.transform(from: $0) })
    }

    public var tcDescription: String {
        return inlinePreviewEntities.values.flatMap({ $0.values }).map({ $0.tcDescription }).joined(separator: ";")
    }
}

public struct InlinePreviewEntity {
    public var version: Int32
    public var sourceID: String
    public var previewID: String
    public var title: String?
    public var udIcon: Basic_V1_UDIcon?
    public var imageSetPassThrough: Basic_V1_ImageSetPassThrough?
    public var iconKey: String?
    public var iconUrl: String?
    public var iconImage: UIImage?
    public var tag: String?
    public var url: Basic_V1_URL?
    public var isSDKPreview: Bool
    public var needReload: Bool // 是否需要主动触发拉取
    public var useColorIcon: Bool // Inline中是否使用彩色Icon
    public var unifiedHeader: Basic_V1_UrlPreviewEntity.UnifiedHeader?
    public var extra: [String: Any] = [:] // 额外信息

    public init(version: Int32,
                sourceID: String,
                previewID: String,
                title: String?,
                udIcon: Basic_V1_UDIcon?,
                imageSetPassThrough: Basic_V1_ImageSetPassThrough?,
                iconKey: String?,
                iconUrl: String?,
                iconImage: UIImage?,
                tag: String?,
                url: Basic_V1_URL?,
                isSDKPreview: Bool,
                needReload: Bool,
                useColorIcon: Bool,
                unifiedHeader: Basic_V1_UrlPreviewEntity.UnifiedHeader?,
                extra: [String: Any] = [:]) {
        self.version = version
        self.sourceID = sourceID
        self.previewID = previewID
        self.title = title
        self.udIcon = udIcon
        self.imageSetPassThrough = imageSetPassThrough
        self.iconKey = iconKey
        self.iconUrl = iconUrl
        self.iconImage = iconImage
        self.tag = tag
        self.url = url
        self.isSDKPreview = isSDKPreview
        self.needReload = needReload
        self.useColorIcon = useColorIcon
        self.unifiedHeader = unifiedHeader
        self.extra = extra
    }

    public static func transform(from: Basic_V1_UrlPreviewEntity) -> InlinePreviewEntity {
        return InlinePreviewEntity(version: from.version,
                                   sourceID: from.sourceID,
                                   previewID: from.previewID,
                                   title: from.hasServerTitle ? from.serverTitle : (from.hasSdkTitle ? from.sdkTitle : nil),
                                   udIcon: from.hasUdIcon ? from.udIcon : nil,
                                   imageSetPassThrough: from.hasServerIconImage ? from.serverIconImage : nil,
                                   iconKey: from.hasServerIconKey ? from.serverIconKey : nil,
                                   iconUrl: nil,
                                   iconImage: nil,
                                   // iconUrl: from.hasSdkIconURL ? from.sdkIconURL : nil, // sdk抓取的icon是彩色的，端上染色会变成纯色，此时需用默认占位图
                                   tag: from.hasServerTag ? from.serverTag : nil,
                                   url: from.hasURL ? from.url : nil,
                                   isSDKPreview: from.isSdkPreview,
                                   needReload: from.needReload,
                                   useColorIcon: from.useColorIcon,
                                   unifiedHeader: from.hasUnifiedHeader ? from.unifiedHeader : nil)
    }

    public static func transform(from: Basic_V1_PreviewEntityPair) -> InlinePreviewEntityBody {
        from.previewEntity.mapValues { transform(from: $0) }
    }

    public static func transform(entity: Basic_V1_Entity, pb: Basic_V1_Message) -> [String: InlinePreviewEntity] {
        var inlineEntities = [String: InlinePreviewEntity]()
        for (_, value) in pb.content.urlPreviewHangPointMap {
            if let preview = entity.previewEntities[pb.id]?.previewEntity[value.previewID] {
                let entity = InlinePreviewEntity.transform(from: preview)
                inlineEntities[value.previewID] = entity
            }
        }
        return inlineEntities
    }

    public static func transform(messageLink: Basic_V1_MessageLink, pb: Basic_V1_Message) -> [String: InlinePreviewEntity] {
        var inlineEntities = [String: InlinePreviewEntity]()
        for (_, value) in pb.content.urlPreviewHangPointMap {
            if let preview = messageLink.previewEntities[pb.id]?.previewEntity[value.previewID] {
                let entity = InlinePreviewEntity.transform(from: preview)
                inlineEntities[value.previewID] = entity
            }
        }
        return inlineEntities
    }

    public var tcDescription: String {
        return "{ sourceID = \(sourceID); previewID = \(previewID); title = \(title?.count); tag = \(tag?.count); iosURL = \(url?.ios.count); url = \(url?.url.count) }"
    }
}

public func + (_ left: [String: InlinePreviewEntity], _ right: [String: InlinePreviewEntity]) -> [String: InlinePreviewEntity] {
    var inlines = left
    inlines.merge(right) { old, new in
        // 当version相等时也需要更新：超大群懒加载时，SDKPush的数据和端上主动pull的数据version可能相同
        return new.version >= old.version ? new : old
    }
    return inlines
}

public func += (_ left: inout InlinePreviewEntityBody, _ right: InlinePreviewEntityBody) {
    left.merge(right) { old, new in
        // 当version相等时也需要更新：超大群懒加载时，SDKPush的数据和端上主动pull的数据version可能相同
        return new.version >= old.version ? new : old
    }
}
