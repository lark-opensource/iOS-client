//
//  V3ListView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import CTFoundation
import LarkSwipeCellKit
import UniverseDesignEmpty
import LarkUIKit
import Differentiator
import UIKit
import UniverseDesignFont

// MARK: - List View

protocol V3ListViewActionDelegate: AnyObject {
    /// 获取测滑的按钮
    func getSwipeDescriptor(at indexPath: IndexPath, guid: String) -> [V3SwipeActionDescriptor]?
    /// check box
    func enabledAction(at indexPath: IndexPath, guid: String, isFromSlide: Bool) -> CheckboxEnabledAction
    /// 是否可以拖拽
    func canDrag(at indexPath: IndexPath) -> Bool
    /// 用户在列表上点击
    func doAction(by type: V3ListView.ActionType)
}

final class V3ListView: UIView {

    // delegate
    weak var actionDelegate: V3ListViewActionDelegate?
    // view
    private(set) lazy var collectionView: UICollectionView = configCollectionView()
    // model
    private(set) lazy var sectionModels = [V3ListSectionData]()
    // 背景色，pad 和 phone 不同
    private var mainBgColor: UIColor { Display.pad ? UIColor.ud.bgBodyOverlay : UIColor.ud.bgBase }

    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: self,
            targetView: collectionView,
            bottomInset: collectionView.contentInset.bottom,
            backgroundColor: mainBgColor
        )
    }()
    private lazy var prefetchEnable: Bool = true

    /// 记录拖拽的变量
    private struct DragDropState {
        var isReordering: Bool = false
        var isDroping: Bool = false
        var reloadFailedData: [V3ListSectionData]?
    }
    private var dragDropState = DragDropState()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = mainBgColor
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension V3ListView {

    private func setupView() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
            )
        }
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        collectionView.addGestureRecognizer(longPress)
        stateView.retryHandler = { [weak self] in self?.actionDelegate?.doAction(by: .retryFetch) }
    }

    private func configCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = .zero
        layout.itemSize = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = mainBgColor
        cv.clipsToBounds = true
        cv.dragInteractionEnabled = true
        cv.dropDelegate = self
        cv.dragDelegate = self
        cv.ctf.register(cellType: V3ListCell.self)
        cv.ctf.register(headerViewType: V3ListSectionHeaderView.self)
        cv.ctf.register(footerViewType: V3ListSectionFooterView.self)
        return cv
    }

    @objc
    private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began, .changed: dragDropState.isReordering = true
        default: dragDropState.isReordering = false
        }
    }

}

// MARK: - CollectionView

extension V3ListView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels) else { return .zero }
        if let header = sectionModels[section].header, header.isFold { return .zero }
        let item = sectionModels[section].items[row]
        let maxWidth = collectionView.bounds.width - ListConfig.Cell.leftPadding - ListConfig.Cell.rightPadding
        if let height = item.cellHeight {
            return CGSize(width: maxWidth, height: height)
        }
        let height = item.preferredHeight(maxWidth: maxWidth)
        sectionModels[section].items[row].cellHeight = height
        return CGSize(width: maxWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection
                            section: Int
    ) -> CGSize {
        guard V3ListSectionData.safeCheckSection(in: section, with: sectionModels) != nil else { return .zero }
        guard let header = sectionModels[section].header else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: header.preferredHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection
                            section: Int
    ) -> CGSize {
        guard V3ListSectionData.safeCheckSection(in: section, with: sectionModels) != nil else { return .zero }
        let footer = sectionModels[section].footer
        return CGSize(width: collectionView.bounds.width, height: footer.preferredHeight)
    }

}

