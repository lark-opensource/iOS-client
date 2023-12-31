//
//  SheetTabSwitcherView.swift
//  SpaceKit
//
//  Created by 段晓琛 on 2019/7/16.
//  swiftlint:disable identifier_name file_length

import Foundation
import UIKit
import SnapKit
import RxSwift
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor

public final class SheetTabSwitcherView: UIView {

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.scrollDirection = .horizontal
        it.sectionInset = .zero
        it.minimumLineSpacing = 0
        it.minimumInteritemSpacing = 0
    }

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = []
        return preventer
    }()

    private lazy var tabCollectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout).construct { it in
        it.dataSource = self
        it.delegate = self
        it.showsHorizontalScrollIndicator = false
        it.showsVerticalScrollIndicator = false
        it.register(SheetTabCell.self, forCellWithReuseIdentifier: "sheet.tab")
        it.backgroundColor = UIColor.ud.N200 & UIColor.ud.bgBase
        it.clipsToBounds = true
        it.layer.masksToBounds = true
        it.dragDelegate = self
        it.dropDelegate = self
    }

    private var tabCollectionRightSafeAreaRightConstraint: Constraint?

    private lazy var exitLandscapeButton = ExitLandscapeButton(frame: .zero).construct { it in
        it.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(exitLandscapeMode)))
    }
    private var tabCollectionRightExitLandscapeButtonLeftConstraint: Constraint?

    private lazy var addNewSheetButton = AddNewSheetButton(frame: .zero).construct { it in
        it.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addNewSheet)))
        it.backgroundColor = UIColor.ud.N300 & UIColor.ud.bgBodyOverlay
    }

    private var tabCollectionRightAddNewSheetButtonLeftConstraint: Constraint?

    private var infos: [SheetTabInfo] = [] // 这里的 infos 已经是过滤掉隐藏 tab 的数据了

    private var selectedIndex: Int = 0

    static let preferredHeight: CGFloat = 36.0

    private var allowsSync = true

    private var canEditTab = false

    private var canEditSheet = false

    private var jsCallback = ""

    private var canShowExitLandscapeButton = true

    weak var delegate: SheetTabSwitcherDelegate?

    let disposeBag = DisposeBag()

    // Drag & Drop

    var dropContext: (sheetID: String, source: Int, destination: Int)?

    weak var forbidDropDelegate: SheetTabSwitcherViewForbidDropDelegate?

    private var restoreSyncAfter3SecondsTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
        addAllViews()
    }

    private func addAllViews() {
        addViewBackedBorder(side: .top, thickness: 1, color: UIColor.ud.N300)
        addViewBackedBorder(side: .bottom, thickness: 1, color: UIColor.ud.N300)

        let container: UIView
        if ViewCapturePreventer.isFeatureEnable {
            container = viewCapturePreventer.contentView
            self.addSubview(container)
            container.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            container = self
        }
        container.addSubview(tabCollectionView)
        container.addSubview(exitLandscapeButton)
        container.addSubview(addNewSheetButton)

        exitLandscapeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(1)
            make.bottom.equalToSuperview().inset(1)
            make.right.equalTo(container.safeAreaLayoutGuide.snp.right)
            make.width.equalTo(0)
        }
        exitLandscapeButton.isHidden = true

        addNewSheetButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(1)
            make.bottom.equalToSuperview().inset(1)
            make.right.equalTo(container.safeAreaLayoutGuide.snp.right)
            make.width.equalTo(0)
        }
        addNewSheetButton.isHidden = true

        tabCollectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(1)
            make.bottom.equalToSuperview().inset(1)
            tabCollectionRightSafeAreaRightConstraint = make.right.equalTo(container.safeAreaLayoutGuide.snp.right).constraint
            tabCollectionRightSafeAreaRightConstraint?.activate()
            tabCollectionRightExitLandscapeButtonLeftConstraint = make.right.equalTo(exitLandscapeButton.snp.left).constraint
            tabCollectionRightExitLandscapeButtonLeftConstraint?.deactivate()
            tabCollectionRightAddNewSheetButtonLeftConstraint = make.right.equalTo(addNewSheetButton.snp.left).constraint
            tabCollectionRightAddNewSheetButtonLeftConstraint?.deactivate()
            make.left.equalTo(container.safeAreaLayoutGuide.snp.left)
        }
    }

    func getSubviewRect(source: SheetTabOperationSource) -> Observable<CGRect?> {
        switch source.eventId {
        case .add:
            return Observable.just(addNewSheetButton.frame)
        case .operate:
            guard let sheetID = source.sheetId else { return Observable.just(nil) }
            for (index, info) in infos.enumerated() where info.id == sheetID {
                let indexPath = IndexPath(item: index, section: 0)
                let observable = ReplaySubject<CGRect?>.create(bufferSize: 1)
                let visibleIndexPaths = tabCollectionView.indexPathsForVisibleItems.sorted()
                if visibleIndexPaths.contains(indexPath),
                   indexPath != visibleIndexPaths.last && indexPath != visibleIndexPaths.first,
                   let targetItem = tabCollectionView.cellForItem(at: indexPath) {
                    let convertedRect = targetItem.convert(targetItem.bounds, to: self)
                    observable.onNext(convertedRect)
                } else {
                    scrollToIndexPath(IndexPath(item: index, section: 0))
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                        guard let targetItem = self?.tabCollectionView.cellForItem(at: indexPath) else {
                            observable.onNext(nil)
                            return
                        }
                        let convertedRect = targetItem.convert(targetItem.bounds, to: self)
                        observable.onNext(convertedRect)
                    }
                }
                return observable
            }
        default:
            return Observable.just(nil)
        }
        return Observable.just(nil)
    }

    func update(infos: [SheetTabInfo],
                tabEditable: Bool,
                sheetEditable: Bool,
                callback: String,
                canShowExitLandscapeButton: Bool = true) {
        DocsLogger.info("前端更新工作表栏数据",
                        extraInfo: ["tabs": infos.map(\.id), "tabEditable": tabEditable, "sheetEditable": sheetEditable],
                        component: LogComponents.sheetTab)
        canEditTab = tabEditable
        canEditSheet = sheetEditable
        self.canShowExitLandscapeButton = canShowExitLandscapeButton
        let isLandscapePhone = UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone
        tabCollectionView.dragInteractionEnabled = sheetEditable && !isLandscapePhone
        jsCallback = callback
        updateTrailingButton()
        guard allowsSync else {
            DocsLogger.info("由于当前处于 drag&drop，所以不予刷新数据", component: LogComponents.sheetTab)
            return
        }
        self.infos = infos
        selectedIndex = infos.firstIndex(where: { $0.isSelected }) ?? 0
        tabCollectionView.reloadData()
        tabCollectionView.collectionViewLayout.invalidateLayout()
        tabCollectionView.layoutIfNeeded()
        // 在刷完数据之后进行滚动
        scrollToSelectedItem()
    }

    func updateTrailingButton() {
        // 这里根据有无编辑权限来决定 UI，是因为只有 portrait 才可能有编辑权限，landscape 是不能编辑的，所以这么写代码逻辑会更简单
        if canEditTab {
            addNewSheetButton.snp.updateConstraints { (make) in
                make.width.equalTo(50)
            }
            exitLandscapeButton.snp.updateConstraints { (make) in
                make.width.equalTo(0)
            }
            tabCollectionRightSafeAreaRightConstraint?.deactivate()
            tabCollectionRightExitLandscapeButtonLeftConstraint?.deactivate()
            tabCollectionRightAddNewSheetButtonLeftConstraint?.activate()
            addNewSheetButton.isHidden = false
            exitLandscapeButton.isHidden = true
        } else {
            addNewSheetButton.snp.updateConstraints { (make) in
                make.width.equalTo(0)
            }
            exitLandscapeButton.snp.updateConstraints { (make) in
                make.width.equalTo(0)
            }
            addNewSheetButton.isHidden = true
            exitLandscapeButton.isHidden = true
            tabCollectionRightAddNewSheetButtonLeftConstraint?.deactivate()
            tabCollectionRightExitLandscapeButtonLeftConstraint?.deactivate()
            tabCollectionRightSafeAreaRightConstraint?.activate()
            let interfaceOrientation: UIInterfaceOrientation?
            if #available(iOS 13.0, *) {
                interfaceOrientation = window?.windowScene?.interfaceOrientation
            } else {
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            }
            if interfaceOrientation?.isLandscape == true && SKDisplay.phone && canShowExitLandscapeButton {
                exitLandscapeButton.snp.updateConstraints { (make) in
                    make.width.equalTo(exitLandscapeButton.neededWidth)
                }
                exitLandscapeButton.isHidden = false
                tabCollectionRightSafeAreaRightConstraint?.deactivate()
                tabCollectionRightExitLandscapeButtonLeftConstraint?.activate()
            }
        }
    }

    func scrollToSelectedItem() {
        if tabCollectionView.hasActiveDrag || tabCollectionView.hasActiveDrop {
            // 这个时候如果去 programatically 滚动 collection view，会多调用几次 cellForItemAt，进而导致 drag & drop 状态错误
            return
        }
        var nextHighlightedIndexPath: IndexPath?
        for (idx, info) in infos.enumerated() where info.isSelected {
            nextHighlightedIndexPath = IndexPath(item: idx, section: 0)
        }
        guard let indexPath = nextHighlightedIndexPath else {
            // 在这里踩过坑，如果 infos 是空，那么 indexPath 是无意义的，调用 scrollToItem(at:at:animated:) 时传入会 crash
            return
        }
        scrollToIndexPath(indexPath)
    }

    func scrollToIndexPath(_ indexPath: IndexPath) {
        let visibleIndexPaths = tabCollectionView.indexPathsForVisibleItems.sorted()
        guard let firstVisibleIndexPath = visibleIndexPaths.first,
              let lastVisibleIndexPath = visibleIndexPaths.last
        else { return }
        if indexPath <= firstVisibleIndexPath {
            tabCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        } else if indexPath >= lastVisibleIndexPath {
            tabCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        }
    }

    func tapCell(at indexPath: IndexPath) {
        guard let cell = tabCollectionView.cellForItem(at: indexPath) as? SheetTabCell else { return }
        cell.tapped()
        if cell.tapCount == 2 {
            operateSheet(infos[indexPath.item].id)
        } else {
            switchToSheet(infos[indexPath.item].id)
        }
    }

    func untapCell(at indexPath: IndexPath) {
        guard let cell = tabCollectionView.cellForItem(at: indexPath) as? SheetTabCell else { return }
        cell.clearTapCount()
    }

    @objc
    private func exitLandscapeMode() {
        delegate?.forceOrientation(to: .portrait)
    }

    @objc
    private func addNewSheet() {
        DocsLogger.info("新建工作表", component: LogComponents.sheetTab)
        delegate?.callJSFunction(DocsJSCallBack(jsCallback), params: ["eventId": SheetTabOperationType.add.rawValue])
    }

    private func operateSheet(_ sheetID: String) {
        DocsLogger.info("操作工作表 \(sheetID)", component: LogComponents.sheetTab)
        delegate?.callJSFunction(DocsJSCallBack(jsCallback), params: ["eventId": SheetTabOperationType.operate.rawValue,
                                                                      "sheetId": sheetID])
    }

    private func switchToSheet(_ sheetID: String) {
        DocsLogger.info("切换到工作表 \(sheetID)", component: LogComponents.sheetTab)
        delegate?.callJSFunction(.onSwitchSheet, params: ["sheetId": sheetID])
    }

    private func commitReorderSheet(_ sheetID: String, sourceIndex: Int, destinationIndex: Int) {
        DocsLogger.info("将工作表 \(sheetID) 从 \(sourceIndex) 移至 \(destinationIndex)", component: LogComponents.sheetTab)
        delegate?.callJSFunction(DocsJSCallBack(jsCallback), params: ["eventId": SheetTabOperationType.reorder.rawValue,
                                                                      "sheetId": sheetID,
                                                                      "sourceIndex": sourceIndex,
                                                                      "targetIndex": destinationIndex])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SheetTabSwitcherView {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}

// MARK: 工作表栏右部按钮

extension SheetTabSwitcherView {
    private class ExitLandscapeButton: UIView {
        var neededWidth: CGFloat { buttonLeftMargin + buttonLeftRightPadding + textNeededWidth + buttonLeftRightPadding + buttonRightMargin }

        private var textNeededWidth: CGFloat = 0
        private var buttonLeftRightPadding: CGFloat = 12
        private var buttonLeftMargin: CGFloat = 16
        private var buttonRightMargin: CGFloat = 12

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear

            let label = UILabel(frame: .zero).construct { it in
                it.text = BundleI18n.SKResource.Doc_Sheet_ExitLandscape
                it.textColor = UIColor.ud.N900
                it.textAlignment = .center
                it.font = UIFont.systemFont(ofSize: 12)
                it.frame.size.height = 22
                it.layer.cornerRadius = 11
                it.layer.borderWidth = 0.5
                it.layer.masksToBounds = true
                it.layer.borderColor = UIColor.ud.N400.cgColor
            }
            textNeededWidth = label.text?.estimatedSingleLineUILabelWidth(in: label.font) ?? 0
            addSubview(label)
            label.layer.ud.setBackgroundColor(UIColor.ud.bgBody)
            label.snp.makeConstraints { (make) in
                make.height.equalTo(22)
                make.width.equalTo(buttonLeftRightPadding + textNeededWidth + buttonLeftRightPadding)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(buttonRightMargin)
            }

            let leftSeparator = UIView()
            leftSeparator.backgroundColor = UIColor.ud.N300
            addSubview(leftSeparator)
            leftSeparator.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(4)
                make.left.equalToSuperview()
                make.width.equalTo(1)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class AddNewSheetButton: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            let image = UIImageView(image: UDIcon.addOutlined.ud.withTintColor(UIColor.ud.iconN1))
            addSubview(image)
            image.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.height.width.equalTo(18)
            }

            let leftSeparator = UIView()
            leftSeparator.backgroundColor = UIColor.ud.N300 & UIColor.ud.bgBodyOverlay
            addSubview(leftSeparator)
            leftSeparator.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(4)
                make.left.equalToSuperview()
                make.width.equalTo(1)
            }
            // +号吸附效果太大会导致hover聚焦光标失败
            image.docs.addHighlight(with: .zero, radius: 8)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.backgroundColor = UIColor.ud.N300
            super.touchesBegan(touches, with: event)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.backgroundColor = UIColor.ud.N300
            super.touchesMoved(touches, with: event)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.backgroundColor = UIColor.ud.N200
            super.touchesCancelled(touches, with: event)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.backgroundColor = UIColor.ud.N200
            super.touchesEnded(touches, with: event)
        }
    }
}

