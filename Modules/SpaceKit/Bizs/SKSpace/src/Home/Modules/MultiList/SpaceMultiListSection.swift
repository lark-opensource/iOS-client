//
//  SpaceMultiListSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SKFoundation
import SKUIKit
import SKCommon
import LarkSetting

import LarkContainer

private extension SpaceListSubSection {
    var pickerItem: SpaceMultiListPickerItem {
        SpaceMultiListPickerItem(identifier: subSectionIdentifier, title: subSectionTitle)
    }
}

/// 多重列表模块，负责多个子列表的调度
public final class SpaceMultiListSection<T: SpaceMultiSectionHeaderView>: SpaceSection {
    static var sectionIdentifier: String { "multi-list" }
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let listToolsConfigRelay: BehaviorRelay<[SpaceListTool]>
    private let ipadListHeaderConfigRelay: BehaviorRelay<IpadListHeaderSortConfig?>

    private let disposeBag = DisposeBag()
    private var subSectionBag = DisposeBag()
    private var headerBag = DisposeBag()

    private let subSections: [SpaceListSubSection]
    private let currentSectionIndexRelay = BehaviorRelay<Int>(value: 0)
    private var currentSectionIndex: Int {
        currentSectionIndexRelay.value
    }
    public var currentSection: SpaceListSubSection {
        subSections[currentSectionIndex]
    }
    
    public var currentSectionCreateIntent: SpaceCreateIntent {
        currentSection.createIntent
    }

    // 暴露到上层，目前提供单品内埋点用
    public var currentSectionModuleUpdated: Observable<String> {
        currentSectionIndexRelay.map { [weak self] index -> String in
            guard let self = self else { return "recent" }
            return self.subSections[index].subSectionIdentifier
        }
    }

    private var subSectionsFirstVisableIndex: [Int: Int] = [:]

    private var tracker: SpaceMultiListTracker
        
    private let homeType: SpaceHomeType
    
    public let userResolver: UserResolver
    
    private let indexCache: SpaceMultiSectionIndexCache

    public init(userResolver: UserResolver,
                homeType: SpaceHomeType,
                needActiveIndexCache: Bool = false,
                @SpaceMultiListBuilder subSections: () -> [SpaceListSubSection]) {
        self.userResolver = userResolver
        let sections = subSections()
        assert(!sections.isEmpty)
        self.subSections = sections
        self.homeType = homeType
        self.indexCache = SpaceMultiSectionIndexCache(needActive: needActiveIndexCache, identifier: T.reuseIdentifier)
        
        let firstIndex = indexCache.get()
        var firstTools: [SpaceListTool]
        var ipadHeaderSortConfig: IpadListHeaderSortConfig?
        if firstIndex < sections.count {
            firstTools = sections[firstIndex].listTools
            ipadHeaderSortConfig = sections[firstIndex].iPadListHeaderSortConfig
            currentSectionIndexRelay.accept(firstIndex)
        } else {
            firstTools = sections.first?.listTools ?? []
            ipadHeaderSortConfig = sections.first?.iPadListHeaderSortConfig
        }
        
        listToolsConfigRelay = BehaviorRelay<[SpaceListTool]>(value: firstTools)
        ipadListHeaderConfigRelay = BehaviorRelay<IpadListHeaderSortConfig?>(value: ipadHeaderSortConfig)

        tracker = SpaceMultiListTracker(subTabIDs: sections.map(\.subSectionIdentifier))
    }

    public func prepare() {
        currentSection.reloadSignal.emit(to: reloadInput).disposed(by: subSectionBag)
        currentSection.actionSignal.emit(to: actionInput).disposed(by: subSectionBag)
        subSections.forEach { $0.prepare() }
        currentSection.didShowSubSection()
    }

