//
//  SpaceVerticalGridSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKCommon
import RxDataSources
import LarkContainer

private protocol SpaceVerticalGridItemDiffer {
    typealias Item = SpaceVerticalGridSection.Item
    func handle(currentList: [Item], newList: [Item]) -> [SpaceListDiffResult<Item>]
}

fileprivate extension SpaceVerticalGridSection {

    typealias ItemCell = SpaceVerticalGridCell
    typealias HeaderCell = SpaceVerticalGridHeaderCell
    typealias PlaceHolderCell = SpaceVerticalGridPlaceHolderCell
    typealias EmptyTipsCell = SpaceVerticalGridEmptyTipsCell
    typealias FooterView = SpaceVerticalGridFooterView

    struct Layout {
        static let itemHorizontalSpacing: CGFloat = 12
        static let itemVerticalSpacing: CGFloat = 12
        static let itemHeight: CGFloat = 48
        static var headerHeight: CGFloat { HeaderCell.Layout.headerHeight }
        static let emptyItemHeight: CGFloat = 32

        static let sectionHorizontalInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 12

        var containerWidth: CGFloat = 375
        var itemPerLine = 2
        var itemWidth: CGFloat = 165.5

        mutating func updateItemWidthIfNeed(with containerWidth: CGFloat) {
            guard self.containerWidth != containerWidth else { return }
            self.containerWidth = containerWidth
            itemPerLine = SpaceSubSectionLayoutHelper.calculateGridItemPerLine(for: containerWidth - Self.sectionHorizontalInset * 2, spacing: Self.itemHorizontalSpacing)
            itemWidth = SpaceSubSectionLayoutHelper.calculateGridItemWidth(itemPerLine: itemPerLine,
                                                                           containerWidth: containerWidth - Self.sectionHorizontalInset * 2,
                                                                           spacing: Self.itemHorizontalSpacing)
        }

        func placeHolderItemSize(at index: Int) -> CGSize {
            let placeHolderCount = itemPerLine - (index % itemPerLine)
            let cellWidth = itemWidth * CGFloat(placeHolderCount)
            return CGSize(width: cellWidth, height: Self.itemHeight)
        }
    }

    enum Item: IdentifiableType, Equatable {

        case header(title: String, moreHandler: () -> Void)
        case content(item: SpaceVerticalGridItem)
        case placeHolder // 用于解决只有1个item时，item不居中的问题
        case emptyTips  // item 为空时的占位cell

        var identity: String {
            switch self {
            case let .header(title, _):
                return title
            case let .content(item):
                return item.entry.objToken
            case .placeHolder:
                return "placeholder"
            case .emptyTips:
                return "empty-tips"
            }
        }

        static func == (lhs: SpaceVerticalGridSection.Item, rhs: SpaceVerticalGridSection.Item) -> Bool {
            switch (lhs, rhs) {
            case let (.header(lTitle, _), .header(rTitle, _)):
                return lTitle == rTitle
            case let (.content(lItem), .content(rItem)):
                return lItem == rItem
            case (.placeHolder, .placeHolder),
                 (.emptyTips, .emptyTips):
                return true
            default:
                return false
            }
        }
    }

    private var headerItem: Item {
        return .header(title: config.headerTitle) { [weak viewModel] in
            viewModel?.handleMoreAction()
        }
    }

    class StandardDiffer: SpaceListStandardDiffer<Item>, SpaceVerticalGridItemDiffer {}

    class SectionDiffer {
        private var currentItems: [Item]
        private let differ: SpaceVerticalGridItemDiffer
        init(initialItems: [Item], differ: SpaceVerticalGridItemDiffer) {
            currentItems = initialItems
            self.differ = differ
        }

        func handle(newItems: [Item]) -> [SpaceListDiffResult<Item>] {
            let oldItems = currentItems
            currentItems = newItems
            return differ.handle(currentList: oldItems, newList: newItems)
        }
    }
}

public extension SpaceVerticalGridSection {

    // 用于控制列表内容为空时的表现
    enum EmptyBehavior {
        /// 隐藏整个 section
        case hide
        /// 展示占位文本
        case emptyTips(placeHolder: String)
    }

    struct Config {
        public let headerTitle: String
        public let emptyBehavior: EmptyBehavior
        public let needBottomSeperator: Bool
    }
}

public final class SpaceVerticalGridSection: SpaceSection {

    static let sectionIdentifier: String = "vertical-grid"
    public var identifier: String { Self.sectionIdentifier }

    private let viewModel: SpaceVerticalGridViewModel
    private let config: Config

    private var items: [Item]
    private let disposeBag = DisposeBag()

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let differ: SectionDiffer
    private var layout = Layout()
    
    public let userResolver: UserResolver

    public init(userResolver: UserResolver,
                viewModel: SpaceVerticalGridViewModel,
                config: Config) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.config = config
        switch config.emptyBehavior {
        case .emptyTips:
            items = [
                .header(title: config.headerTitle, moreHandler: { [weak viewModel] in
                    viewModel?.handleMoreAction()
                }),
                .emptyTips
            ]
        case .hide:
            items = []
        }
        differ = SectionDiffer(initialItems: items, differ: StandardDiffer())
    }

    public func prepare() {
        viewModel.itemsUpdated
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.vertical-grid.section"))
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                let maxCount = self.layout.itemPerLine * 3
                self.handle(gridItems: Array(items.prefix(maxCount)))
            })
            .disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {}
}