// MARK: collection view 数据源和代理方法

extension SheetTabSwitcherView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: infos[indexPath.item].estimatedCellWidth(boundedByMaxWidth: collectionView.bounds.width * 0.4), height: 34)
    }
}

extension SheetTabSwitcherView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infos.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = tabCollectionView.dequeueReusableCell(withReuseIdentifier: "sheet.tab", for: indexPath)
                as? SheetTabCell else { return SheetTabCell() }
        let info = infos[indexPath.item]
        cell.update(info, selectedIndex: selectedIndex)
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.hasActiveDrop {
            DocsLogger.info("当前正在 drop，不允许点击 tab", component: LogComponents.sheetTab)
            return false
        }
        if !infos[indexPath.item].enabled {
            switchToSheet(infos[indexPath.item].id)
        }
        return infos[indexPath.item].enabled
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DocsLogger.info("选中第 \(indexPath.item) 个 tab，之前选中的是 \(selectedIndex)", component: LogComponents.sheetTab)
        let previousLightedTabIndexPath = IndexPath(item: selectedIndex, section: indexPath.section)
        if selectedIndex != indexPath.item {
            collectionView.deselectItem(at: previousLightedTabIndexPath, animated: false)
            infos[selectedIndex].isSelected = false
            selectedIndex = indexPath.item
            infos[selectedIndex].isSelected = true
            untapCell(at: previousLightedTabIndexPath)
            tapCell(at: indexPath)
            var updatingIndexPathSet: Set<IndexPath> = []
            updatingIndexPathSet.insert(IndexPath(item: max(0, previousLightedTabIndexPath.item - 1), section: previousLightedTabIndexPath.section))
            updatingIndexPathSet.insert(previousLightedTabIndexPath)
            updatingIndexPathSet.insert(IndexPath(item: min(previousLightedTabIndexPath.item + 1, infos.count - 1), section: previousLightedTabIndexPath.section))
            updatingIndexPathSet.insert(IndexPath(item: max(0, indexPath.item - 1), section: indexPath.section))
            updatingIndexPathSet.insert(indexPath)
            updatingIndexPathSet.insert(IndexPath(item: min(indexPath.item + 1, infos.count - 1), section: indexPath.section))
            let updatingIndexPaths = Array(updatingIndexPathSet)
            UIView.performWithoutAnimation {
                DocsLogger.info("刷新第 \(updatingIndexPaths.map(\.item)) 个 tab", component: LogComponents.sheetTab)
                collectionView.reloadItems(at: updatingIndexPaths)
            }
        } else if allowsSync {
            tapCell(at: indexPath)
        }
    }
}

