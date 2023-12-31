//
//  PickerWikiEntityConfig.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/29.
//

import Foundation
import RustPB

extension Search_V2_UniversalFilters.WikiFilter.SearchContentType: Codable {}

public extension PickerConfig {
    struct WikiEntityConfig: WikiEntityConfigType, BelongUserConfigurable, BelongChatConfigurable, Codable {
        /// 设置Wiki创建者范围
        public var type: SearchEntityType = .wiki
        public var belongUser: BelongUserCondition = .all
        public var belongChat: BelongChatCondition = .all

        /// 移动端涉及知识库过滤器的搜索 动作为：
        /// 搜索某个知识库 -> 选择知识库（此处需要传入id列表）
        public var repoIds: [String] = []
        /// 最近浏览时间
        public var reviewTimeRange: TimeRangeCondition = .all
        /// wiki 类型
        public var types: [Basic_V1_Doc.TypeEnum] = []
        /// 按指定内容搜索
        public var searchContentTypes: [Search_V2_UniversalFilters.WikiFilter.SearchContentType] = []
        /// 文档分享者IDs
        public var sharerIds: [String] = []
        /// 来自 = 所有者 + 分享者
        public var fromIds: [String] = []
        /// 排序方式
        public var sortType: Basic_V1_DocSortRuleType = .defaultType
        /// 是否跨语言搜索
        public var crossLanguage: Bool
        /// 搜索某个space下的wiki
        public var spaceIds: [String] = []
        /// 使用V2版本的扩召回词表
        public var useExtendedSearchV2: Bool

        public var field: WikiField?

        public init(belongUser: BelongUserCondition = .all,
                    belongChat: BelongChatCondition = .all,
                    repoIds: [String] = [],
                    reviewTimeRange: TimeRangeCondition = .all,
                    types: [Basic_V1_Doc.TypeEnum] = [],
                    searchContentTypes: [Search_V2_UniversalFilters.WikiFilter.SearchContentType] = [],
                    sharerIds: [String] = [],
                    fromIds: [String] = [],
                    sortType: Basic_V1_DocSortRuleType = .defaultType,
                    crossLanguage: Bool = false,
                    spaceIds: [String] = [],
                    useExtendedSearchV2: Bool = false,
                    field: WikiField? = nil
        ) {
            self.belongUser = belongUser
            self.belongChat = belongChat
            self.repoIds = repoIds
            self.reviewTimeRange = reviewTimeRange
            self.types = types
            self.searchContentTypes = searchContentTypes
            self.sharerIds = sharerIds
            self.fromIds = fromIds
            self.sortType = sortType
            self.crossLanguage = crossLanguage
            self.spaceIds = spaceIds
            self.useExtendedSearchV2 = useExtendedSearchV2
            self.field = field
        }
    }
}

extension PickerConfig {
    public struct WikiField: Codable {
        public var relationTag: Bool = false
        public init(relationTag: Bool = false) {
            self.relationTag = relationTag
        }
    }
}
