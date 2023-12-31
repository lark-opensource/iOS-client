//
//  LabelMainListTableAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkOpenFeed
import LarkSwipeCellKit

/** LabelMainListTableAdapter的设计：分担VC的工作（tableView相关）
 1. 实现tableView相关协议
 2. 实现刷新table
 3. loadmore 触发器
*/

final class LabelMainListTableAdapter: NSObject, AdapterInterface, UITableViewDataSource, UITableViewDelegate {
    weak var page: LabelMainListViewController?
    let vm: LabelMainListViewModel
    // 记录侧滑的cell
    weak var swipingCell: SwipeTableViewCell?
    let disposeBag = DisposeBag()
    lazy var longPressActionPlugin = {
        FeedCardLongPressActionPlugin()
    }()
    lazy var swipeActionPlugin = {
        FeedCardSwipeActionPlugin(filterType: .tag,
                                  userResolver: vm.userResolver)
    }()

    init(vm: LabelMainListViewModel) {
        self.vm = vm
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    func setup(page: LabelMainListViewController) {
        self.page = page
        page.tableView.separatorStyle = .none
        let backgroundColor = UIColor.ud.bgBody
        page.tableView.backgroundColor = backgroundColor
        page.tableView.contentInsetAdjustmentBehavior = .never
        page.tableView.estimatedRowHeight = 0
        page.tableView.estimatedSectionHeaderHeight = 0
        page.tableView.estimatedSectionFooterHeight = 0
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            page.tableView.fillerRowHeight = 0
            page.tableView.sectionHeaderTopPadding = .zero
        }
        #endif
        page.tableView.delegate = self
        page.tableView.dataSource = self
        page.tableView.tableFooterView = page.tableFooter
        page.tableFooter.setActionHandlerAdapter(page.actionHandlerAdapter)
        FeedCardContext.registerCell?(page.tableView, vm.userResolver)

        page.tableView.register(LableFeedCell.self, forCellReuseIdentifier: LableFeedCell.identifier)
        page.tableView.register(LableSectionHeader.self, forHeaderFooterViewReuseIdentifier: LableSectionHeader.identifier)
        page.tableView.register(LableSectionFooter.self, forHeaderFooterViewReuseIdentifier: LableSectionFooter.identifier)
        vm.viewDataStateModule.renderObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] extraInfo in
                self?.render(extraInfo.render)
                self?.vm.viewDataStateModule.renderFinish(dataFrom: extraInfo.dataFrom)
        }).disposed(by: disposeBag)

        // 侧滑设置发生变化时：1. 隐藏action视图；2. 重置左右action视图配置
        vm.swipeSettingChanged.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.swipingCell?.hideSwipe(animated: false)
            FeedCardSwipeActionPlugin.leftOrientation = nil
            FeedCardSwipeActionPlugin.rightOrientation = nil
        }).disposed(by: disposeBag)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return vm.viewDataStateModule.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let label = vm.viewDataStateModule.getLabel(section: section) else { return 0 }
        guard vm.expandedModule.getExpandState(id: label.item.id) ?? false else { return 0 }
        return vm.viewDataStateModule.count(in: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath) else { return 0 }
        return feed.getHeight(mode: vm.switchModeModule.mode)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let page = self.page,
              let label = vm.viewDataStateModule.getLabel(section: indexPath.section),
              let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath) else {
            return UITableViewCell()
        }
        switch vm.switchModeModule.mode {
        case .standardMode:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LableFeedCell.identifier, for: indexPath) as? LableFeedCell else {
                   return UITableViewCell()
            }
            let isSelected = vm.selectedModule.isSelected(feedId: feed.feedPreview.id, labelId: label.item.id)
            cell.delegate = self
            cell.set(viewModel: feed, isSelected: isSelected)
            return cell
        case .threeBarMode(_):
            let item = feed.feedViewModel
            guard let cell = FeedCardContext.dequeueReusableCell(
                feedCardModuleManager: vm.dependency.feedCardModuleManager,
                viewModel: item,
                tableView: tableView,
                indexPath: indexPath) else {
                return UITableViewCell()
            }
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
              let page = self.page,
              let context = try? vm.userResolver.resolve(assert: FeedCardContext.self),
              let feed = vm.viewDataStateModule.getFeed(indexPath: indexPath) else { return }
        FeedActionFactoryManager.performJumpAction(
            feedPreview: feed.feedPreview,
            context: context,
            from: page,
            basicData: feed.feedViewModel.basicData,
            bizData: feed.feedViewModel.bizData,
            extraData: [:])
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard vm.viewDataStateModule.getLabel(section: section) != nil else {
            return 0
        }
        return LabelTableCons.sectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let page = page else { return nil }
        var labelHeader: LableSectionHeader?
        if let header = tableView.headerView(forSection: section) as? LableSectionHeader {
            /// just update  section header view
            labelHeader = header
        } else if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: LableSectionHeader.identifier) as? LableSectionHeader {
            /// create  or reuse one
            labelHeader = header
        }

        guard let labelHeader = labelHeader,
              let label = vm.viewDataStateModule.getLabel(section: section) else {
            return nil
        }

        let isExpanded = vm.expandedModule.getExpandState(id: label.item.id) ?? false
        let displayLine: Bool
        if isExpanded {
            displayLine = vm.viewDataStateModule.count(in: section) <= 0
        } else {
            displayLine = true
        }
        labelHeader.set(viewModel: label,
                   isExpanded: isExpanded,
                   displayLine: displayLine,
                   section: section,
                   labelContext: page.vm.labelContext)
        return labelHeader
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let label = vm.viewDataStateModule.getLabel(section: section) else { return 0 }
        let hasFooter = (vm.expandedModule.getExpandState(id: label.item.id) ?? false) && (vm.viewDataStateModule.count(in: section) > 0)
        return hasFooter ? LabelTableCons.sectionFooterHeight : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var labelFooter: LableSectionFooter?
        if let footer = tableView.footerView(forSection: section) as? LableSectionFooter {
            labelFooter = footer
        } else if let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: LableSectionFooter.identifier) as? LableSectionFooter {
            labelFooter = footer
        }
        guard let labelFooter = labelFooter,
              let label = vm.viewDataStateModule.getLabel(section: section),
              let isExpanded = vm.expandedModule.getExpandState(id: label.item.id),
              isExpanded == true,
              vm.viewDataStateModule.count(in: section) > 0 else {
            return nil
        }
        return labelFooter
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let label = vm.viewDataStateModule.getLabel(section: section) else {
            return
        }
        vm.viewDataStateModule.loadFeeds(labelId: label.item.id, index: section)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        vm.dataModule.dataQueue.frozenDataQueue(.draging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            page?.otherAdapter.preloadDetail()
        }
        vm.dataModule.dataQueue.resumeDataQueue(.draging)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        page?.otherAdapter.preloadDetail()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        vm.dataModule.dataQueue.resumeDataQueue(.draging)
    }

    enum LabelTableCons {
        static let sectionHeaderHeight: CGFloat = 54.0
        static let sectionFooterHeight: CGFloat = 12.0
        static let tableFooterHeight: CGFloat = 50.0
    }
}

