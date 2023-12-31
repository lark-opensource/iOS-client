//
//  LarkSheetMenuViewModel.swift
//  LarkSheetMenu
//
//  Created by liluobin on 2023/5/29.
//

import UIKit
import LKCommonsLogging

class MenuViewModel {

    static let logger = Logger.log(MenuViewModel.self, category: "LarkSheetMenu.MenuViewModel")

    var dataSource: [LarkSheetMenuActionSection] {
        if let section = self._dataSource.first, section.sectionItems.count > 1 {
            var targetSource = self._dataSource
            targetSource.removeFirst()
            /// 去掉宫格数据之后，再过滤空section, 防止UI计算header错误
            return targetSource.filter{ !$0.sectionItems.isEmpty }
        }
        return self._dataSource.filter{ !$0.sectionItems.isEmpty }
    }

    var headerData: [LarkSheetMenuActionItem] {
        if let section = self._dataSource.first, section.sectionItems.count > 1 {
            return section.sectionItems
        }
        return []
    }

    private var _dataSource: [LarkSheetMenuActionSection] {
        return self.dataSourceFetchBlock()
    }

    /// 数据源
    private let dataSourceFetchBlock: (() -> [LarkSheetMenuActionSection])

    init(dataSourceFetchBlock: (@escaping () -> [LarkSheetMenuActionSection])) {
        self.dataSourceFetchBlock = dataSourceFetchBlock
    }
}