extension V3ListView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionModels.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard V3ListSectionData.safeCheckSection(in: section, with: sectionModels) != nil else { return 0 }
        if let header = sectionModels[section].header, header.isFold {
            return .zero
        }
        return sectionModels[section].items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(V3ListCell.self, for: indexPath),
              let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels)
        else {
            return UICollectionViewCell()
        }
        cell.viewData = sectionModels[section].items[row]
        cell.delegate = self
        cell.actionDelegate = self
        cell.showSeparateLine = true
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        if numberOfRows - 1 == indexPath.row, sectionModels[section].footer.isHidden {
            cell.showSeparateLine = false
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView.ctf.dequeueReusableHeaderView(V3ListSectionHeaderView.self, for: indexPath),
                  let section = V3ListSectionData.safeCheckSection(in: indexPath.section, with: sectionModels) else {
                return UICollectionReusableView()
            }
            let sectionModel = sectionModels[section]
            header.viewData = sectionModel.header
            // 分组收起和分组为空且footer不展示都不需要显示分割线
            if (sectionModel.items.isEmpty && sectionModel.footer.isHidden) || (sectionModel.header?.isFold ?? true) {
                header.showSeparateLine = false
            } else {
                header.showSeparateLine = true
            }
            header.tapSectionHandler = { [weak self] in
                self?.actionDelegate?.doAction(by: .headerSelected(indexPath: indexPath, sectionId: sectionModel.sectionId))
            }
            header.tapMoreHandler = { [weak self, weak header] in
                guard let self = self, let view = header else { return }
                self.actionDelegate?.doAction(by: .headerMore(indexPath: indexPath, sectionId: sectionModel.sectionId, sourceView: view))
            }
            return header
        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView.ctf.dequeueReusableFooterView(V3ListSectionFooterView.self, for: indexPath),
                let section = V3ListSectionData.safeCheckSection(in: indexPath.section, with: sectionModels) else {
                return UICollectionReusableView()
            }
            let sectionModel = sectionModels[section]
            footer.viewData = sectionModel.footer
            footer.tapSectionHandler = { [weak self] in
                self?.actionDelegate?.doAction(by: .footerSelected(indexPath: indexPath, sectionId: sectionModel.sectionId))
            }
            return footer
        default:
            V3Home.assertionFailure()
            return UICollectionReusableView()
        }
    }

    private func guid(by indexPath: IndexPath) -> String? {
        guard let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels) else { return nil }
        let item = sectionModels[section].items[row]
        return item.todo.guid
    }

    private func tryPrefetch(index: IndexPath) {
        // 只有最后一个分组是骨架图，才表示需要加载更多
        guard let lastSection = sectionModels.last, lastSection.isSkeleton else {
            return
        }
        let allItemCnt = sectionModels.reduce(0) { partialResult, section in
            if section.isSkeleton { return partialResult }
            return partialResult + section.items.count
        }
        // 总数要大于3屏才能触发
        guard allItemCnt >= Utils.List.fetchCount.initial else { return }
        guard prefetchEnable else { return }
        var leftCount = 0
        for (i, item) in sectionModels.enumerated() {
            if i > index.section {
                leftCount += item.items.count
            } else if i == index.section {
                leftCount += (item.items.count - index.row)
            } else {
                continue
            }
        }
        // 剩余个数为20的时候进行预加载.
        let needFetch = leftCount <= Utils.List.fetchCount.loadMore
        guard needFetch else {
            V3Home.logger.info("should not load more. left count \(leftCount), all count \(allItemCnt), section \(index.section), row \(index.row)")
            return
        }
        prefetchEnable = false
        actionDelegate?.doAction(by: .prefetch)
    }

}

extension V3ListView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.cellForItem(at: indexPath) != nil else { return }
        guard let guid = guid(by: indexPath) else { return }
        actionDelegate?.doAction(by: .didSelectItem(indexPath: indexPath, guid: guid))
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String,
                        at indexPath: IndexPath) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            guard let section = V3ListSectionData.safeCheckSection(in: indexPath.section, with: sectionModels),
                  let headerData = sectionModels[section].header, let header = view as? V3ListSectionHeaderView else {
                return
            }
            // 如果折叠或者分组数据中没有数据
            if headerData.isFold || (sectionModels[section].items.isEmpty && sectionModels[section].footer.isHidden) {
                header.containerView.lu.addCorner(
                    corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
                    cornerSize: CGSize(width: 10, height: 10)
                )
                header.containerView.clipsToBounds = true
            } else {
                header.containerView.lu.addCorner(
                    corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                    cornerSize: CGSize(width: 10, height: 10)
                )
                header.containerView.clipsToBounds = true
            }
        case UICollectionView.elementKindSectionFooter:
            guard let section = V3ListSectionData.safeCheckSection(in: indexPath.section, with: sectionModels),
                  let footer = view as? V3ListSectionFooterView else {
                return
            }
            var corners: CACornerMask = []
            if !sectionModels[section].footer.isHidden {
                corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            footer.containerView.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
            footer.containerView.clipsToBounds = true
        default:
            V3Home.assertionFailure()
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let (section, _) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels),
                let cell = cell as? V3ListCell else { return }
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        switch indexPath.row {
        case 0:
            var corners: CACornerMask = []
            // 分组section不显示的时候，需要处理左上、和右上
            if sectionModels[section].header == nil {
                corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
            }
            // 有且只有一个cell的时候需要处理左下、右下. 且footer不展示的时候
            if numberOfRows - 1 == 0, sectionModels[section].footer.isHidden {
                corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
        case numberOfRows - 1:
            var corners: CACornerMask = []
            if sectionModels[section].footer.isHidden {
                corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
        default:
            cell.lu.addCorner(
                corners: [],
                cornerSize: .zero
            )
        }
        cell.clipsToBounds = true
        // 显示骨架图
        DispatchQueue.main.async {
            cell.showSkeletonIfNeeded()
        }
        tryPrefetch(index: indexPath)
    }

}

