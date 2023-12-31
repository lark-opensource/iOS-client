//
//  RankViewController.swift
//  AnimatedTabBar
//
//  Created by bytedance on 2020/11/25.
//

import Foundation
import UIKit
import SnapKit
import LKCommonsTracker
import Homeric
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import LarkTab
import LarkContainer

final class RankViewController: UIViewController, UserResolverWrapper {
    public let userResolver: UserResolver
    typealias ConfirmCallback = (
        _ controller: UIViewController,
        _ changed: Bool,
        _ mainItems: [RankItem],
        _ quickItems: [RankItem]
    ) -> Void
    typealias CancelCallback = () -> Void

    // Show or hide the mock tab bar for previewing.
    private let previewEnabled: Bool
    /// 数据model
    private let viewModel: RankViewModel
    private let previewAnimationDuration = 0.3
    /// 确定点击事件
    private let confirmCallback: ConfirmCallback?
    private let cancelCallback: CancelCallback?
    // swiftlint:disable all
    lazy var container = RankView(previewEnabled: previewEnabled)
    // swiftlint:enable all

    var transitionManager: RankViewTransitionManager? {
        didSet {
            modalPresentationStyle = .custom
            transitioningDelegate = transitionManager
        }
    }

    required init(viewModel: RankViewModel,
                  previewEnabled: Bool,
                  userResolver: UserResolver,
                  confirmCallback: ConfirmCallback? = nil,
                  cancelCallback: CancelCallback? = nil) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.previewEnabled = previewEnabled
        self.confirmCallback = confirmCallback
        self.cancelCallback = cancelCallback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bindActions()
        reloadTabs()
        container.rankTableView.setEditing(true, animated: true)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tabStyleDidChange),
            name: AnimatedTabBarController.styleChangeNotification,
            object: nil
        )
    }

    @objc private func tabStyleDidChange() {
        dismiss(animated: false)
    }

    private func bindActions() {
        container.rankTableView.delegate = self
        container.rankTableView.dataSource = self
        container.cancelButton.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        container.confirmButton.addTarget(self, action: #selector(confirmBtnTapped), for: .touchUpInside)
    }

    @objc
    func cancelBtnTapped() {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_EDIT_CANCEL))
        cancelCallback?()
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func confirmBtnTapped() {
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
        Tracker.post(TeaEvent(Homeric.NAVIGATION_EDIT_MENU_MOBILE_CLICK, params: params))
        let mainItems = viewModel.allItems(at: .mainItemSection)
        let quickItems = viewModel.allItems(at: .quickItemSection)
        confirmCallback?(self, viewModel.changed(), mainItems, quickItems)
    }
}

