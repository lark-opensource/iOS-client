//
//  PickerSelectedItemTransformer.swift
//  Pods
//
//  Created by Yuri on 2023/10/20.
//

import Foundation
import LarkModel

public final class PickerSelectedItemTransformer {

    public var accessoryTransformer: PickerItemAccessoryTransformer

    public init(accessoryTransformer: PickerItemAccessoryTransformer) {
        self.accessoryTransformer = accessoryTransformer
    }

    public func transform(
        indexPath: IndexPath,
        item: PickerItem,
        checkBox: ListItemNode.CheckBoxState = .init()
    ) -> ListItemNode {
        var node = ListItemNode(indexPath: indexPath, checkBoxState: .init(isShow: false))
        switch item.meta {
        case .chatter(let meta):
            fullChatter(node: &node, item: item, meta: meta)
        default: break
        }
        return node
    }

    private func fullChatter(node: inout ListItemNode, item: PickerItem, meta: PickerChatterMeta) {
        if let renderData = item.renderData {
            if let title = renderData.title {
                node.title = SearchAttributeString(searchHighlightedString: title).attributeText
            }
        }
        var accessory = accessoryTransformer.transform(item: item) ?? []
        accessory.append(.delete)
        node.accessories = accessory
        if let key = meta.avatarKey {
            node.icon = .avatar(meta.avatarId ?? "", key)
        } else if let url = meta.avatarUrl {
            node.icon = .avatarImageURL(URL(string: url))
        }
    }
}
