//
//  BlockTreeView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/29.
//

import UIKit
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor

protocol BlockTreeViewDelegate: AnyObject {
    func didSwapItem(id: String, from: Int, to: Int)
}

final class BlockTreeView: UITableView, UITableViewDataSource, UITableViewDelegate {
    private var lastHeight: CGFloat = 0
    
    weak var blockTreeDelegate: BlockTreeViewDelegate?
    
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        return generator
    }()
    
    private var items: BTCommonDataModel = BTCommonDataModel(groups: []) {
        didSet {
            reloadData()
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastHeight != frame.height {
            lastHeight = frame.height
            // 高度发生变化，需要重新定位到选中的item
            scrollToHighLightRow(animated: false)
        }
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
        
        self.showsVerticalScrollIndicator = false        
        self.dragDelegate = self
        self.dropDelegate = self
        
        self.rowHeight = UITableView.automaticDimension
        self.estimatedRowHeight = 46
        
        self.delaysContentTouches = false
        self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)

        // 注册 UITableViewCell
        self.register(BTCommonItemCell.self, forCellReuseIdentifier: BTCommonItemCell.reuseIdentifier)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.groups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let group = items.groups.safe(index: section) {
            return group.items.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BTCommonItemCell.reuseIdentifier, for: indexPath)

        if let cell = cell as? BTCommonItemCell {
            if let group = items.groups.safe(index: indexPath.section), let item = group.items.safe(index: indexPath.row) {
                cell.update(item: item, group: group, indexPath: indexPath)
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 处理选中某一行的操作
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.frame = CGRect(x: 0, y: 0, width: 0, height: 4)
        return view
    }
}

extension BlockTreeView {
    func setData(items: BTCommonDataModel) {
        self.items = items
    }
    
    // 滚动到高亮行
    func scrollToHighLightRow(animated: Bool = true) {
        items.groups.enumerated().forEach { (section, group) in
            if let row = group.items.firstIndex(where: { $0.isSelected ?? false }) {
                if animated {
                    self.docs.safeScrollToItem(at: IndexPath(row: row, section: section), at: .middle, animated: animated)
                } else {
                    // 避免其他动画影响
                    UIView.performWithoutAnimation {
                        self.docs.safeScrollToItem(at: IndexPath(row: row, section: section), at: .middle, animated: animated)
                    }
                }
                return
            }
        }
    }
    
    // 设置列表是否可拖动
    func setDraggable(_ draggable: Bool) {
        self.dragInteractionEnabled = draggable
    }
}

extension BlockTreeView: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if !UserScopeNoChangeFG.LYL.disableFixBaseDragTableSplash {
            let cell = tableView.cellForRow(at: indexPath) as? BTCommonItemCell
            // 系统拖动基于截图实现，防截图功能会影响拖动，所以这里临时打开 isCaptureAllowed，再关闭
            cell?.update(isCaptureAllowed: true)
        }
        
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        impactGenerator.impactOccurred()
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        swapItem(from: sourceIndexPath, to: destinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        let location = session.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) as? BTCommonItemCell {
            cell.update(isCaptureAllowed: items.isCaptureAllowed)
        }
    }
}

extension BlockTreeView: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = self.cellForRow(at: indexPath) else {
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
            DocsLogger.btInfo("[BlockTreeView] coordinator operation not move")
            return
        }
        guard let item = coordinator.items.first,
              let source = item.sourceIndexPath,
              let destinationIndexPath = coordinator.destinationIndexPath,
              source.section < items.groups.count,
              source.row < items.groups[source.section].items.count else {
            DocsLogger.btError("[BlockTreeView] source is invalid")
            return
        }

        guard source != destinationIndexPath else {
            DocsLogger.btInfo("[BlockTreeView] source equal to destinationIndexPath")
            return
        }

        swapItem(from: source, to: destinationIndexPath)
    }
    
    // 拖拽排序后更新数据源
    func swapItem(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let sourceGroup = items.groups.safe(index: sourceIndexPath.section),
              sourceGroup.items.safe(index: sourceIndexPath.row) != nil else {
            DocsLogger.btError("[BlockTreeView] source get error")
            return
        }
        
        guard let destinGroup = items.groups.safe(index: destinationIndexPath.section),
              destinGroup.items.safe(index: destinationIndexPath.row) != nil else {
            DocsLogger.btError("[BlockTreeView] destin get error")
            return
        }
        
        DocsLogger.btInfo("[BlockTreeView] swap from: \(sourceIndexPath) to: \(destinationIndexPath)")
        
        let mover = items.groups[sourceIndexPath.section].items.remove(at: sourceIndexPath.row)
        items.groups[destinationIndexPath.section].items.insert(mover, at: destinationIndexPath.row)
        
        blockTreeDelegate?.didSwapItem(id: mover.id ?? "", from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
}
