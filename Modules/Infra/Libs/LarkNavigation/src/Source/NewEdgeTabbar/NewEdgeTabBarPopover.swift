//
//  NewEdgeTabBarPopover.swift
//  LarkNavigation
//
//  Created by Saafo on 2023/6/19.
//

import UIKit
import LarkTab
import FigmaKit
import Foundation
import LarkSetting
import AnimatedTabBar
import LarkExtensions
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import LarkContainer
import LKCommonsLogging
import LarkBoxSetting

final class NewEdgeTabBarPopover: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UserResolverWrapper {

    public let userResolver: UserResolver

    static let logger = Logger.log(NewEdgeTabBarPopover.self, category: "Module.LarkNavigation")

    /// 开平配置
    @ScopedInjectedLazy private var openPlatformConfig: OpenPlatformConfigService?
    
    enum Cons {
        static let width: CGFloat = 375

        enum CollectionView {
            static let itemSize: CGSize = CGSize(width: 64, height: 104)
            static let sectionInset: CGFloat = 24
            static let topInset: CGFloat = sectionInset - QuickTabBarItemView.Layout.hSpacing
            static let bottomInset: CGFloat = sectionInset - QuickTabBarItemView.Layout.bottomSpacing
            static let minimumInteritemSpacing: CGFloat = 22
            static let minimumLineSpacing: CGFloat = 0
            static let itemCountPerLine: Int = 4
        }

    }

    internal weak var edgeTabBar: NewEdgeTabBar?

    private let auroraView = QuickLaunchAuroraView(isPopover: true)

    lazy var collectionView: UICollectionView = {
        let layout = CenterLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.scrollDirection = .vertical
        typealias CollectionCons = Cons.CollectionView
        layout.minimumInteritemSpacing = CollectionCons.minimumInteritemSpacing
        layout.minimumLineSpacing = CollectionCons.minimumLineSpacing
        layout.itemSize = CollectionCons.itemSize
        layout.sectionInset = .init(top: CollectionCons.topInset,
                                    left: CollectionCons.sectionInset,
                                    bottom: CollectionCons.bottomInset,
                                    right: CollectionCons.sectionInset)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.lu.register(cellWithClass: QuickTabBarItemView.self)
        if #available(iOS 15, *) { // iPad 快捷键选择能力
            collectionView.allowsFocus = true
        }
        return collectionView
    }()

    private var itemCount: Int {
        // 1 是指「添加」按钮
        let addCount = isOpenPlatformEntryEnable ? 1 : 0
        guard let edgeTabBar else { return addCount }
        return edgeTabBar.hiddenTabItems.count + addCount
    }

    public var isOpenPlatformEntryEnable: Bool {
        if BoxSetting.isBoxOff() {
            return false
        }
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.navigation.openplatform.entry")
    }

    private lazy var openPlatformItem: AbstractTabBarItem = {
        let stateConfig = ItemStateConfig(defaultIcon: UDIcon.addOutlined, selectedIcon: UDIcon.addOutlined, quickBarIcon: UDIcon.addOutlined)
        if let asTab = self.openPlatformConfig?.asTab {
            let item = TabBarItem(tab: asTab, title: BundleI18n.LarkNavigation.Lark_Core_More_AddApp_Button, stateConfig: stateConfig)
            return item
        } else {
            Self.logger.error("open platform app store item is nil")
            let tab = Tab(url: "", appType: .appTypeOpenApp, key: "")
            let item = TabBarItem(tab: tab, title: "", stateConfig: stateConfig)
            return item
        }
    }()
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(auroraView)
        auroraView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            // 13 以上系统, Popover 的 ContentView 包括箭头区域, 避让箭头
            // 13 以下系统, Popover 的 ContentView 不包括箭头区域
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        refreshContentSize()
    }

    func reloadDataAndViews() {
        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.performBatchUpdates({ [weak self] in
                guard let self else { return }
                let visibleItems = self.collectionView.indexPathsForVisibleItems
                self.collectionView.reloadItems(at: visibleItems)
            })
        }
        refreshContentSize()
    }

    private func refreshContentSize() {
        typealias CollectionCons = Cons.CollectionView
        let lineCount: CGFloat = max(1, ceil(Double(itemCount) / Double(CollectionCons.itemCountPerLine)))
        let preferredHeight: CGFloat = lineCount * CollectionCons.itemSize.height // cell height
        + (lineCount - 1) * CollectionCons.minimumLineSpacing // line spacing
        + CollectionCons.topInset + CollectionCons.bottomInset // top and bottom
        preferredContentSize = CGSize(width: Cons.width, height: preferredHeight)
    }

    // MARK: UICollectionView

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let edgeTabBar else { return UICollectionViewCell() }
        if indexPath.row == edgeTabBar.hiddenTabItems.count {
            let cell = collectionView.lu.dequeueReusableCell(withClass: QuickTabBarItemView.self, for: indexPath)
            // 需要在最后面加一个应用商城的item
            cell.item = openPlatformItem
            cell.configure(userResolver: userResolver)
            cell.layer.cornerRadius = NewEdgeTabBar.Cons.dragPreviewRadius // 让 Drag Preview 圆角过渡自然
            return cell
        } else {
            let cell = collectionView.lu.dequeueReusableCell(withClass: QuickTabBarItemView.self, for: indexPath)
            let item = edgeTabBar.hiddenTabItems[indexPath.row]
            cell.item = item
            cell.configure(userResolver: userResolver)
            cell.layer.cornerRadius = NewEdgeTabBar.Cons.dragPreviewRadius
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        dismiss(animated: true) { [weak self] in
            guard let self, let edgeTabBar = self.edgeTabBar else { return }
            let item: AbstractTabBarItem
            if indexPath.row == edgeTabBar.hiddenTabItems.count {
                item = self.openPlatformItem
            } else {
                item = edgeTabBar.hiddenTabItems[indexPath.row]
            }
            edgeTabBar.delegate?.edgeTabBar(edgeTabBar, didSelectItem: item)
        }
    }

    // MARK: Context menu
    @available(iOS 13, *)
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let edgeTabBar, indexPath.row < edgeTabBar.hiddenTabItems.count else { return nil }

        let actions = edgeTabBar.getActions(position: .hidden(index: indexPath.row))
        var menu = actions.map({
            return UIMenu(title: "", options: .displayInline, children: $0)
        })

        let identifier = indexPath as NSCopying
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in
            return UIMenu(title: "", children: menu)
        })
    }

    // 定制 Preview 避免错乱
    @available(iOS 13, *)
    func collectionView(_ collectionView: UICollectionView,
                        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: indexPath),
              collectionView.window != nil,
              let copy = cell.snapshotView(afterScreenUpdates: false) else { return nil }
        let parameter = UIPreviewParameters()
        parameter.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: NewEdgeTabBar.Cons.dragPreviewRadius)
        return UITargetedPreview(view: copy, parameters: parameter,
                                 target: UIPreviewTarget(container: collectionView, center: cell.center))
    }
}