// MARK: 数据源
extension RankViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.itemsCount(at: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RankViewCell.Config.identifier, for: indexPath)
        guard let rankCell = cell as? RankViewCell,
              let info = viewModel.itemInfo(in: indexPath.section, at: indexPath.row) else { return cell }
        rankCell.refresh(info: info, isQuick: indexPath.section == .quickItemSection, canDelete: info.canDelete) { [weak self] type in
            switch type {
            case .add(let cell): self?.addItem(cell)
            case .delete(let cell): self?.deleteItem(cell)
            case .deleteThoroughly(cell: let cell): self?.deleteThoroughlyItem(cell)
            }
        }
        return rankCell
    }

    private func reloadTabs() {
        for tab in container.preview.arrangedSubviews {
            tab.removeFromSuperview()
        }
        viewModel.allItems(at: .mainItemSection).forEach { item in
            let tabItem = makeTabItem(withIcon: item.stateConfig.defaultIcon, name: item.name, iconInfo: item.tab.tabIcon)
            container.preview.addArrangedSubview(tabItem)
        }
        let tabItem = makeTabItem(withIcon: UDIcon.getIconByKey(.moreLauncherOutlined, iconColor: UIColor.ud.iconN3),
                                  name: BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore)
        container.preview.addArrangedSubview(tabItem)
    }

    private func removeTabItemFromPreview(forRowAt row: Int) {
        for (index, _) in container.preview.arrangedSubviews.enumerated() where index == row {
            let tab = container.preview.arrangedSubviews[index]
            UIView.animate(withDuration: previewAnimationDuration) {
                tab.alpha = 0
                tab.isHidden = !tab.isHidden
            } completion: { (_) in
                tab.removeFromSuperview()
            }
        }
    }

    private func insertTabItemToPreview(tabItemInfo info: RankItem, forRowAt row: Int) {
        for (index, _) in container.preview.arrangedSubviews.enumerated() where index == row {
            let tab = makeTabItem(withIcon: info.stateConfig.defaultIcon, name: info.name, iconInfo: info.tab.tabIcon)
            tab.alpha = 0
            tab.isHidden = true
            self.container.preview.insertArrangedSubview(tab, at: row)
            UIView.animate(withDuration: previewAnimationDuration) {
                tab.alpha = 1
                tab.isHidden = !tab.isHidden
            }
        }
    }

    private func makeTabItem(withIcon icon: UIImage?, name: String, iconInfo: TabCandidate.TabIcon? = nil) -> UIView {
        let itemView = MainTabBarItemView(userResolver: userResolver)
        itemView.configure(icon: icon, text: name, iconInfo: iconInfo)
        return itemView
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: RankViewHeader.Config.identifier
        ) as? RankViewHeader else {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
        }
        header.label.text = viewModel.headerTitle(at: section)
        return header
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return viewModel.canEdit(in: indexPath.section, at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: 事件托管
extension RankViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 设置item高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RankViewCell.Config.cellHeight
    }

    // 设置header高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RankViewHeader.Config.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath != destinationIndexPath {
            viewModel.move(from: sourceIndexPath, to: destinationIndexPath)
            reloadTabs()
            DispatchQueue.main.async {
                guard let destCell = tableView.cellForRow(at: destinationIndexPath) as? RankViewCell,
                      let destInfo = self.viewModel.itemInfo(
                        in: destinationIndexPath.section,
                        at: destinationIndexPath.row
                      ) else { return }
                let isCustomType = destInfo.tab.isCustomType()
                let isUserPined = destInfo.tab.isUserPined()
                // 是自定义类型并且是用户自己添加的可以删除
                let canDelete = isCustomType && isUserPined
                destCell.refreshEditButton(info: destInfo, isQuick: destinationIndexPath.section == .quickItemSection, canDelete: canDelete)
            }
        } else if let tips = viewModel.tips {
            UDToast.showTips(with: tips, on: self.view)
        }
        viewModel.tips = nil
    }

    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return viewModel.canMove(from: sourceIndexPath, to: proposedDestinationIndexPath)
    }

    func addItem(_ cell: RankViewCell) {
        guard let indexPath = container.rankTableView.indexPath(for: cell),
              let item = viewModel.itemInfo(in: indexPath.section, at: indexPath.row) else { return }
        if container.rankTableView.numberOfRows(inSection: .mainItemSection) < viewModel.maxTabCount {
            viewModel.remove(at: indexPath)
            container.rankTableView.deleteRows(at: [indexPath], with: .fade)
            viewModel.append(item, at: .mainItemSection)
            let newIndexPath = IndexPath(row: container.rankTableView.numberOfRows(inSection: .mainItemSection),
                                         section: .mainItemSection)
            container.rankTableView.insertRows(at: [newIndexPath], with: .fade)
            insertTabItemToPreview(tabItemInfo: item, forRowAt: newIndexPath.row)
        } else {
            UDToast.showTips(
                with: BundleI18n.AnimatedTabBar.Lark_Legacy_BottomNavigationItemMaxReachedToast(viewModel.maxTabCount),
                on: self.view
            )
        }
    }

    func deleteItem(_ cell: RankViewCell) {
        guard let indexPath = container.rankTableView.indexPath(for: cell),
              let item = viewModel.itemInfo(in: indexPath.section, at: indexPath.row) else { return }
        if container.rankTableView.numberOfRows(inSection: .mainItemSection) > viewModel.minTabCount {
            viewModel.remove(at: indexPath)
            container.rankTableView.deleteRows(at: [indexPath], with: .automatic)
            viewModel.append(item, at: .quickItemSection)
            let newIndexPath = IndexPath(row: container.rankTableView.numberOfRows(inSection: .quickItemSection),
                                         section: .quickItemSection)
            container.rankTableView.insertRows(at: [newIndexPath], with: .automatic)
            removeTabItemFromPreview(forRowAt: indexPath.row)
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

    func deleteThoroughlyItem(_ cell: RankViewCell) {
        guard let indexPath = container.rankTableView.indexPath(for: cell),
              let item = viewModel.itemInfo(in: indexPath.section, at: indexPath.row) else { return }
        // 当不在主导航或者在主导航上Item数量大于最小数量时才可以删除
        if indexPath.section == .quickItemSection || container.rankTableView.numberOfRows(inSection: .mainItemSection) > viewModel.minTabCount {
            viewModel.remove(at: indexPath)
            container.rankTableView.deleteRows(at: [indexPath], with: .automatic)
            if indexPath.section == .mainItemSection {
                removeTabItemFromPreview(forRowAt: indexPath.row)
            }
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
