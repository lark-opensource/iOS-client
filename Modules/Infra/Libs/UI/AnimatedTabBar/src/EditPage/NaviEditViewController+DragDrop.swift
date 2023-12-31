//
//  NaviEditViewController+DragDrop.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/8/3.
//

import UIKit
import Foundation
import LarkTab
import LarkInteraction
import UniverseDesignToast
import UniverseDesignIcon

// MARK: Drag & Drop

extension NaviEditViewController {

    enum PointLocationDirection: Int {
        case left
        case right
        case center
    }

    enum EditDropOperation: UInt {
        case copy
        case move
    }

    // 进某个控件的时候弹出提示
    func showPopoverOnEnteringIfNeeded() {
    }
    // 离开 某个控件的时候Dismiss提示
    func dismissPopoverOnExitingIfNeeded() {
    }

    func canDrag(from position: Position) -> Bool {
        // 0. 如果应用本身无法拖动
        if let dragItem = item(at: position), dragItem.tab.unmovable {
            // 无法更改，该应用排序已被管理员固定
            UDToast.showTips(with: BundleI18n.AnimatedTabBar.Lark_iPad_UnableReorderFixedByAdmin,
                             on: self.view)
            return false
        }
        if case .quick = position {
            // 1. 从 quick 上拖起时，quick 数量必须保证大于 1
            return viewModel.quickItems.count > 1
        }
        if case .main = position {
            // 2. 从 main 上拖起时，main 数量必须保证大于 1
            return viewModel.mainItems.count > 1
        }
        return true
    }

    func canDrop(from originPosition: Position, to destPosition: Position) -> Bool {
        guard let originItem = item(at: originPosition) else { return false }
        // destItem 可空
        let destItem = item(at: destPosition)
        // 1. destItem 必须 !unmovable
        if let destItem, destItem.tab.unmovable {
            return false
        }
        // 2. 当 destPosition != .main 时，originItem 必须是 !primaryOnly
        if case .main = destPosition {} else {
            if originItem.tab.primaryOnly {
                return false
            }
        }
        switch destPosition {
        // 3. destPosition 需要校验非特殊位置（不能放在更多、添加之后）
        case .quick(let index):
            // 如果目标是快捷导航不管来源是哪都不能放在添加之后
            switch originPosition {
            case .quick:
                if index >= viewModel.quickItems.count + 1 {
                    return false
                }
            case .main:
                if index >= viewModel.quickItems.count + 1 {
                    return false
                }
            }
        case .main(let index):
            // 如果目标是主导航的话不管来源是哪都不能放在更多之后
            switch originPosition {
            case .quick:
                if viewModel.mainItems.count >= 5 {
                    // 主导航不能超过5个
                    return false
                }
            case .main:
                if index >= viewModel.mainItems.count {
                    return false
                }
            }
        }
        return true
    }

    func calculatePointLocation(by point: CGPoint, frames: [CGRect]) -> (Int?, PointLocationDirection?) {
        var minDistance = CGFloat.greatestFiniteMagnitude
        var nearestFrame: CGRect?
        for frame in frames {
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance < minDistance {
                minDistance = distance
                nearestFrame = frame
            }
        }
        guard let nearestFrame else {
            return (nil, nil)
        }
        let index = frames.firstIndex(of: nearestFrame)
        if point.x < nearestFrame.midX {
            // point 靠近 frame 左侧
            return (index, .left)
        } else if point.x > nearestFrame.midX {
            // point 靠近 frame 右侧
            return (index, .right)
        } else {
            // point 位于 frame 中心
            return (index, .center)
        }
    }

    func getByDefaultDestinationIndexPath(by collectionView: UICollectionView, dropOperation: EditDropOperation) -> IndexPath {
        let section = collectionView.numberOfSections - 1
        var row = collectionView.numberOfItems(inSection: section)
        if case .move = dropOperation {
            row = row > 0 ? (row - 1) : 0
        }
        let destinationIndexPath = IndexPath(row: row, section: section)
        return destinationIndexPath
    }

