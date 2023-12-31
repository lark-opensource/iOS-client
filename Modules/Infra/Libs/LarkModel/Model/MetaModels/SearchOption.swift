//
//  SearchOption.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/22.
//

import Foundation
import RustPB

public struct SearchOption: Codable {
    public enum Meta: Codable {
        case chatter(ChatterMeta)
        case chat(ChatMeta)
        case unknown
    }

    public struct ChatterMeta: Codable {
        public var isInTeam: Bool?
    }
    public struct ChatMeta: Codable {
        public var isInTeam: Bool?
    }

    public var id: String
    public var meta: Meta

    public init(id: String, meta: Meta) {
        self.id = id
        self.meta = meta
    }
}

public protocol SearchOptionConvertable {
    func convert(result: Search_V2_SearchResult) -> SearchOption
    func convert(results: [Search_V2_SearchResult]) -> [SearchOption]
}

public extension SearchOptionConvertable {
    func convert(result: Search_V2_SearchResult) -> SearchOption {
        let meta: SearchOption.Meta = {
            switch result.resultMeta.typedMeta {
            case .userMeta(let user):
                var meta = SearchOption.ChatterMeta()
                meta.isInTeam = user.extraFields.isDirectlyInTeam
                return .chatter(meta)
            case .groupChatMeta(let chat):
                var meta = SearchOption.ChatMeta()
                meta.isInTeam = chat.isInTeam
                return .chat(meta)
            @unknown default: return .unknown
            }
        }()

        let option = SearchOption(id: result.id, meta: meta)
        return option
    }

    func convert(results: [Search_V2_SearchResult]) -> [SearchOption] {
        return results.map { convert(result: $0) }
    }
}