extension V3ListView: UICollectionViewDragDelegate {

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let delegate = actionDelegate, delegate.canDrag(at: indexPath) else { return [] }
        guard let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels) else { return [] }
        let item = sectionModels[section].items[row]
        guard let cell = collectionView.cellForItem(at: indexPath) as? V3ListCell,
              cell.viewData?.todo.guid == item.todo.guid else { return [] }
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }

    /// 下面两个方法主要是处理跨分组拖拽场景，当分组为空的时候，需要额外在UI上插入一个cell。
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        var itemsToInsert = [IndexPath]()
        (0 ..< sectionModels.count).forEach {
            if sectionModels[$0].items.isEmpty {
                itemsToInsert.append(IndexPath(item: sectionModels[$0].items.count, section: $0))
                var item = V3ListCellData(with: Rust.Todo(), completeState: .outsider(isCompleted: false))
                item.contentType = .availableToDrop
                sectionModels[$0].items.append(item)
            }
            if !itemsToInsert.isEmpty {
                collectionView.reloadSections(indexSet(itemsToInsert.map(\.section)))
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        removeDropItem()
        collectionView.cancelInteractiveMovement()
        collectionView.endInteractiveMovement()
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return false
    }

}

extension V3ListView: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool { return true }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag, let indexPath = destinationIndexPath,
           let (section, row) = V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels) {
            switch sectionModels[section].items[row].contentType {
            case .availableToDrop:
                return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
            default:
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let targetIndexPath = coordinator.destinationIndexPath, let first = coordinator.items.first, let sourceIndexPath = first.sourceIndexPath, let item = first.dragItem.localObject as? V3ListCellData else {
            return
        }
        guard V3ListSectionData.safeCheckIndexPath(at: sourceIndexPath, with: sectionModels) != nil else {
            V3Home.logger.error("out of bounds. index \(sourceIndexPath)")
            return
        }
        collectionView.performBatchUpdates {
            sectionModels[sourceIndexPath.section].items.remove(at: sourceIndexPath.row)
            sectionModels[targetIndexPath.section].items.insert(item, at: targetIndexPath.row)
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [targetIndexPath])
        } completion: { [weak self] _ in
            guard let self = self else { return }
            let tuple = self.findNearestItem(by: targetIndexPath)
            self.actionDelegate?.doAction(
                by: .moveItem(
                    from: self.sectionModels[sourceIndexPath.section].sectionId,
                    to: self.sectionModels[targetIndexPath.section].sectionId,
                    preGuid: tuple.pre,
                    todo: item.todo,
                    nextGuid: tuple.next
                )
            )
        }
        // 动画
        coordinator.drop(first.dragItem, toItemAt: targetIndexPath)
        removeDropItem()
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        dragDropState.isDroping = true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        collectionView.endInteractiveMovement()
        dragDropState.isDroping = false
        if let reloadFailedData = dragDropState.reloadFailedData {
            V3Home.logger.info("try reload failed list data")
            reloadList(reloadFailedData, animated: false)
        }
    }

    private func removeDropItem() {
        var dataItems = [IndexPath](), uiItems = [IndexPath]()
        for section in 0..<sectionModels.count {
            let lastIndex = sectionModels[section].items.lastIndex { item in
                if case .availableToDrop = item.contentType {
                    return true
                }
                return false
            }
            if let lastIndex = lastIndex {
                let indexPath = IndexPath(item: lastIndex, section: section)
                dataItems.append(indexPath)
                if collectionView.numberOfItems(inSection: section) > 0 {
                    uiItems.append(indexPath)
                }
            }
        }
        if !dataItems.isEmpty {
            dataItems.forEach { sectionModels[$0.section].items.remove(at: $0.item) }
        }
        if !uiItems.isEmpty {
            collectionView.deleteItems(at: uiItems)
        }
    }

    private func findNearestItem(by indexPath: IndexPath) -> (pre: String?, next: String?) {
        guard V3ListSectionData.safeCheckIndexPath(at: indexPath, with: sectionModels) != nil else { return (nil, nil) }
        let sourceData = sectionModels
        // 二维数组拍平后取Index, 这时候完全有可能超出数组的下标
        var position: Int = 0, sectionFirst: Bool = false, sectionlLast: Bool = false
        for (index, section) in sourceData.enumerated() {
            if index < indexPath.section {
                position += section.items.count
            } else if index == indexPath.section {
                position += indexPath.row
                if indexPath.row == 0 {
                    sectionFirst = true
                }
                if indexPath.row == section.items.count - 1 {
                    sectionlLast = true
                }
            } else {
                break
            }
        }
        // 分组内只有条数据
        if sectionFirst, sectionlLast { return (nil, nil) }
        let items = sourceData.flatMap(\.items)
        let preIndex = position - 1, nextIndex = position + 1
        if sectionFirst {
            if nextIndex >= 0, nextIndex < items.count {
                return (nil, items[nextIndex].todo.guid)
            }
        }
        if sectionlLast {
            if preIndex >= 0, preIndex < items.count {
                return (items[preIndex].todo.guid, nil)
            }
        }
        guard preIndex >= 0, preIndex < items.count, nextIndex >= 0, nextIndex < items.count else {
            return (nil, nil)
        }
        return (items[preIndex].todo.guid, items[nextIndex].todo.guid)
    }
}

