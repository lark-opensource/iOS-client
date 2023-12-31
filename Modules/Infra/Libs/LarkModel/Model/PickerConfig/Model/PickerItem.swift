//
//  PickerItem.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/28.
//

import Foundation
import RustPB

/// Picker的数据来源
public enum PickerItemCategory: String, Codable {
    /// 搜索
    case search
    /// 我管理的群里
    case ownedGroup
    /// 外部联系人
    case external
    /// 部门
    case organization
    /// 关联组织
    case relatedOrganization
    /// 邮箱联系人
    case emailContact
    /// 大搜结果空搜推荐内容
    case emptySearch
    /// 近期访问
    case recentVisit
    case unknown
}


public protocol PickerItemMetaType {
    var id: String { get set }
}

public struct PickerItem: CustomStringConvertible {
    public var category: PickerItemCategory = .unknown
    public var meta: Meta
    public var renderData: RenderData?

    /// 包含的直接渲染信息, 目前仅用于大搜
    public struct RenderData {
        public var title: String?
        public var summary: String?
        public var titleHighlighted: NSAttributedString?
        public var summaryHighlighted: NSAttributedString?
        public var extrasHighlighted: String?
        public var explanationTags: [RustPB.Search_V2_ExplanationTag]?
        public var extraInfos: [RustPB.Search_V2_ExtraInfoBlock]?
        public var extraInfoSeparator: String?
        public var renderData: String?
        public init(
            title: String? = nil,
            summary: String? = nil,
            titleHighlighted: NSAttributedString? = nil,
            summaryHighlighted: NSAttributedString? = nil,
            extrasHighlighted: String? = nil,
            explanationTags: [RustPB.Search_V2_ExplanationTag]? = nil,
            extraInfos: [RustPB.Search_V2_ExtraInfoBlock]? = nil,
            extraInfoSeparator: String? = nil,
            renderData: String? = nil) {
                self.title = title
                self.summary = summary
                self.titleHighlighted = titleHighlighted
                self.summaryHighlighted = summaryHighlighted
                self.extrasHighlighted = extrasHighlighted
                self.explanationTags = explanationTags
                self.extraInfos = extraInfos
                self.extraInfoSeparator = extraInfoSeparator
                self.renderData = renderData
            }
    }

    public init(meta: PickerItem.Meta, category: PickerItemCategory = .unknown) {
        self.category = category
        self.meta = meta
    }

    public static func empty() -> Self {
        return PickerItem(meta: .unknown)
    }

    public var id: String {
        switch self.meta {
        case .chatter(let i):
            return i.id
        case  .chat(let i):
            return i.id
        case .userGroup(let i):
            return i.id
        case .doc(let i):
            return i.id
        case .wiki(let i):
            return i.id
        case .wikiSpace(let i):
            return i.id
        case .mailUser(let i):
            return i.id
        default: return ""
        }
    }

    public var description: String {
        switch meta {
        case .chatter(let i):
            return "{chatter: {id: \(id)}}"
        case .chat(let i):
            return "{chat: {id: \(id)}}"
        case .doc(_):
            return "{doc}"
        case .wiki(_):
            return "{wiki}"
        case .wikiSpace(let i):
            return "{wikiSpace: {id: \(id)}}"
        case .mailUser(let i):
            return "{mailUser: {id: \(id)}}"
        default:
            return "unknown"
        }
    }
}

extension PickerItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PickerItem.CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let type = try container.decode(PickerItem.MetaType.self, forKey: .type)
        switch type {
        case .chatter:
            self.meta = .chatter(.init(id: id))
        case .chat:
            self.meta = .chat(.init(id: id, type: .group))
        default:
            self.meta = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.meta.type, forKey: .type)
    }
}
