//
//  File.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/22.
//

import Foundation
import RustPB

public extension Basic_V1_TagData {
    static func transform(tagDataItems: [Basic_V1_TagData.TagDataItem]) -> [LarkBizTag.TagDataItem] {
        guard !tagDataItems.isEmpty else { return [] }
        var bizTags: [LarkBizTag.TagDataItem] = []
        tagDataItems.forEach { item in
            bizTags.append(item.transform())
        }
        return bizTags
    }

    func transform() -> [LarkBizTag.TagDataItem] {
        return Basic_V1_TagData.transform(tagDataItems: self.tagDataItems)
    }
}

public extension Basic_V1_TagData.TagDataItem {
    func transform() -> LarkBizTag.TagDataItem {
        return LarkBizTag.TagDataItem(text: self.textVal,
                                      tagType: self.respTagType.transform(),
                                      priority: Int(self.priority))
    }
}

public extension Search_V2_TagData {
    func transform() -> [LarkBizTag.TagDataItem] {
        guard !tagDataItems.isEmpty else { return [] }
        var bizTags: [LarkBizTag.TagDataItem] = []
        self.tagDataItems.forEach { item in
            let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                     tagType: item.respTagType.transform())
            bizTags.append(tagDataItem)
        }
        return bizTags
    }

    func toBasicTagData() -> Basic_V1_TagData {
        var basicTagData = Basic_V1_TagData()
        for tagData in self.tagDataItems {
            var item = Basic_V1_TagData.TagDataItem()
            item.textVal = tagData.textVal
            item.tagID = tagData.tagID
            switch tagData.respTagType {
            case .relationTagPartner:
                item.respTagType = .relationTagPartner
            case .relationTagExternal:
                item.respTagType = .relationTagExternal
            case .relationTagTenantName:
                item.respTagType = .relationTagTenantName
            case .relationTagUnset:
                item.respTagType = .relationTagUnset
            default: break
            }
            basicTagData.tagDataItems.append(item)
        }
        return basicTagData
    }
}

public extension Basic_V1_ResponseTagTypeEnum {
    func transform() -> TagType {
        switch self {
            /// B2B 关联企业
        case .relationTagPartner: return .relation
            /// 企业名称标签
        case .relationTagTenantName: return .organization
            /// 外部标签
        case .relationTagExternal: return .external
            /// 未知标签，默认为「外部」
        case .relationTagUnset: return .unKnown
            /// 租户标签
        case .tenantEntityTag: return .tenantTag
        default: return .unKnown
        }
    }
}

public extension Search_V2_ResponseTagTypeEnum {
    func transform() -> TagType {
        switch self {
            /// B2B 关联企业
        case .relationTagPartner: return .relation
            /// 企业名称标签
        case .relationTagTenantName: return .organization
            /// 外部标签
        case .relationTagExternal: return .external
            /// 未知标签，默认为「外部」
        case .relationTagUnset: return .unKnown

        default: return .unKnown
        }
    }
}
