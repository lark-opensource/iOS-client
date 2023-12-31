//
//  FeedFilterListViewController.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import RxDataSources
import LarkSDKInterface
import LarkSwipeCellKit
import LKCommonsLogging
import LarkKeyCommandKit
import LarkPerf
import AppReciableSDK
import LarkZoomable
import LarkModel
import LarkSceneManager
import UniverseDesignEmpty
import RustPB
import LarkContainer
import LarkOpenFeed
import LarkAccountInterface
import Swinject

final class FeedFilterListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.dependency.userResolver }
    let tableView: FeedTableView = {
        let tableView = FeedTableView(frame: .zero, style: .grouped)
#if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.fillerRowHeight = 0
            tableView.sectionHeaderTopPadding = .zero
        }
#endif
        return tableView
    }()
    let headerView = FeedFilterHeaderView()
    let viewModel: FeedFilterListViewModel
    let disposeBag = DisposeBag()
    let defaultCellIdentifier = "defaultCellIdentifier"
    weak var delegate: PopoveContentControllerDelegate?
    @ScopedInjectedLazy private var guideService: FeedThreeColumnsGuideService?

    init(viewModel: FeedFilterListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fullReload()
        let offset = viewModel.dependency.getLastOffset()
        tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.dependency.saveCurrentOffset(tableView.contentOffset.y)
    }

    private var dataSource: [FilterItemModel] {
        return viewModel.dependency.filterItems
    }

    private func isMultiLevelTab(_ tab: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        let multiLevelTabs = viewModel.dependency.multiLevelTabs
        return multiLevelTabs.contains(tab)
    }

    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < dataSource.count else {
            return CGFloat.leastNormalMagnitude
        }
        let filterItemModel = dataSource[section]
        if isMultiLevelTab(filterItemModel.type) {
            return 48
        }
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < dataSource.count else {
            return nil
        }

        let filterItemModel = dataSource[section]
        guard isMultiLevelTab(filterItemModel.type),
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FeedFilterListSectionHeader.identifier) as? FeedFilterListSectionHeader else {
            return nil
        }
        let currentTab = viewModel.dependency.currentTab
        let expand = viewModel.dependency.getExpandState(id: filterItemModel.type.rawValue)
        header.set(section, filterItemModel,
                   selectedType: currentTab,
                   selectedId: viewModel.getSubTabId(filterItemModel.type),
                   expand: expand)
        header.delegate = self
        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSource.count else { return 0 }
        let type = dataSource[section].type
        if isMultiLevelTab(type) {
            let expand = viewModel.dependency.getExpandState(id: type.rawValue)
            return expand ? viewModel.dependency.getItemsByTab(type).count : 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < dataSource.count else { return 0 }
        let type = dataSource[indexPath.section].type
        if isMultiLevelTab(type) {
            let expand = viewModel.dependency.getExpandState(id: type.rawValue)
            return expand ? 48 : 0
        }
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < dataSource.count else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }
        let tab = dataSource[indexPath.section].type
        let items = viewModel.dependency.getItemsByTab(tab)
        guard indexPath.row < items.count else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }

        if isMultiLevelTab(tab),
           let cell = tableView.dequeueReusableCell(withIdentifier: FeedFilterListSubItemCell.identifier, for: indexPath) as? FeedFilterListSubItemCell {
            // 二级分组
            cell.set(items[indexPath.row])
            return cell
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: FeedFilterListCell.identifier, for: indexPath) as? FeedFilterListCell {
            // 一级分组
            cell.set(items[indexPath.row])
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section < dataSource.count else { return }
        let type = dataSource[indexPath.section].type
        if isMultiLevelTab(type) {
            didClickSecondLevelTab(type, indexPath)
        } else {
            didClickFirstLevelTab(type, indexPath.section)
        }
    }
}

