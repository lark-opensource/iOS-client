//
//  Subtitles.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public enum FetchOrder: Int, Codable, ModelEnum {
    public static var fallbackValue: FetchOrder = .unknown

    case forward = 1
    case backward = 2
    case unknown = -999
}

public struct Subtitles: Codable {

    public let total: Int
    public let paragraphID: String
    public let size: Int
    public let forward: FetchOrder
    public let hasMore: Bool
    public let version: Int
    public let lastEditVersion: Int
    public let translateLang: String
    public let paragraphs: [Paragraph]

    private enum CodingKeys: String, CodingKey {
        case total = "total"
        case paragraphID = "paragraph_id"
        case size = "size"
        case forward = "forward"
        case hasMore = "has_more"
        case version = "version"
        case lastEditVersion = "last_edit_version"
        case translateLang = "translate_lang"
        case paragraphs = "paragraphs"
    }
}