    func calculateAppropriateIndexPath(by collectionView: UICollectionView, dropPoint: CGPoint, dropOperation: EditDropOperation) -> IndexPath {
        let visibleCells = collectionView.visibleCells.sorted(by: { (left, right) -> Bool in
            guard let leftPath = collectionView.indexPath(for: left),
                  let rightPath = collectionView.indexPath(for: right) else {
                return false
            }
            return leftPath.row < rightPath.row
        })
        let indexPathArray = visibleCells.map { collectionView.indexPath(for: $0) }
        let cellFrames: [CGRect] = indexPathArray.map { indexPath in
            if let indexPath {
                return collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
            }
            return .zero
        }
        let destinationIndexPath: IndexPath
        let (index, direction) = self.calculatePointLocation(by: dropPoint, frames: cellFrames)
        if let index, let direction {
            let targetIndex: Int
            switch direction {
            case .left:
                targetIndex = index < viewModel.mainItems.count ? index : 0
            case .right, .center:
                targetIndex = index < viewModel.mainItems.count ? (index + 1) : viewModel.mainItems.count
            }
            let section = collectionView.numberOfSections - 1
            destinationIndexPath = IndexPath(row: targetIndex, section: section)
        } else {
            destinationIndexPath = self.getByDefaultDestinationIndexPath(by: collectionView, dropOperation: dropOperation)
        }
        return destinationIndexPath
    }
}

extension NaviEditViewController.Position {
    var isQuick: Bool {
        if case .quick = self {
            return true
        }
        return false
    }
    var isMain: Bool {
        if case .main = self {
            return true
        }
        return false
    }
}

// MARK: Reorder

extension NaviEditViewController {
    func remove(from: Position) {
        Self.logger.info("remove Position \(from)")
        switch from {
        case .quick(index: let index):
            guard index < viewModel.quickItems.count else { return }
            viewModel.quickItems.remove(at: index)
        case .main(index: let index):
            guard index < viewModel.mainItems.count else { return }
            viewModel.mainItems.remove(at: index)
        }

        container.quickCollectionView.reloadData()
        container.quickCollectionView.performBatchUpdates({ [weak self] in
            guard let self else { return }
            let visibleItems = self.container.quickCollectionView.indexPathsForVisibleItems
            self.container.quickCollectionView.reloadItems(at: visibleItems)
        })
        container.mainCollectionView.reloadData()
        container.mainCollectionView.performBatchUpdates({ [weak self] in
            guard let self else { return }
            let visibleItems = self.container.mainCollectionView.indexPathsForVisibleItems
            self.container.mainCollectionView.reloadItems(at: visibleItems)
        })
    }

    func insert(from: Position, to position: Position) {
        guard from != position else { return }

        Self.logger.info("insert Position from: \(from) to: \(position)")

        let tab: AbstractTabBarItem

        switch from {
        case .quick(index: let index):
            tab = viewModel.quickItems.remove(at: index)
        case .main(index: let index):
            tab = viewModel.mainItems.remove(at: index)
        }
        switch position {
        case .quick(index: let index):
            guard viewModel.quickItems.count >= index else { return }
            viewModel.quickItems.insert(tab, at: index)
        case .main(index: let index):
            guard viewModel.mainItems.count >= index else { return }
            viewModel.mainItems.insert(tab, at: index)
        }

        // 排序动画
        let (sourceIndexPath, sourceView) = indexPathAndView(of: from)
        let (destIndexPath, destView) = indexPathAndView(of: position)
        if sourceView == destView {
            if let sourceView = sourceView as? UITableView {
                sourceView.performBatchUpdates {
                    sourceView.deleteRows(at: [sourceIndexPath], with: .fade)
                    sourceView.insertRows(at: [destIndexPath], with: .fade)
                }
            } else if let sourceView = sourceView as? UICollectionView {
                sourceView.performBatchUpdates {
                    sourceView.deleteItems(at: [sourceIndexPath])
                    sourceView.insertItems(at: [destIndexPath])
                }
            }
        } else {
            deleteItems(at: [sourceIndexPath], in: sourceView)
            insertItems(at: [destIndexPath], in: destView)
        }
        container.quickCollectionView.reloadData()
        container.quickCollectionView.performBatchUpdates({ [weak self] in
            guard let self else { return }
            let visibleItems = self.container.quickCollectionView.indexPathsForVisibleItems
            self.container.quickCollectionView.reloadItems(at: visibleItems)
        })
        container.mainCollectionView.reloadData()
        container.mainCollectionView.performBatchUpdates({ [weak self] in
            guard let self else { return }
            let visibleItems = self.container.mainCollectionView.indexPathsForVisibleItems
            self.container.mainCollectionView.reloadItems(at: visibleItems)
        })
    }

    private func insertItems(at indexPaths: [IndexPath], in view: UIView?) {
        guard let view = view else { return }
        if let collection = view as? UICollectionView {
            collection.insertItems(at: indexPaths)
        } else if let table = view as? UITableView {
            table.insertRows(at: indexPaths, with: .fade)
        }
    }

