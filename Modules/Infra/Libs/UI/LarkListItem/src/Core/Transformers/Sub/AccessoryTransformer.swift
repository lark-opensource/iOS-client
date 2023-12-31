//
//  AccessoryTransformer.swift
//  Pods
//
//  Created by Yuri on 2023/10/11.
//

import Foundation
import LarkModel

public protocol AccessoryTransformerType {
    associatedtype ItemType
    func transform(item: ItemType) -> [ListItemNode.AccessoryType]?
}

public class TargetPreviewAccessoryTransformer: AccessoryTransformerType {
    public typealias ItemType = PickerItem

    public init() {}

    public func transform(item: PickerItem) -> [ListItemNode.AccessoryType]? {
        switch item.meta {
        case .chatter(let chatter):
            if chatter.isCrypto == true { return nil }
            return [.targetPreview]
        default:
            return nil
        }
    }
}

public class PickerItemAccessoryTransformer {

    public var isOpen: Bool
    public var transformers: [any AccessoryTransformerType]

    public init(isOpen: Bool = false,
                transformers: [any AccessoryTransformerType] = [TargetPreviewAccessoryTransformer()]
    ) {
        self.isOpen = isOpen
        self.transformers = transformers
    }

    public func transform(item: PickerItem) -> [ListItemNode.AccessoryType]? {
        var accessories = [ListItemNode.AccessoryType]()
        for transformer in transformers {
            if isOpen,
               case let previewTransformer = transformer as? TargetPreviewAccessoryTransformer,
               let res = previewTransformer?.transform(item: item) {
                accessories.append(contentsOf: res)
            }
        }
        return accessories
    }
}
