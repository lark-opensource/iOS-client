//
//  WikiPickerTreeViewModel.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/22.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor
import SKWorkspace

// ViewModel 的方法、属性要保证在主线程可安全使用
class WikiPickerTreeViewModel {
    private let sectionsRelay = BehaviorRelay<[NodeSection]>(value: [])
    var sectionsDriver: Driver<[NodeSection]> { sectionsRelay.asDriver() }
    // viewModel 持有一份 treeState 用于业务判断，但不会直接修改 treeState
    let treeStateRelay = BehaviorRelay<WikiTreeState>(value: .empty)
    var selectedWikiToken: String? { treeStateRelay.value.viewState.selectedWikiToken }
    var selectedNode: WikiTreeNodeMeta? {
        guard let selectedWikiToken = selectedWikiToken else {
            return nil
        }
        let metas = treeStateRelay.value.metaStorage
        return metas[selectedWikiToken]
    }
    private(set) var dataState: ServerDataState = .loading

    // space 信息
    private let spaceInfoRelay = BehaviorRelay<WikiSpace?>(value: nil)
    var spaceInfo: WikiSpace? { spaceInfoRelay.value }

    let reloadInput = PublishRelay<Void>()

    let actionInput = PublishRelay<WikiTreeViewAction>()
    var actionSignal: Signal<WikiTreeViewAction> { actionInput.asSignal() }

    let scrollByUIDInput = PublishRelay<WikiTreeNodeUID>()

    private let workQueue = DispatchQueue(label: "wiki.picker.tree.vm")
    private lazy var workQueueScheduler = SerialDispatchQueueScheduler(queue: workQueue,
                                                                       internalSerialQueueName: "wiki.picker.tree.scheduler.vm")
    let disposeBag = DisposeBag()

    let dataModel: WikiPickerTreeDataModelType
    private let converterProvider: WikiPickerTreeConverterProviderType
    let interactionHandler: WikiInteractionHandler
    var disabledToken: String? { converterProvider.disabledToken }

    convenience init(spaceID: String,
                     wikiToken: String?,
                     disabledToken: String?) {
        let dataModel = WikiTreeDataModel(spaceID: spaceID,
                                          initialWikiToken: wikiToken,
                                          scene: .documentDraggablePage,
                                          networkAPI: WikiNetworkManager.shared,
                                          cacheAPI: WikiTreeCacheHandle.shared,
                                          processor: WikiTreeDataProcessor())
        let converterProvider = WikiPickerTreeConverterProvider(disabledToken: disabledToken)
        self.init(dataModel: dataModel, converterProvider: converterProvider, interactionHandler: WikiInteractionHandler())
    }

    init(dataModel: WikiPickerTreeDataModelType,
         converterProvider: WikiPickerTreeConverterProviderType,
         interactionHandler: WikiInteractionHandler) {
        self.dataModel = dataModel
        self.interactionHandler = interactionHandler
        self.converterProvider = converterProvider
        self.converterProvider.clickHandler = self
    }

