//
//  EdgeTabBar+DragDrop.swift
//  LarkNavigation
//
//  Created by Yaoguoguo on 2023/6/21.
//

import UIKit
import Foundation
import AnimatedTabBar
import LarkEMM
import LarkTab
import LarkInteraction
import LarkSensitivityControl
import UniverseDesignToast
import UniverseDesignIcon

// MARK: Drag & Drop

extension NewEdgeTabBar {

    /// 进入 More 按钮或者 Popover 区域时，展示或者取消 Dismiss Popover
    func showPopoverOnEnteringMoreIfNeeded() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self, selector: #selector(dismissPopover), object: nil
        )
        if popover == nil {
            showPopover()
        }
    }
    /// 离开 More 按钮或者 Popover 区域时，1s 后 Dismiss Popover
    func dismissPopoverOnExitingMoreLater() {
        perform(#selector(dismissPopover), with: nil, afterDelay: 1)
    }

    func canDrag(from position: Position) -> Bool {
        // 1. 如果存在 info(非临时 Tab)，则必须 !unmovable
        if let dragItem = item(at: position), let info = tabInfo[dragItem.tab.key], info.unmovable {
            UDToast.showTips(with: BundleI18n.LarkNavigation.Lark_iPad_UnableReorderFixedByAdmin,
                             on: window ?? self)
            return false
        }
        if case .main = position {
            // 2. 从 main 上拖起时，main 数量必须保证大于 1
            return mainTabItems.count > 1
        }
        return true
    }

    func canDrop(from originPosition: Position, point: CGPoint) -> Bool {
        guard let originItem = item(at: originPosition), point.y > self.tableView.contentSize.height else { return false }

        return originItem.tab.isCustomType()
    }

    func canDrop(from originPosition: Position, to destPosition: Position) -> Bool {
        guard let originItem = item(at: originPosition) else { return false }
        let destItem = item(at: destPosition) // destItem 可空
        // 1. destItem 必须 !unmovable
        if let destItem, let info = tabInfo[destItem.tab.key], info.unmovable {
            return false
        }
        // 2. 当 destPosition != .main 时，originItem 必须是 !primaryOnly
        if case .main = destPosition {} else {
            if let info = tabInfo[originItem.tab.key], info.primaryOnly {
                return false
            }
        }
        switch destPosition {
            // 3. destPosition 需要校验非特殊位置（不能放在更多、添加之后）
        case .main(let index):
            // 不能放在更多之后
            switch originPosition {
            case .main:
                if index >= mainTabItems.count {
                    return false
                }
            case .temporary, .hidden:
                if index >= mainTabItems.count + 1 {
                    return false
                }
            }
        case .hidden(let index):
            // 不能放在添加之后
            switch originPosition {
            case .main, .temporary:
                if index >= hiddenTabItems.count + 1 {
                    return false
                }
            case .hidden:
                if index >= hiddenTabItems.count {
                    return false
                }
            }
        case .temporary:
            // 4. destPosition 为 Temp 时，Item 也必须为 Temp Item
            if !originItem.tab.isCustomType() {
                return false
            }
        }
        // 5. 当 originItem 为 Temp Item，origin 与 dest 跨区域，那么 destPosition 需要校验所属区域 Temp Item 总数
        if originItem.tab.isCustomType(),
           (originPosition.isTemporary != destPosition.isTemporary) {
            let currentTargetAreaTempItemCount: Int
            if destPosition.isTemporary {
                currentTargetAreaTempItemCount = temporaryTabItems.filter({
                    $0.tab.isCustomType()
                }).count
            } else {
                currentTargetAreaTempItemCount = mainTabItems.filter({
                    $0.tab.isCustomType()
                }).count
                + hiddenTabItems.filter({
                    $0.tab.isCustomType()
                }).count
            }
            if currentTargetAreaTempItemCount >= maxAreaTempItemCount {
                return false
            }
        }
        return true
    }
}

extension NewEdgeTabBar.Position {
    var isTemporary: Bool {
        if case .temporary = self {
            return true
        }
        return false
    }
}

// MARK: Menu

