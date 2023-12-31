//
//  NaviEditViewController.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/08/01.
//

import Foundation
import UIKit
import SnapKit
import LKCommonsTracker
import LKCommonsLogging
import Homeric
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import LarkTab
import LarkInteraction
import LarkContainer
import LarkSetting

final class NaviEditViewController: UIViewController, UserResolverWrapper {
    public let userResolver: UserResolver

    private weak var tabBarVC: AnimatedTabBarController?

    static let logger = Logger.log(NaviEditViewController.self, category: "Module.AnimatedTabBar")

    var dragdropOptimizeEnableClose: Bool {
        let optimizeEnableClose = userResolver.fg.dynamicFeatureGatingValue(with: "navigation.dragdrop.optimize.close")
        Self.logger.info("dragdrop optimize enable close: \(optimizeEnableClose)")
        return optimizeEnableClose
    }

    // 完成回调
    typealias FinishCallback = (
        _ controller: UIViewController,
        _ changed: Bool,
        _ mainItems: [AbstractTabBarItem],
        _ quickItems: [AbstractTabBarItem]
    ) -> Void
    // 取消回调
    typealias CancelCallback = () -> Void
    
    // 拖曳区域的位置
    enum Position: Equatable {
        // 快捷导航区域
        case quick(index: Int)
        // 主导航区域
        case main(index: Int)
    }
    
    enum Cons {
        static let dragPreviewRadius: CGFloat = 12
        static var tabBarColor: UIColor {
            // UIColor.ud.bgFloatOverlay
            return makeDynamicColor(
                light: UIColor.ud.N100,
                dark: UIColor.ud.N200
            )
        }
        static var popoverColor: UIColor {
            // UIColor.ud.bgFloat
            return makeDynamicColor(
                light: UIColor.ud.N00,
                dark: UIColor.ud.N100
            )
        }
        static func makeDynamicColor(light: UIColor, dark: UIColor) -> UIColor {
            if #available(iOS 13.0, *) {
                return UIColor { trait -> UIColor in
                    switch trait.userInterfaceStyle {
                    case .dark: return dark.resolvedColor(with: trait)
                    default:    return light.resolvedColor(with: trait)
                    }
                }
            } else {
                return light
            }
        }
    }

    // 数据model
    public let viewModel: NaviEditViewModel
    // 完成点击事件
    private let finishCallback: FinishCallback?
    // 取消点击事件
    private let cancelCallback: CancelCallback?
    // 容器
    lazy var container = NaviEditContainer()
    // 是否显示「更多」tab，目前精简模式下不显示该tab
    private let moreTabEnabled: Bool
    // 主导航区更多按钮数据模型
    private var moreItem: AbstractTabBarItem

    required init(tabBarVC: AnimatedTabBarController,
                  viewModel: NaviEditViewModel,
                  moreTabEnabled: Bool,
                  userResolver: UserResolver,
                  finishCallback: FinishCallback? = nil,
                  cancelCallback: CancelCallback? = nil) {
        self.tabBarVC = tabBarVC
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.finishCallback = finishCallback
        self.cancelCallback = cancelCallback
        self.moreTabEnabled = moreTabEnabled
        self.moreItem = TabBarItem(tab: Tab.more,
                                   title: BundleI18n.AnimatedTabBar.Lark_Core_More_Navigation,
                                   stateConfig: ItemStateConfig(defaultIcon: nil, selectedIcon: nil, quickBarIcon: nil))
        self.moreItem.quickCustomView = TabMoreGridView(tabBarItems: viewModel.quickItems)
        self.moreItem.itemState = DefaultTabState()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        layout()
        bindActions()
    }

    private func setup() {
        view.addSubview(container)
    }

    private func layout() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindActions() {
        container.quickCollectionView.delegate = self
        container.quickCollectionView.dataSource = self
        container.quickCollectionView.dragDelegate = self
        container.quickCollectionView.dropDelegate = self
        
        container.mainCollectionView.delegate = self
        container.mainCollectionView.dataSource = self
        container.mainCollectionView.dragDelegate = self
        container.mainCollectionView.dropDelegate = self

        container.cancelButton.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        container.finishButton.addTarget(self, action: #selector(finishBtnTapped), for: .touchUpInside)
    }

    static func realItemSize(forWidth width: CGFloat) -> CGSize {
        // 限制一行 4 个，根据 collectionView 的宽度调整大小
        let allCellWidth = width - QuickTabBarConfig.Layout.quickSectionInset.left - QuickTabBarConfig.Layout.quickSectionInset.right
        let itemWidth = allCellWidth / CGFloat(QuickTabBarConfig.Layout.collectionMaxLineCount)
        return CGSize(width: itemWidth, height: QuickTabBarConfig.Layout.itemSize.height)
    }

    @objc
    func cancelBtnTapped() {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_EDIT_CANCEL))
        cancelCallback?()
        self.dismiss(animated: true, completion: nil)
    }

    // nolint: duplicated_code - 非重复代码
    @objc
    func finishBtnTapped() {
        // 老的埋点，不要移除
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_EDIT_DONE))
        
        let before = viewModel.mainItemsBackup + viewModel.quickItemsBackup
        let beforeOrder = before.map({ $0.tab.key })
        var beforMap: [AnyHashable: Any] = [:]
        beforMap["order"] = beforeOrder
        beforMap["main_count"] = viewModel.mainItemsBackup.count
        let after = viewModel.mainItems + viewModel.quickItems
        let afterOrder = after.map({ $0.tab.key })
        var afterMap: [AnyHashable: Any] = [:]
        afterMap["order"] = afterOrder
        afterMap["main_count"] = viewModel.mainItems.count
        var params: [AnyHashable: Any] = [:]
        params["click"] = "save"
        params["before_order"] = beforMap
        params["after_order"] = afterMap
        let clickType = Set(beforeOrder) == Set(afterOrder) ? "change_order" : "remove"
        params["click_type"] = clickType
        Tracker.post(TeaEvent(Homeric.NAVIGATION_EDIT_MENU_MOBILE_CLICK, params: params))
        let mainItems = viewModel.mainItems
        let quickItems = viewModel.quickItems
        finishCallback?(self, viewModel.changed(), mainItems, quickItems)
    }
}

