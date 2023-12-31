//
//  PSTNModelDefines.swift
//  ByteView
//
//  Created by yangyao on 2020/4/14.
//

import Foundation
import RxDataSources

struct AreaCodeSectionModel<Section, ItemType> {
    var index: Section
    var items: [ItemType]

    init(index: Section, items: [ItemType]) {
        self.index = index
        self.items = items
    }
}

extension AreaCodeSectionModel: SectionModelType {
    init(original: AreaCodeSectionModel<Section, ItemType>, items: [ItemType]) {
        self.index = original.index
        self.items = items
    }
    typealias Item = ItemType
}
