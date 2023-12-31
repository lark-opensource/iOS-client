//
//  TreeView.swift
//  SKWiki
//
//  Created by 邱沛 on 2021/3/22.
//
// swiftlint:disable file_length cyclomatic_complexity

import Foundation
import RxSwift
import RxDataSources
import RxCocoa
import SKFoundation
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignDialog
import SKCommon
import SKSpace
import EENavigator
import SKUIKit
import UIKit
import SpaceInterface
import SKWorkspace

protocol TreeViewRouter: AnyObject {
    // 用到新的再拓展
    func treeView(_ treeView: TreeView, openURL url: URL)
}

class TreeView: UIView {
    // tableView 数据源，只能在主线程进行操作，更新后需要手动触发 tableView 更新
    private var listData: [NodeSection] = []
    private var differ = TreeViewListDiffer()
    private let dataQueue = DispatchQueue(label: "wiki.tree.view.dataQueue")
    private(set) lazy var dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue,
                                                                            internalSerialQueueName: "wiki.tree.view.dataQueueScheduler")


    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        if #available(iOS 15.0, *) {
            tableView.fillerRowHeight = 0
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(TreeTableViewCell.self,
                           forCellReuseIdentifier: TreeTableViewCell.reuseIdentifier)
        tableView.register(TreeTableViewEmptyCell.self,
                           forCellReuseIdentifier: TreeTableViewEmptyCell.reuseIdentifier)
        tableView.register(TreeHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: TreeHeaderView.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.sectionFooterHeight = 0.5
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UDColor.bgBody
        tableView.separatorStyle = .none
        tableView.rx.setDelegate(self).disposed(by: bag)
        tableView.dataSource = self
        return tableView
    }()

    let mutexHelper = SKCustomSlideMutexHelper()
    
    private(set) lazy var horizonIndicator: TreeViewHorizonIndicator = {
        let v = TreeViewHorizonIndicator()
        v.isHidden = true
        v.alpha = 0
        v.delegate = self
        return v
    }()

    private(set) lazy var doublePanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(swipDidChange(_:)))
        gesture.minimumNumberOfTouches = 2
        return gesture
    }()
    
    private(set) lazy var rightSwipeGesture: UIPanGestureRecognizer = {
        let rightSwipe = UIPanGestureRecognizer(target: self, action: #selector(rightSwipeDidChange))
        rightSwipe.minimumNumberOfTouches = 1
        rightSwipe.maximumNumberOfTouches = 1
        return rightSwipe
    }()

    private(set) lazy var gestureHandler: TreePanGestureHandler = {
        let gestureHandler = TreePanGestureHandler(singlePanGesture: rightSwipeGesture, doublePanGesture: doublePanGesture)
        return gestureHandler
    }()

    private let loadingView = DocsUDLoadingImageView()
    private weak var errorPage: UIView?

    private(set) var dataBuilder: TreeViewDataBuilder

    private let bag = DisposeBag()

    var currentTopMost: UIViewController? {
        guard let rootVC = window?.rootViewController else {
            spaceAssertionFailure("cannot get rootVC")
            return nil
        }
        return UIViewController.docs.topMost(of: rootVC)
    }
    var toastDisplayView: UIView {
        let theWindow: UIWindow?
        if let wd = self.window {
            theWindow = wd
        } else { // iOS 12 有可能获取不到self.window, 兜底
            theWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
        guard let window = theWindow else {
            spaceAssertionFailure("cannot get window")
            return self
        }
        return window
    }
    
    // 当前一屏节点宽度超出屏幕的offset
    var maxHorizonOffset: CGFloat {
        var maxSize = CGFloat()
        let cells = tableView.visibleCells
        cells.forEach { cell in
            guard let cell = cell as? TreeTableViewCell else {
                return
            }
            if cell.content.completeWidth > maxSize {
                maxSize = cell.content.completeWidth
            }
        }
        let offset = maxSize - frame.width
        return offset > 0 ? offset : CGFloat()
    }
    
    private var isReachable: Bool = true
    weak var treeViewRouter: TreeViewRouter?
    let showHorizonIndicator = BehaviorSubject<Bool>(value: false)

    init(dataBuilder: TreeViewDataBuilder) {
        self.dataBuilder = dataBuilder
        super.init(frame: .zero)
        _setupUI()
        _observeNetwork()
        showHorizonIndicatorIfNeed()
        setSwipeGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupUI() {
        addSubview(tableView)
        addSubview(loadingView)
        addSubview(horizonIndicator)
        
        tableView.snp.makeConstraints { (make) in
            make.center.size.equalToSuperview()
        }
        loadingView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.tableView.tableHeaderView?.bounds.height ?? 0)
        }
        
        horizonIndicator.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-31)
            make.height.equalTo(3)
        }
        
        loadingView.backgroundColor = UDColor.bgBody
        // 数据源更新
        dataBuilder
            .sectionRelay
            .observeOn(dataQueueScheduler)
            .subscribe(onNext: { [weak self] newData in
                guard let self = self else { return }
                self.handle(newData: newData)
                DispatchQueue.main.async {
                    guard !newData.isEmpty else {
                        return
                    }
                    if newData.allSatisfy(\.items.isEmpty) {
                        return
                    }
                    self.loadingView.isHidden = true
                }
            })
            .disposed(by: bag)

        dataBuilder.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(action: action)
            })
            .disposed(by: bag)
    }

    private func handle(action: WikiTreeViewAction) {
        switch action {
        case let .scrollTo(indexPath):
            // scrollTo 往往伴随着一次 state 的更新，此刻 state 可能还在 dataQueue 内算 diff，主线程的数据可能不包含即将 scrollTo 的节点
            // 进而导致滚动失效，为了解决这个问题，这里让 scrollTo 指令延后到 dataQueue 线程当前的任务后再执行
            dataQueue.async { [weak self] in
                DispatchQueue.main.async {
                    self?.scrollTo(indexPath: indexPath)
                }
            }
        case let .simulateClickState(nodeUID):
            // simulateClick 往往伴随一次 state 更新，参考 scrollTo 的逻辑，需要延后到当前 dataQueue 任务后执行
            dataQueue.async { [weak self] in
                DispatchQueue.main.async {
                    self?.simulateClickNode(nodeUID: nodeUID)
                }
            }
        case let .reloadSectionHeader(section, node):
            guard let headerView = tableView.headerView(forSection: section) as? TreeHeaderView else {
                return
            }
            setup(headerView: headerView, section: section, node: node)
        case let .present(provider, popoverConfig):
            let controller = provider(self)
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfig?(controller)
            }
            currentTopMost?.present(controller, animated: true) {
                // present 没有给调用方传入一个 completion 的参数，直接改现有代码改动量太大。
                // 考虑到present一个带键盘的 dialog 后，自动唤起键盘体验比较好，这里统一处理下
                if let dialog = controller as? UDDialog,
                   dialog.customMode == .input {
                    dialog.textField.becomeFirstResponder()
                }
            }
        case let .dismiss(controller):
            controller?.dismiss(animated: true)
        case let .push(controller):
            currentTopMost?.navigationController?.pushViewController(controller, animated: true)
        case let .pushURL(url):
            guard let router = treeViewRouter else {
                spaceAssertionFailure()
                return
            }
            router.treeView(self, openURL: url)
        case .showLoading:
            errorPage?.removeFromSuperview()
            tableView.isScrollEnabled = true
            loadingView.isHidden = false
            bringSubviewToFront(loadingView)
        case let .showErrorPage(errorView):
            self.addSubview(errorView)
            errorView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.tableView.isScrollEnabled = false
            self.errorPage = errorView
        case let .showHUD(subAction):
            handle(action: subAction)
        case .hideHUD:
            UDToast.removeToast(on: toastDisplayView)
        case let .customAction(compeletion):
            compeletion(currentTopMost)
        }
    }

    private func handle(action: WikiTreeViewAction.HUDAction) {
        UDToast.removeToast(on: toastDisplayView)
        switch action {
        case let .customLoading(text):
            UDToast.showLoading(with: text,
                                on: toastDisplayView,
                                disableUserInteraction: true)
        case let .failure(text):
            UDToast.showFailure(with: text, on: toastDisplayView)
        case let .success(text):
            UDToast.showSuccess(with: text, on: toastDisplayView)
        case let .tips(text):
            UDToast.showTips(with: text, on: toastDisplayView)
        case let .custom(config, operationCallback):
            UDToast.showToast(with: config, on: toastDisplayView, operationCallBack: { [weak self] buttonText in
                guard let self = self else {
                    return
                }
                UDToast.removeToast(on: self.toastDisplayView)
                operationCallback?(buttonText)
            })
        }
    }

    // 这里要回到主线程执行
    private func scrollTo(indexPath: IndexPath) {
        guard indexPath.section < listData.count else {
            DocsLogger.error("scroll to out of bound index path", extraInfo: ["indexPath": indexPath, "count": listData.count])
            return
        }
        let count = tableView.numberOfRows(inSection: indexPath.section)
        guard indexPath.row < count else {
            DocsLogger.error("scroll to out of bound index path", extraInfo: ["indexPath": indexPath, "count": count])
            return
        }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        didUpdateListData()
    }

    private func simulateClickNode(nodeUID: WikiTreeNodeUID) {
        if let sectionIndex = listData.firstIndex(where: { $0.headerNode?.diffId == nodeUID }),
           let view = tableView.headerView(forSection: sectionIndex),
           let headerView = view as? TreeHeaderView {
            // 模拟点击的是 sectionHeader
            headerView.clickStateInput.accept(())
            return
        }

        let cells = tableView.visibleCells.compactMap { $0 as? TreeTableViewCell }
        guard let cell = cells.first(where: { cell in cell.content.node.diffId == nodeUID }) else {
            // 模拟点击不可见的 node 暂时没有效果
            DocsLogger.warning("simulate click node not visible")
            return
        }
        // 模拟一次点击
        cell.content.clickStateInput.accept(())
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        self.loadingView.snp.updateConstraints { (make) in
            make.top.equalTo(self.tableView.tableHeaderView?.bounds.height ?? 0)
        }
    }

    private func _observeNetwork() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
            DocsLogger.debug("Current networkType is \(networkType)")
            self?.isReachable = isReachable
            self?.tableView.reloadData()
        }
    }
    
    // 滚动条的展示与隐藏
    func showHorizonIndicatorIfNeed() {
        showHorizonIndicator
            .subscribe(onNext: {[weak self] show in
            guard let self = self else { return }
            if show {
                self.horizonIndicator.isHidden = false
                UIView.animate(withDuration: 0.5, delay: 0, animations: {
                    self.horizonIndicator.alpha = 1
                })
            } else {
                UIView.animate(withDuration: 0.5, delay: 1, animations: {
                    self.horizonIndicator.alpha = 0
                }) {[weak self] _ in
                    self?.horizonIndicator.isHidden = true
                }
            }
        }).disposed(by: bag)
    }

    deinit {
        print("TreeView deinit")
    }
}

