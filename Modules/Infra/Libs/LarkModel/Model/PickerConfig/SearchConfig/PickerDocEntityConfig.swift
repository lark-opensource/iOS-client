//
//  PickerDocEntityConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/29.
//

import Foundation
import RustPB

typealias SearchContentType = Search_V2_UniversalFilters.DocFilter.SearchContentType

extension RustPB.Basic_V1_Doc.TypeEnum: Codable {}
extension SearchContentType: Codable {}
extension Basic_V1_DocSortRuleType: Codable {}

public extension PickerConfig {
    struct DocEntityConfig: DocEntityConfigType, BelongUserConfigurable, BelongChatConfigurable, Codable {
        public var type: SearchEntityType = .doc
        /// 文档创建者范围
        public var belongUser: BelongUserCondition = .all
        /// 文档群范围
        public var belongChat: BelongChatCondition = .all
        /// 文档查看的时间范围
        public var reviewTimeRange: TimeRangeCondition = .all

        // MARK: - 文档配置
        /// 文档检索类型
        public var types: [Basic_V1_Doc.TypeEnum] = []
        /// 搜索的内容类型
        public var searchContentTypes: [Search_V2_UniversalFilters.DocFilter.SearchContentType] = []
        /// 文档分享者IDs
        public var sharerIds: [String] = []
        /// 来自 = 所有者 + 分享者
        public var fromIds: [String] = []
        /// 排序方式
        public var sortType: Basic_V1_DocSortRuleType = .defaultType
        /// 是否跨语言搜索
        public var crossLanguage: Bool = false
        /// 搜索文件夹内的文档
        public var folderTokens: [String] = []
        /// 扩召回：包括纠错，同义词，向量召回
        public var enableExtendedSearch: Bool
        /// 使用V2版本的扩召回词表
        public var useExtendedSearchV2: Bool

        public var field: DocField?

        public init(belongUser: BelongUserCondition = .all,
                    belongChat: BelongChatCondition = .all,
                    reviewTimeRange: TimeRangeCondition = .all,
                    types: [Basic_V1_Doc.TypeEnum] = [],
                    searchContentTypes: [Search_V2_UniversalFilters.DocFilter.SearchContentType] = [],
                    sharerIds: [String] = [],
                    fromIds: [String] = [],
                    sortType: Basic_V1_DocSortRuleType = .defaultType,
                    crossLanguage: Bool = false,
                    folderTokens: [String] = [],
                    enableExtendedSearch: Bool = false,
                    useExtendedSearchV2: Bool = false,
                    field: DocField? = nil
        ) {
            self.belongUser = belongUser
            self.belongChat = belongChat
            self.reviewTimeRange = reviewTimeRange
            self.types = types
            self.searchContentTypes = searchContentTypes
            self.sharerIds = sharerIds
            self.fromIds = fromIds
            self.sortType = sortType
            self.crossLanguage = crossLanguage
            self.folderTokens = folderTokens
            self.enableExtendedSearch = enableExtendedSearch
            self.useExtendedSearchV2 = useExtendedSearchV2
            self.field = field
        }

        enum CodingKeys: CodingKey {
            case type
            case belongUser
            case belongChat
            case reviewTimeRange
            case types
            case searchContentTypes
            case sharerIds
            case fromIds
            case sortType
            case crossLanguage
            case folderTokens
            case enableExtendedSearch
            case useExtendedSearchV2
            case field
        }

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<PickerConfig.DocEntityConfig.CodingKeys> = try decoder.container(keyedBy: PickerConfig.DocEntityConfig.CodingKeys.self)
            self.type = try container.decode(SearchEntityType.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.type)
            self.belongUser = try container.decode(BelongUserCondition.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.belongUser)
            self.belongChat = try container.decode(BelongChatCondition.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.belongChat)
            self.reviewTimeRange = try container.decode(TimeRangeCondition.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.reviewTimeRange)
            self.types = try container.decode([Basic_V1_Doc.TypeEnum].self, forKey: PickerConfig.DocEntityConfig.CodingKeys.types)
            self.searchContentTypes = try container.decode([Search_V2_UniversalFilters.DocFilter.SearchContentType].self, forKey: PickerConfig.DocEntityConfig.CodingKeys.searchContentTypes)
            self.sharerIds = try container.decode([String].self, forKey: PickerConfig.DocEntityConfig.CodingKeys.sharerIds)
            self.fromIds = try container.decode([String].self, forKey: PickerConfig.DocEntityConfig.CodingKeys.fromIds)
            self.sortType = try container.decode(Basic_V1_DocSortRuleType.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.sortType)
            self.crossLanguage = try container.decode(Bool.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.crossLanguage)
            self.folderTokens = [] // token 是敏感信息
            self.enableExtendedSearch = try container.decode(Bool.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.enableExtendedSearch)
            self.useExtendedSearchV2 = try container.decode(Bool.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.useExtendedSearchV2)
            self.field = try container.decodeIfPresent(PickerConfig.DocField.self, forKey: PickerConfig.DocEntityConfig.CodingKeys.field)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: PickerConfig.DocEntityConfig.CodingKeys.self)
            try container.encode(self.type, forKey: PickerConfig.DocEntityConfig.CodingKeys.type)
            try container.encode(self.belongUser, forKey: PickerConfig.DocEntityConfig.CodingKeys.belongUser)
            try container.encode(self.belongChat, forKey: PickerConfig.DocEntityConfig.CodingKeys.belongChat)
            try container.encode(self.reviewTimeRange, forKey: PickerConfig.DocEntityConfig.CodingKeys.reviewTimeRange)
            try container.encode(self.types, forKey: PickerConfig.DocEntityConfig.CodingKeys.types)
            try container.encode(self.searchContentTypes, forKey: PickerConfig.DocEntityConfig.CodingKeys.searchContentTypes)
            try container.encode(self.sharerIds, forKey: PickerConfig.DocEntityConfig.CodingKeys.sharerIds)
            try container.encode(self.fromIds, forKey: PickerConfig.DocEntityConfig.CodingKeys.fromIds)
            try container.encode(self.sortType, forKey: PickerConfig.DocEntityConfig.CodingKeys.sortType)
            try container.encode(self.crossLanguage, forKey: PickerConfig.DocEntityConfig.CodingKeys.crossLanguage)
            try container.encode(self.enableExtendedSearch, forKey: PickerConfig.DocEntityConfig.CodingKeys.enableExtendedSearch)
            try container.encode(self.useExtendedSearchV2, forKey: PickerConfig.DocEntityConfig.CodingKeys.useExtendedSearchV2)
            try container.encodeIfPresent(self.field, forKey: PickerConfig.DocEntityConfig.CodingKeys.field)
        }
    }
}

extension PickerConfig {
    public struct DocField: Codable {
        public var relationTag: Bool = false
        public init(relationTag: Bool = false) {
            self.relationTag = relationTag
        }
    }
}


