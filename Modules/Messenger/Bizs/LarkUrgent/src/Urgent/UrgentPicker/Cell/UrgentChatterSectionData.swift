//
//  UrgentChatterSectionData.swift
//  Action
//
//  Created by 李勇 on 2019/6/7.
//

import Foundation

/// 表格视图，section数据源所具备的基本能力
protocol UrgentChatterSection {
    var title: String? { get }
    var indexKey: String { get }
    var items: [UrgentChatterModel] { get }
    var sectionHeaderClass: AnyClass { get }
}

struct UrgentChatterSectionData: UrgentChatterSection {
    var title: String?
    var indexKey: String
    var items: [UrgentChatterModel]
    var sectionHeaderClass: AnyClass

    init(title: String?,
         indexKey: String? = nil,
         items: [UrgentChatterModel],
         sectionHeaderClass: AnyClass) {
        self.title = title
        self.indexKey = indexKey ?? title ?? ""
        self.items = items
        self.sectionHeaderClass = sectionHeaderClass
    }
}