extension LabelMainListTableAdapter {

    private func render(_ render: LabelMainListViewDataStateModule.Render) {
        switch render {
        case .none:
            break
        case .fullReload:
            fullReload()
        case .reloadSection(let section):
//            reloadSection(section)
            fullReload()
        }
        setTableFooterDisplay()
    }

    private func reloadSection(_ section: Int) {
        guard let tableView = page?.tableView else { return }
        guard section < tableView.numberOfSections else {
            fullReload()
            return
        }
        let task = {
            tableView.reloadSections(IndexSet(integer: section), with: .fade)
        }
        tableView.performBatchUpdates(task, completion: nil)
    }

    private func fullReload() {
        page?.tableView.reloadData()
    }
}

extension LabelMainListTableAdapter {
    private func setTableFooterDisplay() {
        guard let page = page else { return }
        let display = vm.viewDataStateModule.displayFooter
        guard page.tableFooter.display != display else { return }
        page.tableFooter.display = display
        let height: CGFloat = display ? LabelTableCons.tableFooterHeight : 0
        page.tableFooter.frame = CGRect(x: 0, y: 0, width: page.tableView.bounds.size.width, height: height)
        page.tableView.tableFooterView = page.tableFooter
        // TODO: 修改tableFooter高度，是否需要设置下面两行
//        page.tableView.beginUpdates()
//        page.tableView.endUpdates()
    }
}
