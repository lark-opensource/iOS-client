//
//  UITableView+Drag.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/24.
//

import UIKit
import Foundation
import LKCommonsLogging

public enum TableDragLifeCycle {
    case sessionWillBegin(UITableView, UIDragSession)
    case sessionDidEnd(UITableView, UIDragSession)
}

/// TableViewDragDelegate 是对 UITableViewDragDelegate 简易的封装
public final class TableViewDragDelegate: NSObject {
    static var logger = Logger.log(TableViewDragDelegate.self, category: "Lark.Interaction")

    /// 是否局限在当前 App
    public var restricted: Bool = false

    /// 是否允许 move 操作
    public var allowsMoveOperation: Bool = false

    /// 返回 indexPath 对应的 DragItem
    public var itemsBlock: (UITableView, UIDragSession, IndexPath) -> [UIDragItem] = { (_, _, _) in
        return []
    }

    /// 点击同一 view 是否需要追加 items
    public var itemsForAddingBlock: (UITableView, UIDragSession, IndexPath, CGPoint) -> [UIDragItem] = { (_, _, _, _) in
        return []
    }

    /// preview 可调整参数
    public var previewParameters: ((UITableView, IndexPath) -> UIDragPreviewParameters?)?

    private var observers: [(TableDragLifeCycle) -> Void] = []

    public override init() {
        super.init()
    }

    /// 添加生命周期观察这
    public func add(observer: @escaping (TableDragLifeCycle) -> Void) {
        self.observers.append(observer)
    }
}

extension TableViewDragDelegate {
    /// 便捷的创建 TableViewDragDelegate 的方法
    /// - Parameter itemsBlock: 支持的 DragItem value
    public static func create(
        itemsBlock: @escaping (UITableView, UIDragSession, IndexPath) -> [DragItemValue]
    ) -> TableViewDragDelegate {
        let drag = TableViewDragDelegate()
        drag.itemsBlock = { (tableView, session, indexPath) -> [UIDragItem] in
            let itemValues = itemsBlock(tableView, session, indexPath)
            return DragInteraction.transform(values: itemValues)
        }
        return drag
    }
}

extension TableViewDragDelegate: UITableViewDragDelegate {

    public func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        return itemsBlock(tableView, session, indexPath)
    }

    public func tableView(
        _ tableView: UITableView,
        itemsForAddingTo session: UIDragSession,
        at indexPath: IndexPath,
        point: CGPoint
    ) -> [UIDragItem] {
        return itemsForAddingBlock(tableView, session, indexPath, point)
    }

    public func tableView(
        _ tableView: UITableView,
        dragPreviewParametersForRowAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        return self.previewParameters?(tableView, indexPath)
    }

    public func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        let state: TableDragLifeCycle = .sessionWillBegin(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        let state: TableDragLifeCycle = .sessionDidEnd(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func tableView(
        _ tableView: UITableView,
        dragSessionAllowsMoveOperation session: UIDragSession
    ) -> Bool {
        return allowsMoveOperation
    }

    public func tableView(
        _ tableView: UITableView,
        dragSessionIsRestrictedToDraggingApplication session: UIDragSession
    ) -> Bool {
        return restricted
    }
}
