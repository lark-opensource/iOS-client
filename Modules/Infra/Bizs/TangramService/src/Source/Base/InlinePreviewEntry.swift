//
//  InlinePreviewEntry.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/28.
//

import Foundation
import RustPB
import LarkModel

public struct InlinePreviewEntriesBody {
    // key: sourceID
    public var entries: [String: InlinePreviewEntries]

    public init(entries: [String: InlinePreviewEntries]) {
        self.entries = entries
    }

    public static func transform(from: Url_V1_PushUrlPreviews) -> InlinePreviewEntriesBody {
        var entries = [String: InlinePreviewEntries]()
        from.urlPreviewEntries.forEach { sourceID, entry in
            let inline = InlinePreviewEntries.transform(from: entry)
            entries[sourceID] = inline
        }
        return InlinePreviewEntriesBody(entries: entries)
    }

    public var tcDescription: String {
        return entries.values.map({ $0.tcDescription }).joined(separator: ";")
    }
}

public struct InlinePreviewEntries {
    public var sourceID: String
    public var sourceType: Url_V1_UrlPreviewSourceType
    public var textMD5: String
    public var entries: [InlinePreviewEntry]

    public init(sourceID: String,
                sourceType: Url_V1_UrlPreviewSourceType,
                textMD5: String,
                entries: [InlinePreviewEntry]) {
        self.sourceID = sourceID
        self.sourceType = sourceType
        self.textMD5 = textMD5
        self.entries = entries
    }

    public static func transform(from: Url_V1_UrlPreviewEntries) -> InlinePreviewEntries {
        return InlinePreviewEntries(sourceID: from.sourceID,
                                    sourceType: from.sourceType,
                                    textMD5: from.sourceTextMd5,
                                    entries: from.entries.map({ InlinePreviewEntry.transform(from: $0) }))
    }

    public static func transform(from: Url_V1_GetUrlPreviewResponse) -> InlinePreviewEntries {
        return InlinePreviewEntries(sourceID: from.sourceID,
                                    sourceType: from.sourceType,
                                    textMD5: from.sourceTextMd5,
                                    entries: from.previewEntries.map({ InlinePreviewEntry.transform(from: $0) }))
    }

    public static func transform(from: Url_V1_MGetUrlPreviewResponse) -> [InlinePreviewEntries] {
        return from.resps.map({ InlinePreviewEntries.transform(from: $0) })
    }

    public var tcDescription: String {
        var entryInfo = ""
        entries.forEach({ entryInfo += $0.tcDescription })
        return "{ sourceType = \(sourceType.rawValue); textMD5 = \(textMD5); entryInfo = \(entryInfo) }"
    }
}

public struct InlinePreviewEntry {
    public var offset: Int
    public var length: Int
    public var previewID: String
    public var inlineEntity: InlinePreviewEntity

    public init(offset: Int,
                length: Int,
                previewID: String,
                inlineEntity: InlinePreviewEntity) {
        self.offset = offset
        self.length = length
        self.previewID = previewID
        self.inlineEntity = inlineEntity
    }

    public static func transform(from: Url_V1_UrlPreviewEntry) -> InlinePreviewEntry {
        return InlinePreviewEntry(offset: Int(from.offset),
                                  length: Int(from.length),
                                  previewID: from.previewID,
                                  inlineEntity: InlinePreviewEntity.transform(from: from.previewEntity))
    }

    public var tcDescription: String {
        return "{ length = \(length); offset = \(offset); inlineInfo = \(inlineEntity.tcDescription) }"
    }
}