    func setup() {
        treeStateRelay.skip(1)
            .observeOn(workQueueScheduler)
            .map { [weak self] state -> [NodeSection] in
                if state.isEmpty { return [] }
                guard let self = self else { return [] }
                let converter = self.converterProvider.converter(treeState: state)
                var rootList: [(TreeNodeRootSection, String)] = []
                let sharedRootToken = state.metaStorage[WikiTreeNodeMeta.sharedRootToken]?.wikiToken
                // 是否展示空间目录树，取决于后端有没有下发 mainRootMeta
                if let mainRootToken = state.metaStorage.first(where: { $1.nodeType == .mainRoot })?.key {
                    rootList.append((.mainRoot, mainRootToken))
                }
                if let sharedRootToken = sharedRootToken {
                    rootList.append((.sharedRoot, sharedRootToken))
                }
                if rootList.isEmpty { return [] }
                return converter.convert(rootList: rootList)
            }
            .bind(to: sectionsRelay)
            .disposed(by: disposeBag)

        scrollByUIDInput
            .observeOn(workQueueScheduler)
            .subscribe(onNext: { [weak self] targetUID in
                guard let self = self else { return }
                let sections = self.sectionsRelay.value
                for (sectionIndex, section) in sections.enumerated() {
                    guard let rowIndex = section.items.firstIndex(where: { $0.diffId == targetUID }) else {
                        continue
                    }
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    self.actionInput.accept(.scrollTo(indexPath: indexPath))
                    return
                }
            })
            .disposed(by: disposeBag)

        dataModel.spaceInfoUpdated
            .drive(spaceInfoRelay)
            .disposed(by: disposeBag)

        dataModel.restore()
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] state -> Maybe<WikiTreeState> in
                guard let self = self else { return .just(state) }
                if let initialWikiToken = self.dataModel.initialWikiToken {
                    let section = WikiTreeDataProcessor.getNodeSection(wikiToken: initialWikiToken, treeState: state)
                    let nodeUID = WikiTreeNodeUID(wikiToken: initialWikiToken,
                                                  section: section ?? .mainRoot,
                                                  shortcutPath: "")
                    return self.dataModel.select(wikiToken: initialWikiToken, nodeUID: nodeUID).asMaybe()
                } else if let mainRootToken = state.metaStorage.first(where: { $1.nodeType == .mainRoot })?.key {
                    return self.dataModel.select(wikiToken: mainRootToken, nodeUID: nil).asMaybe()
                } else {
                    spaceAssertionFailure("mainRoot not found in cache state")
                    return .just(state)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                DocsLogger.info("picker tree restore from cache")
                self.treeStateRelay.accept(state)
                if let selectedToken = state.viewState.selectedWikiToken {
                    self.focusNode(wikiToken: selectedToken, needLoading: false)
                }
            } onError: { error in
                DocsLogger.error("picker tree load cache failed with error", error: error)
            } onCompleted: {
                DocsLogger.info("picker tree found no cache")
            }
            .disposed(by: disposeBag)

