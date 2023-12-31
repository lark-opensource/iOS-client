//
//  ActivityRecordViewData.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/30.
//

import Foundation

struct ActivityRecordSectionData {

    enum ItemType {
        case content(ActivityRecordContentData)
        case combine(ActivityRecordCombineData)

        var itemHeight: CGFloat? {
            switch self {
            case .content(let data): return data.itemHeight
            case .combine(let data): return data.itemHeight
            }
        }

        var metaData: Rust.ActivityRecord? {
            switch self {
            case .content(let data): return data.metaData
            case .combine: return nil
            }
        }

        var guid: String {
            switch self {
            case .content(let data): return data.guid
            case .combine(let data): return data.guid
            }
        }

        func preferredHeight(maxWidth: CGFloat) -> CGFloat {
            switch self {
            case .content(let data): return data.preferredHeight(maxWidth: maxWidth)
            case .combine(let data): return data.preferredHeight(maxWidth: maxWidth)
            }
        }

        mutating func updateCacheHeight(_ height: CGFloat) {
            switch self {
            case .content(var data):
                data.itemHeight = height
                self = .content(data)
            case .combine(var data):
                data.itemHeight = height
                self = .combine(data)
            }
        }
    }

    var header = ActivityRecordSectionHeaderData()

    var items = [ItemType]()

    // 分组
    var sectionID: String = UUID().uuidString

}

extension ActivityRecordSectionData {

    static func safeCheck(indexPath: IndexPath, with sections: [ActivityRecordSectionData]) -> (section: Int, row: Int)? {
        guard !sections.isEmpty else {
            ActivityRecord.logger.error("sections is empty")
            return nil
        }
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0 && section < sections.count else {
            ActivityRecord.logger.error("out of section. cur: \(section), total: \(sections.count)")
            return nil
        }
        guard !sections[section].items.isEmpty else {
            ActivityRecord.logger.error("items is empty")
            return nil
        }
        guard row >= 0 && row < sections[section].items.count else {
            ActivityRecord.logger.error("out of items. cur: \(row), total: \(sections[section].items.count)")
            return nil
        }
        return (section, row)
    }

    static func safeCheck(section: Int, with sections: [ActivityRecordSectionData]) -> Int? {
        guard !sections.isEmpty else { return nil }
        guard section >= 0 && section < sections.count else { return nil }
        return section
    }

}