    private func changeSection(newIndex: Int) {
        guard newIndex < subSections.count else {
            DocsLogger.error("space.multi-list.section --- section new index out of range!")
            assertionFailure()
            return
        }
        tracker.reportClick(index: newIndex)
        let previousIndex = currentSectionIndex
        currentSection.willHideSubSection()
        subSectionBag = DisposeBag()
        currentSectionIndexRelay.accept(newIndex)
        indexCache.set(index: newIndex)

        // 切换子列表时，需要记录子列表当前滚动的位置，下次再展示时，需要还原上次滚动的位置
        // 1. 刷新前，获取当前可见cell列表，记录最上面的cell Index
        // 2. 刷新列表
        // 3. 刷新后，若刷新前列表包含其他 section 的 cell（通常表示处于列表顶部），则保持当前列表进度不变
        //    若列表不包含其他 section，说明列表区域覆盖了整个显示区域，此时滚动到新列表上次滚动的位置（取不到则为0，表示滚动到新列表顶部）
        reloadInput.accept(.getVisableIndices(callback: { [weak self] (indices, containCellForOtherSections) in
            guard let self = self else { return }
            self.subSectionsFirstVisableIndex[previousIndex] = indices.min()
            self.reloadInput.accept(.reloadSection(animated: false))
            if !containCellForOtherSections {
                let indexToScroll = self.subSectionsFirstVisableIndex[newIndex] ?? 0
                var scrollPositon = UICollectionView.ScrollPosition.top
                //适配滚动到第一行动画的遮挡问题
                if indexToScroll == 0 {
                    scrollPositon = .bottom
                }
                self.reloadInput.accept(.scrollToItem(index: indexToScroll, at:scrollPositon,animated: false))
            }
        }))

//        reloadInput.accept(.reloadSection(animated: false))
        // 切 section 时，重置一下下拉和上拉的状态
        actionInput.accept(.stopPullToRefresh(total: nil))
        actionInput.accept(.stopPullToLoadMore(hasMore: true))
        listToolsConfigRelay.accept(currentSection.listTools)
        ipadListHeaderConfigRelay.accept(currentSection.iPadListHeaderSortConfig)
        currentSection.reloadSignal.emit(to: reloadInput).disposed(by: subSectionBag)
        currentSection.actionSignal.emit(to: actionInput).disposed(by: subSectionBag)
        currentSection.didShowSubSection()
        currentSection.reportClick(fromSubSectionId: subSections[previousIndex].subSectionIdentifier)

        if case let .baseHomeType(context) = homeType {
            let tabNameMap: [Int: String] = [
                0: "recent",
                1: "quick_access",
                2: "favorites"
            ]
            let params: [String : Any] = [
                "current_sub_view": tabNameMap[previousIndex] ?? "",
                "click": tabNameMap[newIndex] ?? "",
                "target": "none"
            ]
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageFilelistClick, parameters: params, context: context)
        }
    }

    public func notifyPullToRefresh() {
        currentSection.notifyPullToRefresh()
    }
    public func notifyPullToLoadMore() {
        currentSection.notifyPullToLoadMore()
    }
    public func notifySectionDidAppear() {
        subSections.forEach { $0.notifySectionDidAppear() }
    }
    public func notifySectionWillDisappear() {
        subSections.forEach { $0.notifySectionWillDisappear() }
    }

    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {
        currentSection.notifyViewDidLayoutSubviews(hostVCWidth: hostVCWidth)
    }
}

// 除了 header、footer，其他都交给当前section决定
extension SpaceMultiListSection: SpaceSectionLayout {
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        currentSection.itemSize(at: index, containerWidth: containerWidth)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        currentSection.sectionInsets(for: containerWidth)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        currentSection.minimumLineSpacing(for: containerWidth)
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        currentSection.minimumInteritemSpacing(for: containerWidth)
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        if shouldUseNewestStyle() {
            return 50
        }else{
            if let section = currentSection as? SpaceSubSectionLayoutDelegate {
                return T.height(mode: section.layoutDisplayMode)
            } else {
                return T.height
            }
        }
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }
    
    /*
     *列表最新样式
     *目前先在Base-homepage首页中使用最新样式
    */
    func shouldUseNewestStyle() -> Bool {
        //检测场景 非Base场景直接返回false
        guard case .baseHomeType(context: let baseContext) = self.homeType, baseContext.containerEnv == .larkTab else {
            return false
        }
        let enable = baseContext.shouldShowRecommend
        return enable
    }
}

extension SpaceMultiListSection: SpaceSectionDataSource {

    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        currentSection.dragItem(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }

    public var numberOfItems: Int {
        currentSection.numberOfItems
    }

    public func setup(collectionView: UICollectionView) {
        // TODO: @wuwenjian.weston 考虑延迟各个子列表初始化的时机
        subSections.forEach { $0.setup(collectionView: collectionView) }

        collectionView.register(T.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        currentSection.cell(at: indexPath, collectionView: collectionView)
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            headerBag = DisposeBag()
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath)
            
            guard let headerView = view as? T else {
                assertionFailure()
                return view
            }
            let headerItems = subSections.map(\.pickerItem)
            headerView.update(items: headerItems, currentIndex: currentSectionIndex, shouldUseNewestStyle: shouldUseNewestStyle())
            headerView.sectionChangedSignal
                .emit(onNext: { [weak self] newIndex in
                    self?.changeSection(newIndex: newIndex)
                })
                .disposed(by: headerBag)
            listToolsConfigRelay
                .bind(to: headerView.listToolConfigInput)
                .disposed(by: headerBag)
            
            ipadListHeaderConfigRelay
                .bind(to: headerView.ipadListHeaderConfigInput)
                .disposed(by: headerBag)

            return headerView
        case UICollectionView.elementKindSectionFooter:
            assertionFailure()
            return UICollectionReusableView()
        default:
            return currentSection.supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
        }
    }
}

extension SpaceMultiListSection: SpaceSectionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        currentSection.contextMenuConfig(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        currentSection.didSelectItem(at: indexPath, collectionView: collectionView)
    }

    public func notifyDidEndDragging(willDecelerate: Bool) {
        currentSection.notifyDidEndDragging(willDecelerate: willDecelerate)
    }
    public func notifyDidEndDecelerating() {
        currentSection.notifyDidEndDecelerating()
    }
    public func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {
        currentSection.didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }
}