extension FeedFilterListViewController {
    /// 处理常规 filter 选项点击和团队/标签的一级选项点击事件
    func didClickFirstLevelTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ tabIndex: Int) {
        // 触发汉堡菜单引导条件 - 分组侧栏选中一个分组选项
        guideService?.triggerThreeColumnsGuide(scene: .slideThreeColumn)

        // 相同选项重复点击
        guard !isRepeatClickFirstLevelTab(type) else {
            self._dismiss(animated: true)
            return
        }

        viewModel.resetSubTabId()

        var expand: Bool?
        if isMultiLevelTab(type) {
            expand = viewModel.dependency.getExpandState(id: type.rawValue)
        }
        FeedTracker.ThreeColumns.Click.firstLevelTabClick(type: type,
                                                          tabOrder: String(tabIndex + 1),
                                                          isSecondLevelTabUnfold: expand)
        let info = FeedBaseErrorInfo(type: .info(track: false), objcId: "", errorMsg: "firstLevel, current: \(self.viewModel.dependency.currentTab), new: \(type)", error: nil)
        FeedExceptionTracker.Filter.threeColumns(node: .changeViewTab, info: info)
        viewModel.dependency.selectFilterTab(type, nil)
        self._dismiss(animated: true)
    }

    private func isRepeatClickFirstLevelTab(_ type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        // 点击type与当前列表type一致
        guard viewModel.dependency.currentTab == type else { return false }

        // 若点击的二级选项则返回 false
        if isMultiLevelTab(type) {
            if let recordId = getSecondLevelTabId(type), !recordId.isEmpty {
                return false
            }
        }
        return true
    }

    /// 处理常规 filter 选项点击事件，以及团队/标签的二级选项点击事件
    private func didClickSecondLevelTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ indexPath: IndexPath) {
        guard isMultiLevelTab(type) else { return }
        // 触发汉堡菜单引导条件 - 分组侧栏选中一个分组选项
        guideService?.triggerThreeColumnsGuide(scene: .slideThreeColumn)

        // 相同选项重复点击
        guard !isRepeatClickSecondLevelTab(type, indexPath) else {
            self._dismiss(animated: true)
            return
        }

        let dataId = getSecondLevelTabIdFromData(type, indexPath)
        if let hadDataId = dataId {
            viewModel.setSubTabId(type, subId: hadDataId)
        } else {
            viewModel.resetSubTabId()
        }
        FeedTracker.ThreeColumns.Click.secondLevelTabClick(tabName: FeedTracker.Group.Name(groupType: type))
        let detailMsg = "secondLevel, current: \(self.viewModel.dependency.currentTab), new: \(type), dataId: \(dataId ?? "0")"
        let info = FeedBaseErrorInfo(type: .info(track: false), objcId: "", errorMsg: detailMsg, error: nil)
        FeedExceptionTracker.Filter.threeColumns(node: .changeViewTab, info: info)
        viewModel.dependency.selectFilterTab(type, dataId)
        viewModel.currentSelection = FeedFilterSelection(type: type, secLevelId: dataId)
        self._dismiss(animated: true)
    }

    private func isRepeatClickSecondLevelTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ indexPath: IndexPath) -> Bool {
        // 点击type与当前列表type一致
        guard viewModel.dependency.currentTab == type else { return false }

        // 若点击的二级不同选项则返回 false
        if isMultiLevelTab(type) {
            // dataId = nil 代表无效的二级选项点击 返回true以跳出
            // recordId = nil 代表二级选项未点击 返回false
            // recordId != dataId 代表二级不同选项的点击 返回false
            guard let dataId = getSecondLevelTabIdFromData(type, indexPath), !dataId.isEmpty else {
                return true
            }
            guard let recordId = getSecondLevelTabId(type), !recordId.isEmpty else {
                return false
            }
            if recordId != dataId {
                return false
            }
        }

        return true
    }

    private func getSecondLevelTabId(_ type: Feed_V1_FeedFilter.TypeEnum) -> String? {
        return viewModel.getSubTabId(type)
    }

    private func getSecondLevelTabIdFromData(_ type: Feed_V1_FeedFilter.TypeEnum, _ indexPath: IndexPath) -> String? {
        guard isMultiLevelTab(type) else { return nil }
        let items = viewModel.dependency.getItemsByTab(type)
        guard indexPath.row < items.count else { return nil }
        return items[indexPath.row].subTabId
    }
}

extension FeedFilterListViewController: FeedFilterListSectionHeaderDelegate {
    func expandAction(_ header: FeedFilterListSectionHeader, type: Feed_V1_FeedFilter.TypeEnum, isExpanded: Bool) {
        if isMultiLevelTab(type) {
            viewModel.dependency.updateExpandState(id: type.rawValue, isExpand: isExpanded)
        }
        self.fullReload()
    }

    func selectAction(_ header: FeedFilterListSectionHeader, type: Feed_V1_FeedFilter.TypeEnum, _ tabIndex: Int) {
        didClickFirstLevelTab(type, tabIndex)
    }
}
