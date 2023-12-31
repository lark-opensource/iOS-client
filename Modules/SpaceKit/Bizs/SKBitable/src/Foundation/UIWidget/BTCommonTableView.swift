//
//  BTCommonTableView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/30.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SKFoundation
import SKUIKit

protocol BTCommonTableViewScrollDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
}

protocol BTCommonTableViewDelegate: AnyObject {
    func commonTableViewSortItem(_ table: BTCommonTableView, viewId: String, fromIndex: Int, toIndex: Int)
}

class BTCommonTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        return generator
    }()

    weak var commonTableScrollDelegate: BTCommonTableViewScrollDelegate?
    weak var commonTableDelegate: BTCommonTableViewDelegate?
    
    private var items: BTCommonDataModel = BTCommonDataModel(groups: [])

    var hideRightIcon: Bool = false
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.dataSource = self
        self.delegate = self
        
        self.backgroundColor = .clear
        self.backgroundView = nil
        self.separatorStyle = .none
        
        // 启用拖动交互功能
        self.dragInteractionEnabled = true
        self.dragDelegate = self
        self.dropDelegate = self
        
        self.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)

        // 注册 UITableViewCell
        self.register(BTCommonItemCell.self, forCellReuseIdentifier: BTCommonItemCell.reuseIdentifier)

        rowHeight = UITableView.automaticDimension
    }

    func update(items: BTCommonDataModel) {
        self.items = items
        reloadData()
    }

    func update(isCaptureAllowed: Bool) {
        self.items.isCaptureAllowed = isCaptureAllowed
        reloadData()
    }

    func handleScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        if items.groups.safe(index: indexPath.section)?.items.safe(index: indexPath.row) == nil {
            return
        }
        scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.groups.first?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BTCommonItemCell.reuseIdentifier, for: indexPath)
        let isLandscape = UIDevice.current.orientation.isLandscape
        if let cell = cell as? BTCommonItemCell {
            if let group = items.groups.safe(index: indexPath.section), let item = group.items.safe(index: indexPath.row) {
                var item = item
                item.hideRightIcon = self.hideRightIcon
                cell.update(item: item, group: group, indexPath: indexPath, isCaptureAllowed: items.isCaptureAllowed)
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 处理选中某一行的操作
        print("Selected row: \(indexPath.row + 1)")
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        commonTableScrollDelegate?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        commonTableScrollDelegate?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
}

// MARK: - UITableViewDragDelegate

extension BTCommonTableView: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if !UserScopeNoChangeFG.LYL.disableFixBaseDragTableSplash {
            let cell = tableView.cellForRow(at: indexPath) as? BTCommonItemCell
            // 系统拖动基于截图实现，防截图功能会影响拖动，所以这里临时打开 isCaptureAllowed，再关闭
            cell?.update(isCaptureAllowed: true)
        }

        let itemProvider = NSItemProvider(object: "item" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        impactGenerator.impactOccurred()
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        let location = session.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) as? BTCommonItemCell {
            cell.update(isCaptureAllowed: items.isCaptureAllowed)
        }
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        let previewParameters = UIDragPreviewParameters()
        let path = UIBezierPath(roundedRect: cell.bounds,
                                cornerRadius: cell.layer.cornerRadius)
        previewParameters.visiblePath = path
        return previewParameters
    }
}

// MARK: - UITableViewDropDelegate

extension BTCommonTableView: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.hasActiveDrag {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        let previewParameters = UIDragPreviewParameters()
        let path = UIBezierPath(roundedRect: cell.bounds,
                                cornerRadius: cell.layer.cornerRadius)
        previewParameters.visiblePath = path
        return previewParameters
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard coordinator.proposal.operation == .move else {
            DocsLogger.btInfo("[BTCommonTable] coordinator operation not move")
            return
        }
        guard let item = coordinator.items.first,
              let source = item.sourceIndexPath,
              let destinationIndexPath = coordinator.destinationIndexPath,
              source.section < items.groups.count,
              source.row < items.groups[source.section].items.count else {
            DocsLogger.btError("[BTCommonTable] source is invalid")
            return
        }

        guard source != destinationIndexPath else {
            DocsLogger.btInfo("[BTCommonTable] source equal to destinationIndexPath")
            return
        }

        self.exchange(source: source, destination: destinationIndexPath)
        reloadData()
        UIView.performWithoutAnimation {
            coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
        }
    }

    private func exchange(source: IndexPath, destination: IndexPath) {
        guard let sourceGroup = items.groups.safe(index: source.section),
              sourceGroup.items.safe(index: source.row) != nil else {
            DocsLogger.btError("[BTCommonTable] source get error")
            return
        }

        guard let destinGroup = items.groups.safe(index: destination.section),
              destinGroup.items.safe(index: destination.row) != nil else {
            DocsLogger.btError("[BTCommonTable] destin get error")
            return
        }
        guard let viewId = sourceGroup.items.safe(index: source.row)?.id else {
            DocsLogger.btError("[BTCommonTable] get viewId fail")
            return
        }
        let mover = items.groups[source.section].items.remove(at: source.row)
        items.groups[destination.section].items.insert(mover, at: destination.row)
        commonTableDelegate?.commonTableViewSortItem(self, viewId: viewId, fromIndex: source.row, toIndex: destination.row)
    }
}