extension NewEdgeTabBar {
    @available(iOS 13.0, *)
    func getActions(position: Position) -> [[UIAction]] {
        var actions: [[UIAction]] = []

        let iconColor = UIColor.ud.iconN1.resolvedCompatibleColor(with: self.traitCollection)

        let reopenActions = [UIAction(title: BundleI18n.LarkNavigation.Lark_Navbar_ReopenTabs_Button,
                                      image: UDIcon.getContextMenuIconBy(key: .undoOutlined, iconColor: iconColor), handler: { [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.reopenTab()
        })]

        let copyAction = UIAction(title: BundleI18n.LarkNavigation.Lark_Navbar_CopyLink_Button,
                                  image: UDIcon.getContextMenuIconBy(key: .globalLinkOutlined, iconColor: iconColor), handler: { [weak self] _ in
            var url = ""
            guard let `self` = self else { return }
            switch position {
            case .main(index: let index):
                url = self.mainTabItems[index].tab.urlString
            case .hidden(index: let index):
                url = self.hiddenTabItems[index].tab.urlString
            case .temporary(index: let index):
                url = self.temporaryTabItems[index].tab.urlString
            }

            let config = PasteboardConfig(token: Token(Self.token))
            SCPasteboard.general(config).string = url
        })

        switch position {
        case .main(index: let index):
            guard index < mainTabItems.count && mainTabItems.count > 1 else { return [] }
            let tab = mainTabItems[index].tab

            /// 不可移动或者只能再主导航返回空
            if let info = tabInfo[tab.key], (info.unmovable || info.primaryOnly) {
                return []
            }
            var normalActions: [UIAction] = []

            /// 如果是临时Tab，有移除按钮
            Self.logger.info("<NAVIGATION_BAR> getActions: key = \(tab.key) position = \(position) erasable = \(tabInfo[tab.key]?.erasable) isCustomType = \(tab.isCustomType())")
            if tabInfo[tab.key]?.erasable ?? tab.isCustomType() {
                normalActions.append(copyAction)
                
                normalActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_More_RemoveTab_Button,
                                        image: UDIcon.getContextMenuIconBy(key: .noOutlined, iconColor: iconColor), handler: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.remove(from: .main(index: index))
                }))
            }

            /// 可以收到更多
            normalActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_NaviBar_CollapseToMore_Button,
                                    image: UDIcon.getContextMenuIconBy(key: .moreLauncherOutlined, iconColor: iconColor), handler: { [weak self] _ in
                guard let `self` = self else { return }
                self.insert(from: .main(index: index), to: .hidden(index: self.hiddenTabItems.count))
            }))
            actions.append(normalActions)
            if self.delegate?.hasCloseTab() ?? false {
                actions.append(reopenActions)
            }
        case .hidden(index: let index):
            guard index < hiddenTabItems.count else { return [] }
            let tab = hiddenTabItems[index].tab
            var normalActions: [UIAction] = []

            /// 如果是临时Tab，有移除按钮
            Self.logger.info("<NAVIGATION_BAR> getActions: key = \(tab.key) position = \(position) erasable = \(tabInfo[tab.key]?.erasable) isCustomType = \(tab.isCustomType())")
            if tabInfo[tab.key]?.erasable ?? tab.isCustomType() {
                normalActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_More_RemoveTab_Button,
                                        image: UDIcon.getContextMenuIconBy(key: .noOutlined, iconColor: iconColor), handler: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.remove(from: .hidden(index: index))
                }))
            }

            /// 可以固定到主导航
            normalActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_More_PinTab_Button,
                                    image: UDIcon.getContextMenuIconBy(key: .pinOutlined, iconColor: iconColor), handler: { [weak self] _ in
                guard let `self` = self else { return }
                self.insert(from: .hidden(index: index), to: .main(index: self.mainTabItems.count))
            }))
            actions.append(normalActions)
        case .temporary(index: let index):
            guard index < temporaryTabItems.count else { return [] }

            var normalActions: [UIAction] = []

            normalActions.append(copyAction)

            if self.mainTabItems.filter({
                return $0.tab.isCustomType()
            }).count + self.hiddenTabItems.filter({
                return $0.tab.isCustomType()
            }).count < 200 {
                normalActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_More_PinTab_Button,
                                        image: UDIcon.getContextMenuIconBy(key: .pinOutlined, iconColor: iconColor), handler: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.insert(from: .temporary(index: index), to: .main(index: self.mainTabItems.count))
                }))
            }

            actions.append(normalActions)

            var closeActions: [UIAction] = []

            closeActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Core_More_Close_Button,
                                         image: UDIcon.getContextMenuIconBy(key: .closeOutlined, iconColor: iconColor), handler: { [weak self] _ in
                guard let `self` = self, index < self.temporaryTabItems.count else { return }
                let item = self.temporaryTabItems[index]
                self.temporaryTabItems.remove(at: index)
                self.tableView.reloadData()
                self.delegate?.edgeTabBar(self, removeTemporaryItems: [item])
            }))

            if self.temporaryTabItems.count > 1 {
                closeActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Navbar_CloseOtherTabs_Button,
                                             image: nil, handler: { [weak self] _ in
                    guard let `self` = self, index < self.temporaryTabItems.count else { return }
                    let item = self.temporaryTabItems[index]
                    let removeItems = self.temporaryTabItems.filter {
                        $0.tab.key != item.tab.key
                    }
                    self.temporaryTabItems.removeAll {
                        $0.tab.key != item.tab.key
                    }
                    self.tableView.reloadData()
                    self.delegate?.edgeTabBar(self, removeTemporaryItems: removeItems)
                }))
            }

            if index < self.temporaryTabItems.count - 1 {
                closeActions.append(UIAction(title: BundleI18n.LarkNavigation.Lark_Navbar_CloseTabsBelow_Button,
                                             image: nil, handler: { [weak self] _ in
                    guard let `self` = self, index < self.temporaryTabItems.count else { return }
                    let removeItems = Array(self.temporaryTabItems[(index + 1)...(self.temporaryTabItems.count - 1)])
                    self.temporaryTabItems = Array(self.temporaryTabItems[0...index])
                    self.tableView.reloadData()
                    self.delegate?.edgeTabBar(self, removeTemporaryItems: removeItems)
                }))
            }

            actions.append(closeActions)

            if self.delegate?.hasCloseTab() ?? false {
                actions.append(reopenActions)
            }
        }

        let titles = actions.map {
            return $0.map {
                return $0.title
            }
        }

        Self.logger.info("Get Context Menu actions: \(titles)")
        return actions
    }
}