// MARK: Drag & Drop 处理
// 踩坑记录：https://bytedance.feishu.cn/docx/doxcn4sllwZCxpPdSNqj1xL1Urf

extension SheetTabSwitcherView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    public func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication: UIDragSession) -> Bool { true }

    public func collectionView(_ collectionView: UICollectionView,
                               itemsForBeginning session: UIDragSession,
                               at indexPath: IndexPath) -> [UIDragItem] {
        DocsLogger.info("长按第 \(indexPath.item) 个 tab", component: LogComponents.sheetTab)
        if let next3Seconds = Calendar.current.date(byAdding: .second, value: 3, to: Date()) {
            DocsLogger.info("关闭协同", component: LogComponents.sheetTab)
            restoreSyncAfter3SecondsTimer?.invalidate()
            restoreSyncAfter3SecondsTimer = nil
            allowsSync = false
            let timer = Timer(fire: next3Seconds, interval: 3, repeats: false) { [weak self] _ in
                self?.allowsSync = true
                DocsLogger.info("用户放弃 drag & drop，恢复协同", component: LogComponents.sheetTab)
            }
            RunLoop.main.add(timer, forMode: .common)
            restoreSyncAfter3SecondsTimer = timer
        }
        untapCell(at: indexPath) // 长按已选中的 cell 时，需要清空 cell 的点击计数，避免下一句导致计数变成 2
        // Pro Tip: UICollectionView.ScrollPosition 是个 OptionSet，如果不想让他滚动可以设置空集合
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        self.collectionView(collectionView, didSelectItemAt: indexPath)
        let itemProvider = NSItemProvider(object: "\(infos[indexPath.item].text)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = infos[indexPath.item]
        return [dragItem]
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        DocsLogger.info("开始 drag session，关闭协同", component: LogComponents.sheetTab)
        allowsSync = false
        restoreSyncAfter3SecondsTimer?.invalidate()
        restoreSyncAfter3SecondsTimer = nil
        forbidDropDelegate?.addTransparentCollectionViewAboveWebview()
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        DocsLogger.info("结束 drag session", component: LogComponents.sheetTab)
        if !collectionView.hasActiveDrop {
            DocsLogger.info("开启协同", component: LogComponents.sheetTab)
            allowsSync = true
        }
        forbidDropDelegate?.removeTransparentCollectionView()
    }

    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let isLandscapePhone = UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone
        return canEditSheet && session.localDragSession != nil && !isLandscapePhone
    }

    public func collectionView(_ collectionView: UICollectionView,
                               dropSessionDidUpdate session: UIDropSession,
                               withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag, destinationIndexPath != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        DocsLogger.info("开始 drop，关闭协同", component: LogComponents.sheetTab)
        allowsSync = false
        collectionView.isScrollEnabled = false // 避免额外的 cellForItemAt 调用影响 drop
        collectionView.dragInteractionEnabled = false // 避免 didSelectItemAt 调用影响 drop
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            destinationIndexPath = IndexPath(item: infos.count - 1, section: 0)
        }

        switch coordinator.proposal.operation {
        case .move:
            reorderTabs(in: collectionView, with: coordinator, at: destinationIndexPath)
        default:
            allowsSync = true
            return
        }
    }

    private func reorderTabs(in collectionView: UICollectionView,
                             with coordinator: UICollectionViewDropCoordinator,
                             at destinationIndexPath: IndexPath) {
        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath, let target = item.dragItem.localObject as? SheetTabInfo {
            infos.remove(at: sourceIndexPath.item)
            infos.insert(target, at: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            dropContext = (target.id, sourceIndexPath.item, destinationIndexPath.item)
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        DocsLogger.info("结束 drop session", component: LogComponents.sheetTab)
        collectionView.isScrollEnabled = true
        if !collectionView.hasActiveDrag {
            DocsLogger.info("开启协同", component: LogComponents.sheetTab)
            allowsSync = true
        }
        if let (sheetID, source, destination) = dropContext {
            commitReorderSheet(sheetID, sourceIndex: source, destinationIndex: destination)
            dropContext = nil
        }
    }
}