// MARK: - CheckBox

extension V3ListView: V3ListCellActionDelegate {

    func disabledAction(for checkbox: Checkbox, from sender: V3ListCell) -> CheckboxDisabledAction {
        return { }
    }

    func enabledAction(for checkbox: Checkbox, from sender: V3ListCell) -> CheckboxEnabledAction {
        guard let indexPath = collectionView.indexPath(for: sender), let guid = guid(by: indexPath) else {
            return .immediate { }
        }
        return actionDelegate?.enabledAction(at: indexPath, guid: guid, isFromSlide: false) ?? .immediate { }
    }

}

// MARK: - Batch Update

extension V3ListView {

    /// 刷新列表
    func reloadList(_ data: [V3ListSectionData], animated: Bool) {
        guard !dragDropState.isReordering
                && !collectionView.hasActiveDrag
                && !dragDropState.isDroping,
              !collectionView.hasUncommittedUpdates
        else {
            dragDropState.reloadFailedData = data
            V3Home.logger.info("reload list failed, \(dragDropState.isReordering), \(collectionView.hasActiveDrag), \(dragDropState.isDroping), \(collectionView.hasUncommittedUpdates)")
            return
        }
        dragDropState.reloadFailedData = nil
        let reloadData = { [weak self] (data: [V3ListSectionData]) in
            guard let self = self else { return }
            self.sectionModels = data
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
            self.prefetchEnable = true
        }
        if animated {
            do {
                let differences = try Diff.differencesForSectionedView(initialSections: sectionModels, finalSections: data)
                for difference in differences {
                    let updateBlock = { [weak self] () -> Void in
                        self?.batchUpdates(difference.finalSections, changes: difference)
                    }
                    collectionView.performBatchUpdates(updateBlock, completion: nil)
                }
            } catch let err {
                V3Home.logger.error("animated error: \(err.localizedDescription)")
                reloadData(data)
            }
        } else {
            reloadData(data)
        }
    }

    /// 选中
    func selectItem(at indexPath: IndexPath?) {
        if let indexPath = indexPath {
            // async 处理，渲染完了再处理
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.indexPathIsValid(indexPath: indexPath) else {
                    V3Home.assertionFailure("select cell failed")
                    return
                }
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }

    func scrollToItem(at indexPath: IndexPath?) {
        if let indexPath = indexPath {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.indexPathIsValid(indexPath: indexPath) else {
                    V3Home.logger.info("indexPath is not valided when scroll to item")
                    return
                }
                self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
            }
        }
    }

