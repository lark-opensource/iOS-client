//
//  DragItemDataSource.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DragItemDataSource {

    public typealias ItemsForSessionBlock = (UIDragInteraction, UIDragSession) -> [UIDragItem]

    public typealias ItemsForAddingToBlock = (UIDragInteraction, UIDragSession, CGPoint) -> [UIDragItem]

    public typealias SessionForAddingItemsBlock = (UIDragInteraction, [UIDragSession], CGPoint) -> UIDragSession?

    public var itemsForSession: ItemsForSessionBlock = { _, _ in return [] }
    public var itemsForAddingTo: ItemsForAddingToBlock = { _, _, _ in return [] }
    public var sessionForAddingItems: SessionForAddingItemsBlock = { _, _, _ in return nil }
}
