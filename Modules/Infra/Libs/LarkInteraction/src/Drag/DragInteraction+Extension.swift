//
//  DragInteraction+Extension.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/23.
//

import UIKit
import Foundation

extension DragInteraction {

    /// 便捷的创建 Drag Interaction 的方法
    /// - Parameter itemsBlock: 支持的 DragItem value
    public static func create(
        itemsBlock: @escaping (UIDragInteraction, UIDragSession) -> [DragItemValue]
    ) {
        let drag = DragInteraction()
        drag.itemDataSource.itemsForSession = { (interaction, session) -> [UIDragItem] in
            let itemValues = itemsBlock(interaction, session)
            return DragInteraction.transform(values: itemValues)
        }
    }

    static func transform(values: [DragItemValue]) -> [UIDragItem] {
        return values.compactMap { (value) -> UIDragItem? in
            let itemPorvider: NSItemProvider
            switch value.data {
            case .objectType(let object):
                itemPorvider = NSItemProvider(object: object)
            case .fileURL(let url):
                guard let provider = NSItemProvider(contentsOf: url) else {
                    return nil
                }
                itemPorvider = provider
            case let.custom(item: item, typeIdentifier: typeIdentifier):
                itemPorvider = NSItemProvider(item: item, typeIdentifier: typeIdentifier)
            }
            itemPorvider.suggestedName = value.suggestedName
            let dragItem = UIDragItem(itemProvider: itemPorvider)
            dragItem.previewProvider = value.priview
            return dragItem
        }
    }
}