// MARK: - CollectionView delete item

extension NaviEditViewController {

    func deleteItem(from: Position) {
        switch from {
        case .quick:
            self.remove(from: from)
        case .main:
            if viewModel.mainItems.count > viewModel.minTabCount {
                self.remove(from: from)
            } else {
                if viewModel.minTabCount == 1 {
                    UDToast.showTips(
                        with: BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationCantEmptyToast,
                        on: self.view
                    )
                } else {
                    UDToast.showTips(
                        with: BundleI18n.AnimatedTabBar.Lark_Legacy_BottomNavigationItemMinimumToast(viewModel.minTabCount),
                        on: self.view
                    )
                }
            }
        }
    }
}

// MARK: - CollectionView Delegate

extension NaviEditViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

// MARK: - CollectionView DataSource

extension NaviEditViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView === container.quickCollectionView {
            return 1
        } else if collectionView == container.mainCollectionView {
            return 1
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === container.quickCollectionView {
            return viewModel.quickItems.count
        } else if collectionView == container.mainCollectionView {
            return viewModel.mainItems.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === container.quickCollectionView {
            guard indexPath.item >= 0, indexPath.item < viewModel.quickItems.count else { return UICollectionViewCell() }
            let quickTabCell = collectionView.lu.dequeueReusableCell(withClass: QuickTabBarItemView.self, for: indexPath)
            let item = viewModel.quickItems[indexPath.item]
            Self.logger.info("quick item: \(item.title) = \(item.tab)")
            quickTabCell.isInMainTabBar = false
            quickTabCell.isShowBadge = false
            quickTabCell.item = item
            quickTabCell.configure(userResolver: userResolver, enableEditMode: true) { [weak self] type in
                switch type {
                case .delete:
                    self?.deleteItem(from: .quick(index: indexPath.item))
                @unknown default:
                    Self.logger.info("unknown default edit type")
                }
            }
            return quickTabCell
        } else if collectionView == container.mainCollectionView {
            guard indexPath.item >= 0, indexPath.item < viewModel.mainItems.count else { return UICollectionViewCell() }
            let mainTabCell = collectionView.lu.dequeueReusableCell(withClass: QuickTabBarItemView.self, for: indexPath)
            let item = viewModel.mainItems[indexPath.item]
            Self.logger.info("main item: \(item.title) = \(item.tab)")
            mainTabCell.isInMainTabBar = true
            mainTabCell.isShowBadge = false
            mainTabCell.item = item
            mainTabCell.configure(userResolver: userResolver, enableEditMode: true) { [weak self] type in
                switch type {
                case .delete:
                    self?.deleteItem(from: .main(index: indexPath.item))
                @unknown default:
                    Self.logger.info("unknown default edit type")
                }
            }
            return mainTabCell
        }
        return UICollectionViewCell()
    }
}

// MARK: - CollectionView FlowLayout

