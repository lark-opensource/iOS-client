//
//  UITableView+Drop.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/24.
//

import UIKit
import Foundation
import LKCommonsLogging

public enum TableDropLifeCycle {
    case sessionDidEnter(UITableView, UIDropSession)
    case sessionDidUpdate(UITableView, UIDropSession)
    case sessionDidExit(UITableView, UIDropSession)
    case sessionDidEnd(UITableView, UIDropSession)
}

/// TableViewDropDelegate 是对 UITableViewDropDelegate 简易的封装
public final class TableViewDropDelegate: NSObject {

    static var logger = Logger.log(TableViewDropDelegate.self, category: "Lark.Interaction")

    /// 整体是否响应本次拖拽
    public var canHandle: (UITableView, UIDropSession) -> Bool = { (_, _) in
        return true
    }

    /// 处理 Drop 事件
    public var handleBlock: ((UITableView, UITableViewDropCoordinator) -> Void)?

    /// 根据 indexPath 判断是否响应本次 drop 事件
    public var dropProposalBlock: (UITableView, UIDropSession, IndexPath?) -> UITableViewDropProposal = { (_, _, _) in
        return UITableViewDropProposal(operation: .cancel)
    }

    /// preview 可调整参数
    public var previewParameters: ((UITableView, IndexPath) -> UIDragPreviewParameters?)?

    private var observers: [(TableDropLifeCycle) -> Void] = []

    public override init() {
        super.init()
    }

    /// 添加生命周期观察这
    public func add(observer: @escaping (TableDropLifeCycle) -> Void) {
        self.observers.append(observer)
    }
}

extension TableViewDropDelegate {

    /// 创建 TableViewDropDelegate
    /// - Parameters:
    ///   - canHandle: 是否可以整体响应 Drop
    ///   - itemHandleType: handle 策略
    ///   - itemTypes: 支持 handle 的类型
    ///   - itemOptions: handle 可选项
    ///   - canHanleIndex: 根据 index 判断是否可以 handle
    ///   - resultCallback: 结果回调
    public static func create(
        canHandle: @escaping (UITableView, UIDropSession) -> Bool = { (_, _) -> Bool in true },
        itemHandleType: DropItemHandleTactics = .containSupportTypes,
        itemTypes: [DropItemType],
        itemOptions: [DropItemOptions] = [],
        canHanleIndex: @escaping (IndexPath?) -> Bool,
        resultCallback: @escaping (IndexPath?, [DropItemValue]) -> Void
    ) -> TableViewDropDelegate {

        let delegate = TableViewDropDelegate()
        delegate.canHandle = { (table, session) -> Bool in
            /// 整体判断是否响应
            guard canHandle(table, session) else {
                return false
            }

            return DropInteraction.canHanle(
                session: session,
                items: session.items,
                itemTypes: itemTypes,
                itemHandleType: itemHandleType,
                itemOptions: itemOptions
            )
        }
        delegate.handleBlock = { (_, coordinator) in
            DropInteraction.handleDropItems(
                coordinator.items.map({ $0.dragItem }),
                itemTypes: itemTypes) { (values) in
                    if !values.isEmpty {
                        resultCallback(coordinator.destinationIndexPath, values)
                    }
            }
        }
        delegate.dropProposalBlock = { (_, _, indexPath) in
            if canHanleIndex(indexPath) {
                return UITableViewDropProposal(operation: .copy)
            }
            return UITableViewDropProposal(operation: .cancel)
        }

        return delegate
    }
}

extension TableViewDropDelegate: UITableViewDropDelegate {
    public func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        self.handleBlock?(tableView, coordinator)
    }

    public func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return self.canHandle(tableView, session)
    }

    public func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        let state: TableDropLifeCycle = .sessionDidEnter(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        let state: TableDropLifeCycle = .sessionDidUpdate(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
        return self.dropProposalBlock(tableView, session, destinationIndexPath)
    }

    public func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        let state: TableDropLifeCycle = .sessionDidExit(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        let state: TableDropLifeCycle = .sessionDidEnd(tableView, session)
        self.observers.forEach { (observer) in
            observer(state)
        }
    }

    public func tableView(
        _ tableView: UITableView,
        dropPreviewParametersForRowAt indexPath: IndexPath
    ) -> UIDragPreviewParameters? {
        return self.previewParameters?(tableView, indexPath)
    }
}