extension SpaceVerticalGridSection: SpaceSectionLayout {
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        guard index < items.count else { return .zero }
        layout.updateItemWidthIfNeed(with: containerWidth)
        let item = items[index]
        switch item {
        case .header:
            let width = containerWidth - Layout.sectionHorizontalInset * 2
            let height = Layout.headerHeight - Layout.itemVerticalSpacing
            return CGSize(width: width, height: height)
        case .content:
            return CGSize(width: layout.itemWidth, height: Layout.itemHeight)
        case .placeHolder:
            let actualIndex = index - 1 // 去掉 header
            return layout.placeHolderItemSize(at: actualIndex)
        case .emptyTips:
            let width = containerWidth - Layout.sectionHorizontalInset * 2
            return CGSize(width: width, height: Layout.emptyItemHeight)
        }
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        if items.isEmpty { return .zero }
        return UIEdgeInsets(top: 0,
                            left: Layout.sectionHorizontalInset,
                            bottom: Layout.sectionBottomInset,
                            right: Layout.sectionHorizontalInset)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        Layout.itemVerticalSpacing
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        Layout.itemHorizontalSpacing
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        config.needBottomSeperator ? 8 : 0
    }
}

extension SpaceVerticalGridSection: SpaceSectionDataSource {
    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] { [] }

    public var numberOfItems: Int {
        items.count
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.reuseIdentifier)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: HeaderCell.reuseIdentifier)
        collectionView.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.reuseIdentifier)
        collectionView.register(EmptyTipsCell.self, forCellWithReuseIdentifier: EmptyTipsCell.reuseIdentifier)
        collectionView.register(FooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FooterView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let index = indexPath.item
        guard index < items.count else {
            assertionFailure()
            return collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.reuseIdentifier, for: indexPath)
        }
        let item = items[index]
        switch item {
        case let .header(title, moreHandler):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeaderCell.reuseIdentifier, for: indexPath)
            guard let headerCell = cell as? HeaderCell else {
                assertionFailure()
                return cell
            }
            headerCell.update(title: title, moreHandler: moreHandler)
            return headerCell
        case let .content(item):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.reuseIdentifier, for: indexPath)
            guard let itemCell = cell as? ItemCell else {
                assertionFailure()
                return cell
            }
            itemCell.update(item: item)
            return itemCell
        case .placeHolder:
            return collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.reuseIdentifier, for: indexPath)
        case .emptyTips:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyTipsCell.reuseIdentifier, for: indexPath)
            guard let emptyTipsCell = cell as? EmptyTipsCell else {
                return cell
            }
            if case let .emptyTips(placeHolder) = config.emptyBehavior {
                emptyTipsCell.update(placeHolder: placeHolder)
            }
            return emptyTipsCell
        }
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        guard case UICollectionView.elementKindSectionFooter = kind else {
            assertionFailure()
            return UICollectionReusableView()
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterView.reuseIdentifier, for: indexPath)
    }
}

extension SpaceVerticalGridSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        let index = indexPath.item
        guard index < items.count else {
            assertionFailure()
            return
        }
        let item = items[index]
        switch item {
        case let .content(item):
            viewModel.didSelect(item: item)
        case .header,
             .placeHolder,
             .emptyTips:
            return
        }
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? { nil }
}

extension SpaceVerticalGridSection {

    private func handle(gridItems: [SpaceVerticalGridItem]) {
        let newItems = generateItems(from: gridItems)
        let differResults = differ.handle(newItems: newItems)
        differResults.forEach { result in
            let completion: () -> Void
            switch result {
            case let .none(newList):
                completion = { [weak self] in
                    self?.items = newList
                }
            case let .reload(newList):
                completion = { [weak self] in
                    self?.items = newList
                    self?.reloadInput.accept(.reloadSection(animated: false))
                }
            case let .update(newList, inserts, deletes, updates, moves):
                completion = { [weak self] in
                    let reloadAction = SpaceSectionReloadAction.update(inserts: inserts, deletes: deletes, updates: updates, moves: moves) {
                        self?.items = newList
                    }
                    self?.reloadInput.accept(reloadAction)
                }
            }
            DispatchQueue.main.async(execute: completion)
        }
    }

    private func generateItems(from gridItems: [SpaceVerticalGridItem]) -> [Item] {
        var result: [Item] = [
            headerItem
        ]
        if gridItems.isEmpty {
            switch config.emptyBehavior {
            case .hide:
                return []
            case .emptyTips:
                result.append(.emptyTips)
                return result
            }
        }

        if gridItems.count == 1 {
            // 只有一个 item 的时候，可能存在 item 居中的问题，需要补一个 placeHolder
            result.append(.content(item: gridItems[0]))
            result.append(.placeHolder)
            return result
        }

        result.append(contentsOf: gridItems.map { .content(item: $0) })
        return result
    }
}