// MARK: Reorder

extension NewEdgeTabBar {
    func remove(from: Position) {
        Self.logger.info("remove Position \(from)")
        switch from {
        case .main(index: let index):
            mainTabItems.remove(at: index)
        case .hidden(index: let index):
            hiddenTabItems.remove(at: index)
        case .temporary(index: let index):
            temporaryTabItems.remove(at: index)
        }

        let mainRankItem = mainTabItems.compactMap { transferToRankItem(for: $0) }
        let hiddenRankItem = hiddenTabItems.compactMap { transferToRankItem(for: $0) }

        self.tableView.reloadData()
        self.popover?.collectionView.reloadData()

        // 调上传接口
        delegate?.edgeTabBarDidReorderItem(main: mainRankItem, hidden: hiddenRankItem, temporary: temporaryTabItems)
    }

    func insert(from: Position, to position: Position) {
        guard from != position else { return }

        Self.logger.info("insert Position from: \(from) to: \(position)")

        let tab: AbstractTabBarItem
        var isFromTemporary = false

        switch from {
        case .main(index: let index):
            tab = mainTabItems.remove(at: index)
        case .hidden(index: let index):
            tab = hiddenTabItems.remove(at: index)
        case .temporary(index: let index):
            tab = temporaryTabItems.remove(at: index)
            // 如果是从临时区移动过来的话这个tab肯定是可以删除的，需要设置成true，不然在编辑的时候就没法删除
            tab.tab.erasable = true
            isFromTemporary = true
        }
        switch position {
        case .main(index: let index):
            mainTabItems.insert(tab, at: index)
            if isFromTemporary {
                // https://meego.feishu.cn/larksuite/issue/detail/16972678
                delegate?.edgeTabBarUpdateTabBarItem(tab: tab.tab, tabBarItem: tab)
            }
        case .hidden(index: let index):
            hiddenTabItems.insert(tab, at: index)
        case .temporary(index: let index):
            temporaryTabItems.insert(tab, at: index)
        }

        let mainRankItem = mainTabItems.compactMap { transferToRankItem(for: $0) }
        let hiddenRankItem = hiddenTabItems.compactMap { transferToRankItem(for: $0) }

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
        self.tableView.reloadData()
        self.popover?.collectionView.reloadData()

        // 调上传接口
        delegate?.edgeTabBarDidReorderItem(main: mainRankItem, hidden: hiddenRankItem, temporary: temporaryTabItems)
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

    func transferToRankItem(for item: AbstractTabBarItem) -> RankItem? {
        if let info = tabInfo[item.tab.key] {
            return RankItem(tab: item.tab,
                            stateConfig: item.stateConfig,
                            name: item.title,
                            primaryOnly: info.primaryOnly,
                            unmovable: info.unmovable,
                            uniqueID: info.uniqueID,
                            canDelete: info.erasable)
        } else {
            return RankItem(tab: item.tab,
                            stateConfig: item.stateConfig,
                            name: item.title,
                            primaryOnly: false,
                            unmovable: false,
                            uniqueID: item.tab.key,
                            canDelete: true)
        }
    }
}

// MARK: Position

extension NewEdgeTabBar {
    func position(of item: AbstractTabBarItem) -> Position? {
        if let index = mainTabItems.firstIndex(where: { item.tab == $0.tab }) {
            return .main(index: index)
        } else if let index = hiddenTabItems.firstIndex(where: { item.tab == $0.tab }) {
            return .hidden(index: index)
        } else if let index = temporaryTabItems.firstIndex(where: { item.tab == $0.tab }) {
            return .temporary(index: index)
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
        if collectionView === self.popover?.collectionView {
            return .hidden(index: indexPath.row)
        } else {
            return nil
        }
    }

    func item(at indexPath: IndexPath, in tableView: UITableView) -> AbstractTabBarItem? {
        if let position = position(of: indexPath, in: tableView) {
            return item(at: position)
        } else {
            return nil
        }
    }

    func position(of indexPath: IndexPath, in tableView: UITableView) -> Position? {
        if tableView === self.tableView {
            switch indexPath.section {
            case 0: return .main(index: indexPath.row)
            case 1: return .temporary(index: indexPath.row)
            default: return nil
            }
        } else {
            return nil
        }
    }

    func item(at position: Position) -> AbstractTabBarItem? {
        switch position {
        case .main(index: let index):
            return mainTabItems[safe: index]
        case .temporary(index: let index):
            return temporaryTabItems[safe: index]
        case .hidden(index: let index):
            return hiddenTabItems[safe: index]
        }
    }

    func indexPathAndView(of position: Position) -> (IndexPath, UIView?) {
        switch position {
        case .main(let index):
            return (IndexPath(row: index, section: 0), tableView)
        case .hidden(let index):
            return (IndexPath(row: index, section: 0), popover?.collectionView)
        case .temporary(let index):
            return (IndexPath(row: index, section: 1), tableView)
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

// MARK: - NewEdgeTabIndexProvider
/// 拖动的实体，目前包含 Tab index
///
/// - Note: Edge / Bottom 建议使用不同的 Provider，以处理 C/R 切换时，Item 不可互拖的问题
final class NewEdgeTabIndexProvider: NSObject, NSItemProviderWriting, NSItemProviderReading {

    static var typeIdentifier: String = "LarkDraggableTab"
    // Writing
    static var writableTypeIdentifiersForItemProvider: [String] = [typeIdentifier]

    enum DragError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }

    var index: NewEdgeTabBar.Position

    required init(_ index: NewEdgeTabBar.Position) {
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
            let index = try decoder.decode(NewEdgeTabBar.Position.self, from: data)
            return Self.init(index)
        } catch {
            throw DragError.decodingFailure
        }
    }
}

extension NewEdgeTabBar.Position: Codable {
    // Conform to Codable
    private enum CodingKeys: CodingKey {
        case main, hidden, temporary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let key = container.allKeys.first {
            let index = try container.decode(Int.self, forKey: key)
            switch key {
            case .main:
                self = .main(index: index)
            case .hidden:
                self = .hidden(index: index)
            case .temporary:
                self = .temporary(index: index)
            }
        } else {
            assertionFailure("decode failed")
            self = .main(index: -1)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .main(index: let index):
            try container.encode(index, forKey: .main)
        case .hidden(index: let index):
            try container.encode(index, forKey: .hidden)
        case .temporary(index: let index):
            try container.encode(index, forKey: .temporary)
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
    var tabItem: AbstractTabBarItem? {
        if let dragItem = localDragSession?.items.first, let item = dragItem.localObject as? AbstractTabBarItem {
            return item
        }
        return nil
    }
}

extension UIDragSession {
    var tabItem: AbstractTabBarItem? {
        if let dragItem = items.first, let item = dragItem.localObject as? AbstractTabBarItem {
            return item
        }
        return nil
    }
}