    /// 取消选中
    func deselectedItem() {
        guard let indexPaths = collectionView.indexPathsForSelectedItems else {
            return
        }
        indexPaths.forEach { indexPath in
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    private func batchUpdates<Section>(_ data: [V3ListSectionData], changes: Changeset<Section>) {
        sectionModels = data
        typealias Item = Section.Item

        collectionView.deleteSections(indexSet(changes.deletedSections))
        collectionView.insertSections(indexSet(changes.insertedSections))

        collectionView.deleteItems(at: changes.deletedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
        collectionView.insertItems(at: changes.insertedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
        collectionView.reloadItems(at: changes.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })

    }

    private func indexSet(_ values: [Int]) -> IndexSet {
        let indexSet = NSMutableIndexSet()
        for i in values {
            indexSet.add(i)
        }
        return indexSet as IndexSet
    }

    private func indexPathIsValid(indexPath: IndexPath) -> Bool {
        guard indexPath.section < collectionView.numberOfSections, indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) else {
            return false
        }
        return true
    }

}

// MARK: - Action Enum

extension V3ListView {

    enum ActionType: LogConvertible {
        // header & footer
        case headerMore(indexPath: IndexPath, sectionId: String, sourceView: UIView)
        case headerSelected(indexPath: IndexPath, sectionId: String)
        case footerSelected(indexPath: IndexPath, sectionId: String)

        // prefetch
        case prefetch
        // 重新获取
        case retryFetch

        // click
        case didSelectItem(indexPath: IndexPath, guid: String)

        // swipe
        case swipeItem(indexPath: IndexPath, guid: String)
        case didSwipe
        case didSelectSwipeItem(descriptor: V3SwipeActionDescriptor, indexPath: IndexPath, guid: String)

        // drag & drop
        case moveItem(from: String, to: String, preGuid: String?, todo: Rust.Todo, nextGuid: String?)

        var logInfo: String {
            switch self {
            case .headerSelected(let indexPath, let sectionId):
                return "section header selected at \(indexPath), id \(sectionId)"
            case .headerMore:
                return "did click section more"
            case .footerSelected(let indexPath, let sectionId):
                return "footer selected at \(indexPath), id \(sectionId)"
            case .prefetch:
                return "pre fetch"
            case .retryFetch:
                return "retry fetch"
            case .didSelectItem(let indexPath, let guid):
                return "did selected item \(indexPath), id \(guid)"
            case .swipeItem:
                return "swipe item"
            case .didSwipe:
                return "did swipe"
            case .didSelectSwipeItem(let descriptor, _, let guid):
                return "did selected swipe item, action: \(descriptor.title), guid \(guid)"
            case .moveItem(let from, let to, let preGuid, let todo, let nextGuid):
                return "move item from \(from), to \(to), pre \(preGuid ?? ""), guid: \(todo.guid), next \(nextGuid ?? "")"
            }
        }

    }

}

// MARK: - Swipe

extension V3ListView: SwipeCollectionViewCellDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        editActionsForItemAt indexPath: IndexPath,
        for orientation: SwipeActionsOrientation
    ) -> [SwipeAction]? {
        guard collectionView.cellForItem(at: indexPath) != nil else { return nil }
        guard let guid = guid(by: indexPath) else { return nil }
        actionDelegate?.doAction(by: .swipeItem(indexPath: indexPath, guid: guid))
        guard let descriptors = actionDelegate?.getSwipeDescriptor(at: indexPath, guid: guid) else { return nil }
        switch orientation {
        case .left: return descriptors.filter { $0.belongLeft }.map { makeAction(with: $0) }
        case .right: return descriptors.filter { $0.belongRight }.map { makeAction(with: $0) }
        @unknown default: return nil
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        editActionsOptionsForItemAt indexPath: IndexPath,
        for orientation: SwipeActionsOrientation
    ) -> SwipeOptions {
        actionDelegate?.doAction(by: .didSwipe)
        var options = SwipeOptions()
        options.transitionStyle = .border
        options.buttonHorizontalPadding = 20
        options.minimumButtonWidth = 92
        options.buttonStyle = .horizontal
        options.buttonSpacing = 4
        options.transitionStyle = .border
        // 优化左右/上下滑动触发机制, 调整角度使横向手势触发概率变小；目前参数定制为拖拽角度小于 35 度触发
        options.shouldBegin = { (originX, originY) in
            return abs(originY) * 1.4 < abs(originX)
        }
        return options
    }

    private func makeAction(with descriptor: V3SwipeActionDescriptor) -> SwipeAction {
        let action = SwipeAction(style: .default, title: nil) { [weak self] (_, indexPath, _) in
            guard let self = self, let guid = self.guid(by: indexPath) else { return }
            self.actionDelegate?.doAction(by: .didSelectSwipeItem(descriptor: descriptor, indexPath: indexPath, guid: guid))
        }
        action.title = descriptor.title
        action.image = descriptor.image.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        action.textColor = UIColor.ud.primaryOnPrimaryFill
        action.backgroundColor = descriptor.backgroundColor
        action.font = descriptor.font
        action.hidesWhenSelected = true
        return action
    }

}

extension V3ListView {

