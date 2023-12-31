//
//  ItemCellDelegate.swift
//  LarkListItem-Cell-Components-Core-Resources-Utils
//
//  Created by Yuri on 2023/10/10.
//

import Foundation

public protocol ItemTableViewCellDelegate: AnyObject {
    func listItemDidClickAccessory(type: ListItemNode.AccessoryType, at indexPath: IndexPath)
}

extension ItemTableViewCellDelegate {
    func listItemDidClickAccessory(type: ListItemNode.AccessoryType, at indexPath: IndexPath) {}
}