extension TreeView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        listData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < listData.count else {
            DocsLogger.error("out of bound section: \(section), count: \(listData.count)")
            return 0
        }
        return listData[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < listData.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TreeTableViewEmptyCell.reuseIdentifier, for: indexPath)
            return cell
        }
        let sectionData = listData[indexPath.section]
        guard indexPath.row < sectionData.items.count else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TreeTableViewEmptyCell.reuseIdentifier, for: indexPath)
            return cell
        }
        let node = sectionData.items[indexPath.row]
        switch node.type {
        case .empty:
            let cell = tableView.dequeueReusableCell(withIdentifier: TreeTableViewEmptyCell.reuseIdentifier,
                                                     for: indexPath)
            guard let emptyCell = cell as? TreeTableViewEmptyCell else {
                return cell
            }
            emptyCell.selectionStyle = .none
            emptyCell.update(title: node.title, level: node.level, offset: horizonIndicator.currentHorizonOffset)
            return emptyCell
        case .normal:
            let cell = tableView.dequeueReusableCell(withIdentifier: TreeTableViewCell.reuseIdentifier,
                                                     for: indexPath)
            guard let nodeCell = cell as? TreeTableViewCell else {
                return cell
            }
            if indexPath.row >= 1 {
                let preIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                let preCell = tableView.cellForRow(at: preIndexPath)
                let preNode = sectionData.items[preIndexPath.row]
                if let preCell = preCell as? TreeTableViewCell, !preNode.isSelected {
                    preCell.content.segmentLine.isHidden = node.isSelected
                }
            }
            nodeCell.selectionStyle = .none
            nodeCell.updateModel(node, offset: horizonIndicator.currentHorizonOffset)
            nodeCell.content.clickStateSignal.emit(onNext: { [weak self, weak nodeCell] in
                if !node.isOpened {
                    nodeCell?.content.nodeLoadingView.isHidden = false
                    nodeCell?.content.nodeLoadingView.play()
                    nodeCell?.content.stateButton.isHidden = true
                    self?.markNodeAsLoading(indexPath: indexPath)
                }
                node.clickStateAction(indexPath)
            }).disposed(by: nodeCell.reuseBag)
            nodeCell.content.titleButton.rx.tap.subscribe(onNext: {
                node.clickContentAction(indexPath)
            }).disposed(by: nodeCell.reuseBag)
            nodeCell.configSlideItem { [weak self, weak nodeCell] in
                guard let self, let nodeCell else { return (nil, nil) }
                let items = self.slideItems(for: node, cell: nodeCell)
                return (items, self.mutexHelper)
            }
            return nodeCell
        case .wikiSpace:
            spaceAssertionFailure("wiki tree view should not have wikispace node!!!")
            let cell = tableView.dequeueReusableCell(withIdentifier: TreeTableViewCell.reuseIdentifier, for: indexPath)
            return cell
        }
    }

    // 标记 node 为 loading，避免展开时网络请求失败后，loading 不消失问题
    private func markNodeAsLoading(indexPath: IndexPath) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            var listData = self.differ.currentList
            guard indexPath.section < listData.count else {
                return
            }
            var sectionData = listData[indexPath.section]
            var items = sectionData.items
            guard indexPath.row < items.count else {
                return
            }
            var node = items[indexPath.row]
            node.isLoading = true
            items[indexPath.row] = node
            sectionData.updateItems(items)
            listData[indexPath.section] = sectionData
            self.differ.reset(newList: listData)
        }
    }

    // 此方法要在非主线程调用，避免阻塞主线程
    private func handle(newData: [NodeSection]) {
        let transaction = differ.handle(newList: newData)
        switch transaction {
        case .reload:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.listData = newData
                self.tableView.reloadData()
                self.reloadAllHeaders()
                self.didUpdateListData()
            }
        case let .update(changeSets):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                changeSets.forEach { changeSet in
                    self.apply(changeSet: changeSet)
                }
                // diff 后，拿到的最终数据里，sectionHeader 信息不准确，这里最终用入参的数据更新一下
                self.listData = newData
                self.reloadAllHeaders()
                self.didUpdateListData()
            }
        }
    }

    private func didUpdateListData() {
        horizonIndicator.updateMaxHorizonOffset(maxHorizonOffset)
        let horizonSize = horizonIndicator.maxHorizonOffset + frame.width
        let percent = horizonSize > 0 ? frame.width / horizonSize : 1
        horizonIndicator.updateIndicatorWidth(indicatorPercent: percent)
    }

    // 在主线程 apply update，并更新 data
    private func apply(changeSet: Changeset<NodeSection>) {

        let indexToPathTransform: (ItemPath) -> IndexPath = { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }

        tableView.performBatchUpdates {
            listData = changeSet.finalSections
            tableView.deleteSections(changeSet.deletedSections, animationStyle: .fade)
            tableView.insertSections(changeSet.insertedSections, animationStyle: .fade)
            changeSet.movedSections.forEach(tableView.moveSection(_:toSection:))

            tableView.deleteRows(at: changeSet.deletedItems.map(indexToPathTransform), with: .fade)
            tableView.insertRows(at: changeSet.insertedItems.map(indexToPathTransform), with: .fade)
            tableView.reloadRows(at: changeSet.updatedItems.map(indexToPathTransform), with: .none)
            changeSet.movedItems.forEach { (from, to) in
                tableView.moveRow(at: indexToPathTransform(from), to: indexToPathTransform(to))
            }
        }
    }

    private func reloadAllHeaders() {
        for (index, section) in listData.enumerated() {
            guard let headerView = tableView.headerView(forSection: index) as? TreeHeaderView else {
                DocsLogger.error("update header for section \(index) failed")
                continue
            }
            let node = section.headerNode ?? .default
            setup(headerView: headerView, section: index, node: node)
        }
    }
}