// MARK: Drag & Drop Reorder

extension NewEdgeTabBarPopover: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let edgeTabBar, let position = edgeTabBar.position(of: indexPath, in: collectionView),
              // can't get item from `add` button, we don't allow moving it
              let item = edgeTabBar.item(at: position),
              edgeTabBar.canDrag(from: position) else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: NewEdgeTabIndexProvider(position)))
        dragItem.localObject = item
        return [dragItem]
    }
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        [] // Don't allow adding to
    }
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameter = UIDragPreviewParameters()
        if let view = collectionView.cellForItem(at: indexPath) {
            parameter.visiblePath = UIBezierPath(roundedRect: view.bounds,
                                                 cornerRadius: NewEdgeTabBar.Cons.dragPreviewRadius)
        }
        return parameter
    }
    func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        true
    }
    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        true
    }
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        collectionView.endInteractiveMovement() // Fix crash: https://stackoverflow.com/questions/51553223
    }
}

extension NewEdgeTabBarPopover: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NewEdgeTabIndexProvider.self)
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        guard let edgeTabBar, let originItem = session.tabItem,
              let originPosition = edgeTabBar.position(of: originItem) else { return }
        switch originPosition {
        case .main, .temporary:
            edgeTabBar.showPopoverOnEnteringMoreIfNeeded()
        default: break
        }
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        guard let edgeTabBar, let originItem = session.tabItem,
              let originPosition = edgeTabBar.position(of: originItem) else { return }
        switch originPosition {
        case .main, .temporary:
            edgeTabBar.dismissPopoverOnExitingMoreLater()
        default: break
        }
    }
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let edgeTabBar,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let destinationPosition = edgeTabBar.position(of: destinationIndexPath, in: collectionView),
              let sourceItem = coordinator.session.tabItem,
              let sourcePosition = edgeTabBar.position(of: sourceItem),
              // DropSessionDidUpdate 返回 .forbidden 的情况下
              // 仍然有可能会调用 performDropWith，这里需要做二次校验
              edgeTabBar.canDrop(from: sourcePosition, to: destinationPosition) else { return }
        edgeTabBar.insert(from: sourcePosition, to: destinationPosition)
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let destinationIndexPath, let edgeTabBar,
              let originItem = session.tabItem,
              let originPosition = edgeTabBar.position(of: originItem),
              let destinationPosition = edgeTabBar.position(of: destinationIndexPath, in: collectionView),
              edgeTabBar.canDrop(from: originPosition, to: destinationPosition) else {
            return .init(operation: .forbidden)
        }

        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

// MARK: - CenterLayout

final class CenterLayout: UICollectionViewFlowLayout {

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()
        refreshItemAttributes()
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter {
            $0.frame.intersects(rect)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.first {
            $0.indexPath == indexPath
        }
    }

    private func refreshItemAttributes() {
        itemAttributes = []
        guard let collectionView else { return }
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        itemAttributes.reserveCapacity(numberOfItems)
        for row in 0..<numberOfItems {
            let indexPath = IndexPath(row: row, section: 0)
            guard let attribute = super.layoutAttributesForItem(at: indexPath) else { continue }
            // 如果小于 4 个，则居中摆放
            if numberOfItems < NewEdgeTabBarPopover.Cons.CollectionView.itemCountPerLine {
                let leftSpace: CGFloat = (collectionView.frame.width
                                          - sectionInset.left
                                          - sectionInset.right
                                          - NewEdgeTabBarPopover.Cons.CollectionView.itemSize.width * CGFloat(numberOfItems)
                                          - minimumInteritemSpacing * CGFloat(numberOfItems - 1))
                let xOffset = leftSpace / 2
                attribute.frame.origin.x += xOffset
            }
            itemAttributes.append(attribute)
        }
    }
}