    func updateViewState(state: ListViewState, emptyText: String) {
        stateView.bottomInset = collectionView.adjustedContentInset.bottom
        stateView.updateViewState(state: state, emptyDescription: emptyText)
    }
}

// MARK: - StateView

final class ListStateView {

    var retryHandler: (() -> Void)?
    var bottomInset: CGFloat? {
        didSet {
            if oldValue != bottomInset {
                stateViews.empty = nil
                stateViews.failed = nil
            }
        }
    }

    private weak var sourceView: UIView?
    private weak var targetView: UIView?
    private var backgroundColor: UIColor?
    /// 列表空状态
    private var stateViews: (
        loading: LoadingPlaceholderView?,  // 加载中
        empty: UDEmptyView?,             // 空白页
        failed: UDEmptyView?          // 加载失败
    )

    init(with sourceView: UIView, targetView: UIView, bottomInset: CGFloat? = 0, backgroundColor: UIColor?) {
        self.targetView = targetView
        self.sourceView = sourceView
        self.bottomInset = bottomInset
        self.backgroundColor = backgroundColor
    }

    func cleanEmptyView() {
        stateViews.empty = nil
    }

    func updateViewState(
        state: ListViewState,
        emptyType: UDEmptyType = .done,
        emptyTitle: String = "",
        emptyDescription: String = "",
        loadingText: String = "",
        failedText: String = ""
    ) {
        var hiddens = (empty: true, loading: true, failed: true)
        var target: UIView?
        switch state {
        case .idle, .data:
            target = targetView
        case .empty:
            if stateViews.empty == nil {
                let emptyView = lazyInitEmptyView(title: emptyTitle, descriptionText: emptyDescription, type: emptyType)
                sourceView?.addSubview(emptyView)
                emptyView.snp.makeConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomInset ?? 0)
                }
                stateViews.empty = emptyView
            }
            hiddens.empty = false
            target = stateViews.empty
        case .failed(let failedState):
            if stateViews.failed == nil {
                let failedView = lazyInitFaildRetryView(state: failedState, text: failedText)
                sourceView?.addSubview(failedView)
                failedView.snp.makeConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomInset ?? 0)
                }
                stateViews.failed = failedView
            }
            hiddens.failed = false
            target = stateViews.failed
        case .loading:
            if stateViews.loading == nil {
                let loadingView = lazyInitLoadingView(loadingText: loadingText)
                sourceView?.addSubview(loadingView)
                loadingView.snp.makeConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
                stateViews.loading = loadingView
            }
            hiddens.loading = false
            target = stateViews.loading
        }
        if let target = target {
            sourceView?.bringSubviewToFront(target)
        }
        stateViews.empty?.isHidden = hiddens.empty
        stateViews.failed?.isHidden = hiddens.failed
        stateViews.loading?.isHidden = hiddens.loading
    }

    private func lazyInitEmptyView(title: String, descriptionText: String, type: UDEmptyType) -> UDEmptyView {
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: descriptionText,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        var titleConfig: UDEmptyConfig.Title?
        if !title.isEmpty {
            titleConfig = UDEmptyConfig.Title(titleText: title)
        }

        let view = UDEmptyView(config: UDEmptyConfig(
            title: titleConfig,
            description: description,
            type: type
        ))
        view.backgroundColor = backgroundColor
        view.useCenterConstraints = true
        return view
    }

    private func lazyInitLoadingView(loadingText: String = "") -> LoadingPlaceholderView {
        let loadingView = LoadingPlaceholderView()
        loadingView.isHidden = true
        if !loadingText.isEmpty {
            loadingView.text = loadingText
        }
        loadingView.backgroundColor = backgroundColor
        return loadingView
    }

    private func lazyInitFaildRetryView(state: ViewStateFailure, text: String) -> UDEmptyView {
        let title = text.isEmpty ? I18N.Lark_Legacy_LoadFailedRetryTip : text
        let type: UDEmptyType = state == .noAuth ? .noAccess : .loadingFailure
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: title,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let failedView = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: type
        ))
        failedView.clickHandler = { [weak self] in
            if state == .none || state == .needsRetry {
                self?.retryHandler?()
            }
        }
        failedView.backgroundColor = backgroundColor
        failedView.useCenterConstraints = true
        return failedView
    }
}