extension TreeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TreeHeaderView.reuseIdentifier) ?? TreeHeaderView(reuseIdentifier: TreeHeaderView.reuseIdentifier)

        guard let headerView = headerView as? TreeHeaderView else {
            spaceAssertionFailure()
            return nil
        }
        let headerNode = listData[section].headerNode ?? .default
        setup(headerView: headerView, section: section, node: headerNode)
        return headerView
    }

    private func setup(headerView: TreeHeaderView, section: Int, node: TreeNode) {
        headerView.update(node: node)
        headerView.clickStateSignal.emit(onNext: {
            node.clickStateAction(IndexPath(item: 0, section: section))
        }).disposed(by: headerView.reuseBag)
        headerView.titleButton.rx.tap.subscribe(onNext: {
            node.clickContentAction(IndexPath(item: 0, section: section))
        }).disposed(by: headerView.reuseBag)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let foot = UIView()
        foot.backgroundColor = .clear
        return foot
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = listData
        guard section < sections.count, section >= 0 else {
            DocsLogger.warning("TreeView -- out of bound section index \(section), count: \(sections.count)")
            return 0
        }
        return sections[section].headerNode == nil ? 0 : 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let totalSection = self.listData.count
        guard section >= 0 && section < totalSection else { return 0 }
        if section == (totalSection - 1) {
            return 0
        }
        return 12
    }

    private func slideItems(for node: TreeNode, cell: UITableViewCell) -> [SKCustomSlideItem]? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        guard let swipeActions = dataBuilder.configSlideAction(node: node) else {
            return nil
        }

        let actions = swipeActions.map { item -> SKCustomSlideItem in
            let handler = item.action
            let icon: UIImage
            let backgroundColor: UIColor
            if isReachable {
                icon = item.normalImage
                backgroundColor = item.normalBackgroundColor
            } else {
                icon = item.disabledImage
                backgroundColor = item.disabledBackgroundColor
            }
            let slideItem = SKCustomSlideItem(icon: icon, backgroundColor: backgroundColor) { _, _ in
                handler(cell, { _ in }, node, indexPath)
            }
            return slideItem
        }
        dataBuilder.input.swipeCell.accept((indexPath, node))
        return actions
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mutexHelper.listViewDidScroll()
    }
}
