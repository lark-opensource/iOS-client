//
//  URLPreviewEntry.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/28.
//

import Foundation
import RustPB
import LarkModel

public struct URLPreviewEntriesBody {
    // key: sourceID
    public var entries: [String: URLPreviewEntries]

    public init(entries: [String: URLPreviewEntries]) {
        self.entries = entries
    }

    public static func transform(from: Url_V1_PushUrlPreviews) -> URLPreviewEntriesBody {
        var entries = [String: URLPreviewEntries]()
        from.urlPreviewEntries.forEach { sourceID, entry in
            let preview = URLPreviewEntries.transform(from: entry)
            entries[sourceID] = preview
        }
        return URLPreviewEntriesBody(entries: entries)
    }

    public var tcDescription: String {
        return entries.flatMap({ $0.value }).flatMap({ $0.entries }).map({ $0.tcDescription }).joined(separator: ";")
    }
}

public struct URLPreviewEntries {
    public var sourceID: String
    public var sourceType: Url_V1_UrlPreviewSourceType
    public var textMD5: String
    public var entries: [URLPreviewEntry]

    public init(sourceID: String,
                sourceType: Url_V1_UrlPreviewSourceType,
                textMD5: String,
                entries: [URLPreviewEntry]) {
        self.sourceID = sourceID
        self.sourceType = sourceType
        self.textMD5 = textMD5
        self.entries = entries
    }

    public static func transform(from: Url_V1_UrlPreviewEntries) -> URLPreviewEntries {
        return URLPreviewEntries(sourceID: from.sourceID,
                                 sourceType: from.sourceType,
                                 textMD5: from.sourceTextMd5,
                                 entries: from.entries.map({ URLPreviewEntry.transform(from: $0) }))
    }

    public static func transform(from: Url_V1_GetUrlPreviewResponse) -> URLPreviewEntries {
        return URLPreviewEntries(sourceID: from.sourceID,
                                 sourceType: from.sourceType,
                                 textMD5: from.sourceTextMd5,
                                 entries: from.previewEntries.map({ URLPreviewEntry.transform(from: $0) }))
    }

    public static func transform(from: Url_V1_MGetUrlPreviewResponse) -> [URLPreviewEntries] {
        return from.resps.map({ URLPreviewEntries.transform(from: $0) })
    }

    public var tcDescription: String {
        return entries.map({ $0.tcDescription }).joined(separator: ";")
    }
}

public struct URLPreviewEntry {
    public var offset: Int
    public var length: Int
    public var previewID: String
    public var entity: URLPreviewEntity

    public init(offset: Int,
                length: Int,
                previewID: String,
                entity: URLPreviewEntity) {
        self.offset = offset
        self.length = length
        self.previewID = previewID
        self.entity = entity
    }

    public static func transform(from: Url_V1_UrlPreviewEntry) -> URLPreviewEntry {
        return URLPreviewEntry(offset: Int(from.offset),
                               length: Int(from.length),
                               previewID: from.previewID,
                               entity: .transform(from: from.previewEntity))
    }

    public var tcDescription: String {
        return "{ offset = \(offset); length = \(length); entityInfo = \(entity.tcDescription) }"
    }
}