extension NaviEditViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView === container.quickCollectionView {
            return QuickTabBarConfig.Layout.quickSectionInset
        } else if collectionView === container.mainCollectionView {
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            let totalWidth = collectionView.bounds.width
            let totalItemWidth: CGFloat = QuickTabBarConfig.Layout.mainItemSize.width * CGFloat(numberOfItems)
            var padding: CGFloat
            if numberOfItems == 1 {
                padding = (totalWidth - totalItemWidth) / 2.0
                return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
            } else if numberOfItems == 2 {
                padding = (totalWidth - totalItemWidth) / 3.0
                return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
            }
            return QuickTabBarConfig.Layout.mainSectionInset
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView === container.quickCollectionView {
            // 纵向布局
            return QuickTabBarConfig.Layout.itemSpacing
        } else if collectionView === container.mainCollectionView {
            // 横向布局
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            let totalWidth = collectionView.bounds.width
            let itemSize: CGSize = QuickTabBarConfig.Layout.mainItemSize
            let totalItemWidth = CGFloat(numberOfItems) * itemSize.width
            let totalSpacingWidth = totalWidth - totalItemWidth - QuickTabBarConfig.Layout.mainSectionInset.left - QuickTabBarConfig.Layout.mainSectionInset.right
            var spacing: CGFloat = 0.0
            if numberOfItems - 1 > 0 {
                spacing = totalSpacingWidth / CGFloat(numberOfItems - 1)
            }
            if numberOfItems == 2 {
                spacing = (totalWidth - totalItemWidth) / 3.0
            }
            return spacing
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === container.quickCollectionView {
            return NaviEditViewController.realItemSize(forWidth: collectionView.bounds.width)
        } else if collectionView === container.mainCollectionView {
            return QuickTabBarConfig.Layout.mainItemSize
        }
        return .zero
    }
}

// MARK: Drag & Drop Reorder

extension NaviEditViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let position = self.position(of: indexPath, in: collectionView),
              // can't get item from `add` button, we don't allow moving it
              let item = self.item(at: position),
              self.canDrag(from: position) else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: NaviEditViewControllerIndexProvider(position)))
        dragItem.localObject = item
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        [] // Don't allow adding to
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameter = UIDragPreviewParameters()
    if let view = collectionView.cellForItem(at: indexPath), let quickItemView = view as? QuickTabBarItemView {
        //let rect = quickItemView.iconContainerView.convert(quickItemView.iconContainerView.bounds, to: quickItemView)
        let rect = quickItemView.iconContainerView.frame.insetBy(dx: -10, dy: -10)
        parameter.visiblePath = UIBezierPath(roundedRect: rect,
                                                 cornerRadius: Cons.dragPreviewRadius)
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

extension NaviEditViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NaviEditViewControllerIndexProvider.self)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        guard let originItem = session.naviTabItem,
              let originPosition = self.position(of: originItem) else { return }
        switch originPosition {
        case .main:
            self.showPopoverOnEnteringIfNeeded()
        default: break
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        guard let originItem = session.naviTabItem,
              let originPosition = self.position(of: originItem) else { return }
        switch originPosition {
        case .main:
            self.dismissPopoverOnExitingIfNeeded()
        default: break
        }
    }

    // 当用户松开拖动的项目时，系统会调用的方法。在这个方法中，需要更新你的数据源并正确地插入或移动项目。
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if dragdropOptimizeEnableClose {
            guard let indexPath = coordinator.destinationIndexPath else { return }
            destinationIndexPath = indexPath
        } else {
            guard coordinator.proposal.operation == .move || coordinator.proposal.operation == .copy else {
                Self.logger.info("collectionView performDrop coordinator operation unable to operate")
                return
            }
            if let indexPath = coordinator.destinationIndexPath {
                destinationIndexPath = indexPath
            } else {
                var dropOperation: EditDropOperation = .move
                if case .copy = coordinator.proposal.operation {
                    dropOperation = .copy
                }
                //系统没有给出合适的destinationIndexPath，需要手动计算  算出是 copy 还是 复制
                if collectionView == self.container.quickCollectionView {
                    destinationIndexPath = self.getByDefaultDestinationIndexPath(by: collectionView, dropOperation: dropOperation)
                } else {
                    let dropPoint = coordinator.session.location(in: collectionView)
                    destinationIndexPath = self.calculateAppropriateIndexPath(by: collectionView, dropPoint: dropPoint, dropOperation: dropOperation)
                }
            }
        }
        guard let destinationPosition = self.position(of: destinationIndexPath, in: collectionView),
              let sourceItem = coordinator.session.naviTabItem,
              let sourcePosition = self.position(of: sourceItem),
              // DropSessionDidUpdate 返回 .forbidden 的情况下
              // 仍然有可能会调用 performDropWith，这里需要做二次校验
              self.canDrop(from: sourcePosition, to: destinationPosition) else { return }
        self.insert(from: sourcePosition, to: destinationPosition)
    }

    //当拖动一个应用并且项目的位置已经改变时，系统就会调用这个方法。可以在这个方法里面返回一个UICollectionViewDropProposal对象，来决定想要的行为
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if dragdropOptimizeEnableClose {
            guard let destinationIndexPath,
                  let originItem = session.naviTabItem,
                  let originPosition = self.position(of: originItem),
                  let destinationPosition = self.position(of: destinationIndexPath, in: collectionView),
                  self.canDrop(from: originPosition, to: destinationPosition) else {
                return .init(operation: .forbidden)
            }
            return .init(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            if collectionView.hasActiveDrag {
                // 如果是同一个UICollectionView内的拖拽，允许移动
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                // 如果是从其他地方拖拽来的，允许复制
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
    }
}