        reload()
    }

    func reload() {
        // reload 里不会尝试重新加载缓存，因为通常而言需要重试的场合都不存在缓存
        dataModel.reload()
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (state, cacheLoaded) -> Single<(WikiTreeState, Bool)> in
                guard let self = self else { return .just((state, cacheLoaded)) }
                // 首次加载默认高亮逻辑
                if let initialWikiToken = self.dataModel.initialWikiToken {
                    let section = WikiTreeDataProcessor.getNodeSection(wikiToken: initialWikiToken, treeState: state)
                    let initialNodeUID = WikiTreeNodeUID(wikiToken: initialWikiToken,
                                                         section: section ?? .mainRoot,
                                                         shortcutPath: "")
                    return self.dataModel.select(wikiToken: initialWikiToken, nodeUID: initialNodeUID)
                        .map { ($0, cacheLoaded) }
                } else if !cacheLoaded {
                    guard let mainRootToken = state.metaStorage.first(where: { $1.nodeType == .mainRoot })?.key else {
                        spaceAssertionFailure("main root token not found in server data")
                        return .just((state, cacheLoaded))
                    }
                    return self.dataModel.select(wikiToken: mainRootToken, nodeUID: nil)
                        .map { ($0, cacheLoaded) }
                } else {
                    return .just((state, cacheLoaded))
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state, cacheLoaded in
                DocsLogger.info("picker tree reload from server")
                guard let self = self else { return }
                self.dataState = .synced
                self.treeStateRelay.accept(state)
                if !cacheLoaded,
                   let selectedWikiToken = state.viewState.selectedWikiToken {
                    self.focusNode(wikiToken: selectedWikiToken, needLoading: false)
                }
            } onError: { [weak self] error in
                DocsLogger.error("picker tree reload from server failed with error", error: error)
                guard let self = self else { return }
                self.dataState = .fetchFailed(error: error)
                // 重放一次触发 UI 刷新
                self.treeStateRelay.accept(self.treeStateRelay.value)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - Click Handler
extension WikiPickerTreeViewModel: WikiTreeConverterClickHandler {
    func configDidClickNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self = self else { return }
            // 游离树根节点禁止选中
            if meta.nodeType == .sharedRoot {
                self.toggleExpand(meta: meta, nodeUID: node.diffId)
                return
            }
            // 非叶子节点才可以展开
            self.didSelect(meta: meta, nodeUID: node.diffId, canExpand: !node.isLeaf)
        }
    }

    func configDidToggleNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self = self else { return }
            self.toggleExpand(meta: meta, nodeUID: node.diffId)
        }
    }

    func configAccessoryItem(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeNodeAccessoryItem? {
        let showAddItem = meta.nodeType == .mainRoot && UserScopeNoChangeFG.WWJ.newSpaceTabEnable
        // 仅节点选中时才展示创建按钮 /  新首页MVP知识库根目录下固定展示加号按钮
        guard node.isSelected || showAddItem else {
            return nil
        }
        return TreeNodeAccessoryItem(identifier: "create-on-picker-tree",
                                     image: UDIcon.getIconByKeyNoLimitSize(.addOutlined,
                                                                           iconColor: UDColor.iconN1),
                                     handler: { [weak self] _ in
            self?.didClickCreateItem(meta: meta, node: node)
        })
    }

    func didSelect(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID, canExpand: Bool) {
        dataModel.select(wikiToken: meta.wikiToken, nodeUID: nodeUID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
                guard canExpand else { return }
                if state.viewState.expandedUIDs.contains(nodeUID) { return }
                // 新增逻辑，picker 选中节点时，若节点没有展开，需要额外展开一下
                // 为了触发节点 loading 动画，这里抛一个事件模拟一次点击操作
                // 注意这里要把事件派发到 workQueue，保证在 select 事件刷新 UI 后再触发，否则 loading 动画会被 update 效果隐藏掉
                self.workQueue.async {
                    self.actionInput.accept(.simulateClickState(nodeUID: nodeUID))
                }
            } onError: { error in
                DocsLogger.error("select node failed?", error: error)
            }
            .disposed(by: disposeBag)
    }

    func toggleExpand(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID) {
        let currentState = treeStateRelay.value
        guard !currentState.viewState.expandedUIDs.contains(nodeUID) else {
            // 折叠比较简单
            dataModel.collapse(nodeUID: nodeUID)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] state in
                    guard let self = self else { return }
                    self.treeStateRelay.accept(state)
                } onError: { error in
                    DocsLogger.error("collapse node failed?", error: error)
                }
                .disposed(by: disposeBag)
            return
        }

        let token = meta.originWikiToken ?? meta.wikiToken
        let spaceID = meta.originSpaceID ?? meta.spaceID
        var cacheReady = false
        dataModel.expand(wikiToken: token, spaceID: spaceID, nodeUID: nodeUID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state, fromCache) in
                self?.treeStateRelay.accept(state)
                if fromCache {
                    cacheReady = true
                }
            }, onError: { [weak self] error in
                DocsLogger.error("expand node failed", error: error)
                guard let self = self else { return }
                let wikiError = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                if !cacheReady {
                    self.actionInput.accept(.showHUD(.failure(wikiError.expandErrorDescription)))
                    // 重放一次触发 UI 刷新，重置 loading 状态
                    self.treeStateRelay.accept(self.treeStateRelay.value)
                }
            })
            .disposed(by: disposeBag)
    }

    // 展开并高亮到特定路径
    // 从搜索跳到特定位置
    func focusNode(wikiToken: String, needLoading: Bool = true) {
        if needLoading {
            actionInput.accept(.showLoading)
        }
        dataModel.focus(wikiToken: wikiToken)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
                // 固定跳到无 shortcut 路径
                let section = WikiTreeDataProcessor.getNodeSection(wikiToken: wikiToken, treeState: state) ?? .mainRoot
                let nodeUID = WikiTreeNodeUID(wikiToken: wikiToken, section: section, shortcutPath: "")
                self.scrollByUIDInput.accept(nodeUID)
            } onError: { [weak self] error in
                DocsLogger.error("focus node failed", error: error)
                guard let self = self else { return }
                let wikiError = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.actionInput.accept(.showHUD(.failure(wikiError.expandErrorDescription)))
                // 重放一次触发 UI 刷新，重置 loading 状态
                self.treeStateRelay.accept(self.treeStateRelay.value)
            }
            .disposed(by: disposeBag)
    }
}

extension WikiPickerTreeViewModel: TreeViewDataBuilder {
    var spaceID: String { dataModel.spaceID }
    
    var sectionRelay: BehaviorRelay<[NodeSection]> {
        sectionsRelay
    }

    var input: (build: PublishRelay<Void>, swipeCell: PublishRelay<(IndexPath, TreeNode)>) {
        (reloadInput, PublishRelay<(IndexPath, TreeNode)>())
    }

    func configSlideAction(node: TreeNode) -> [TreeSwipeAction]? { nil }
}
