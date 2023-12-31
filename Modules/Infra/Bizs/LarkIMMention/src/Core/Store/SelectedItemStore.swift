//
//  SelectedItemStore.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/30.
//

import UIKit
import Foundation
import RxSwift

class SelectedItemStore {
    var selectedItems: [IMMentionOptionType] = []
    var selectedCache: [String: Int] = [:]
    var items = ReplaySubject<[IMMentionOptionType]>.create(bufferSize: 1)
    
    
    var isMultiSelected: Bool = false
    
    var didUpdateSelectedItems: (([IMMentionOptionType], [String: Int]) -> Void)?
    
    func toggleMultiSelected(isOn: Bool) {
        isMultiSelected = isOn
    }
    
    func toggleItemSelected(item: IMMentionOptionType) {
        // 单选
        guard isMultiSelected else {
            selectedItems = [item]
            return
        }
        // 多选
        guard let itemId = item.id else { return }
        let isSelected = selectedCache[itemId] != nil
        if isSelected {
            selectedItems.removeAll(where: { $0.id == itemId })
            selectedCache.removeValue(forKey: itemId)
        } else {
            selectedItems.append(item)
            selectedCache[itemId] = 1
        }
        didUpdateSelectedItems?(selectedItems, selectedCache)
        items.onNext(selectedItems)
    }
    
    // 处理后对外输出的items
    var selectedResult: [IMMentionOptionType] {
        return selectedItems.map {
            var item = $0
            if item.id == IMPickerOption.allId {
                item.name = NSAttributedString(string: BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_MentionAll_Text)
            }
            return item
        }
    }
}