    private func deleteItems(at indexPaths: [IndexPath], in view: UIView?) {
        guard let view = view else { return }
        if let collection = view as? UICollectionView {
            collection.deleteItems(at: indexPaths)
        } else if let table = view as? UITableView {
            table.deleteRows(at: indexPaths, with: .fade)
        }
    }
}

// MARK: Position

extension NaviEditViewController {
    func position(of item: AbstractTabBarItem) -> Position? {
        if let index = viewModel.quickItems.firstIndex(where: { item.tab == $0.tab }) {
            return .quick(index: index)
        } else if let index = viewModel.mainItems.firstIndex(where: { item.tab == $0.tab }) {
            return .main(index: index)
        }

        return nil
    }

    func item(at indexPath: IndexPath, in collectionView: UICollectionView) -> AbstractTabBarItem? {
        if let position = position(of: indexPath, in: collectionView) {
            return item(at: position)
        } else {
            return nil
        }
    }

    func position(of indexPath: IndexPath, in collectionView: UICollectionView) -> Position? {
        if collectionView === container.quickCollectionView {
            return .quick(index: indexPath.item)
        } else if collectionView === container.mainCollectionView {
            return .main(index: indexPath.item)
        } else {
            return nil
        }
    }

    func item(at position: Position) -> AbstractTabBarItem? {
        switch position {
        case .quick(index: let index):
            return viewModel.quickItems[safe: index]
        case .main(index: let index):
            return viewModel.mainItems[safe: index]
        }
    }

    func indexPathAndView(of position: Position) -> (IndexPath, UIView?) {
        switch position {
        case .quick(let index):
            return (IndexPath(row: index, section: 0), container.quickCollectionView)
        case .main(let index):
            return (IndexPath(row: index, section: 0), container.mainCollectionView)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        if indices.contains(index) {
            return self[index]
        } else {
            return nil
        }
    }
}

// MARK: - NaviEditViewControllerIndexProvider

/// 拖动的实体，目前包含 Tab index
///
/// - Note: Edge / Bottom 使用不同的 Provider，以处理 C/R 切换时，Item 不可互拖的问题
final class NaviEditViewControllerIndexProvider: NSObject, NSItemProviderWriting, NSItemProviderReading {

    static var typeIdentifier: String = "LarkNaviDraggableTab"
    // Writing
    static var writableTypeIdentifiersForItemProvider: [String] = [typeIdentifier]

    enum DragError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }

    var index: NaviEditViewController.Position

    required init(_ index: NaviEditViewController.Position) {
        self.index = index
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        guard Self.writableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            completionHandler(nil, DragError.invalidTypeIdentifier)
            return nil
        }
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(index)
            completionHandler(data, nil)
            return nil
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }

    // Reading
    static var readableTypeIdentifiersForItemProvider: [String] = [typeIdentifier]

    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard self.readableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            throw DragError.invalidTypeIdentifier
        }
        let decoder = PropertyListDecoder()
        do {
            let index = try decoder.decode(NaviEditViewController.Position.self, from: data)
            return Self.init(index)
        } catch {
            throw DragError.decodingFailure
        }
    }
}

extension NaviEditViewController.Position: Codable {
    // Conform to Codable
    private enum CodingKeys: CodingKey {
        case quick, main
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let key = container.allKeys.first {
            let index = try container.decode(Int.self, forKey: key)
            switch key {
            case .quick:
                self = .quick(index: index)
            case .main:
                self = .main(index: index)
            }
        } else {
            assertionFailure("decode failed")
            self = .main(index: -1)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .quick(index: let index):
            try container.encode(index, forKey: .quick)
        case .main(index: let index):
            try container.encode(index, forKey: .main)
        }
    }

    // Convert to data
    func encode() throws -> Data {
        let encoder = PropertyListEncoder()
        return try encoder.encode(self)
    }

    init(from data: Data) throws {
        let decoder = PropertyListDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}

extension UIDropSession {
    var naviTabItem: AbstractTabBarItem? {
        if let dragItem = localDragSession?.items.first, let item = dragItem.localObject as? AbstractTabBarItem {
            return item
        }
        return nil
    }
}

extension UIDragSession {
    var naviTabItem: AbstractTabBarItem? {
        if let dragItem = items.first, let item = dragItem.localObject as? AbstractTabBarItem {
            return item
        }
        return nil
    }
}

