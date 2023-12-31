//
//  MeetTabHistoryTabDataSource.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import RxDataSources
import RxSwift
import RxCocoa
import Action
import UniverseDesignColor
import ByteViewCommon
import ByteViewNetwork

struct MeetTabHistorySectionViewModel {
    var sectionItem: MeetTabSectionViewModel
    var items: [MeetTabCellViewModel]
}

extension MeetTabHistorySectionViewModel: SectionModelType {

    typealias Item = MeetTabCellViewModel

    init(original: MeetTabHistorySectionViewModel, items: [Item]) {
        self = original
        self.items = items
    }
}

protocol MeetTabDataSourceDelegate: AnyObject {

    var viewIsRegular: Bool { get }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)

    func scrollViewDidScroll(_ scrollView: UIScrollView)

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, cell: UITableViewCell)

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)

    func reloadTableView()
}

extension MeetTabDataSourceDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, cell: UITableViewCell) {}

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {}

    func reloadTableView() {}
}

class MeetTabHistoryDataSource: NSObject {

    // fix crash: https://t.wtturl.cn/hanU687/
    var isRegular: Bool {
        if let delegate = delegate {
            return delegate.viewIsRegular
        }
        return false
    }

    enum Layout {
        static let separatorHeight: CGFloat = 0.5
        static let maxCellContentWidth: CGFloat = 618.0
        static let minCellContentLandscapeMargin: CGFloat = 20.0
        static let minCellContentDefaultMargin: CGFloat = 16.0

        static func calculatePadding(bounds: CGRect) -> CGFloat {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                if bounds.width > Layout.maxCellContentWidth + 2 * Layout.minCellContentLandscapeMargin {
                    return (bounds.width - Layout.maxCellContentWidth) * 0.5
                } else {
                    return Layout.minCellContentLandscapeMargin
                }
            } else {
                return Layout.minCellContentDefaultMargin
            }
        }
    }

    static let meetCellIdentifier = String(describing: MeetTabHistoryTableViewCell.self)
    static let upcomingCellIdentifier = String(describing: MeetTabUpcomingTableViewCell.self)
    static let ongoingCellIdentifier = String(describing: MeetTabOngoingTableViewCell.self)

    static let sectionHeaderIdentifier = String(describing: MeetTabSectionHeaderView.self)
    static let padSectionHeaderIdentifier = String(describing: MeetTabPadSectionHeaderView.self)

    static let sectionFooterIdentifier = String(describing: MeetTabSectionFooterView.self)
    static let padSectionFooterIdentifier = String(describing: MeetTabPadSectionFooterView.self)

    static let loadMoreSectionFooterIdentifier = String(describing: MeetTabLoadMoreSectionFooterView.self)
    static let padLoadMoreSectionFooterIdentifier = String(describing: MeetTabPadLoadMoreSectionFooterView.self)

    static func configCell(_ tableView: UITableView) {
        tableView.register(MeetTabHistoryTableViewCell.self, forCellReuseIdentifier: meetCellIdentifier)
        tableView.register(MeetTabUpcomingTableViewCell.self, forCellReuseIdentifier: upcomingCellIdentifier)
        tableView.register(MeetTabOngoingTableViewCell.self, forCellReuseIdentifier: ongoingCellIdentifier)
    }

    static func configHeaderView(_ tableView: UITableView) {
        tableView.register(MeetTabSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: sectionHeaderIdentifier)
        tableView.register(MeetTabPadSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: padSectionHeaderIdentifier)
        tableView.register(MeetTabSectionFooterView.self, forHeaderFooterViewReuseIdentifier: sectionFooterIdentifier)
        tableView.register(MeetTabPadSectionFooterView.self, forHeaderFooterViewReuseIdentifier: padSectionFooterIdentifier)
        tableView.register(MeetTabLoadMoreSectionFooterView.self, forHeaderFooterViewReuseIdentifier: loadMoreSectionFooterIdentifier)
        tableView.register(MeetTabPadLoadMoreSectionFooterView.self, forHeaderFooterViewReuseIdentifier: padLoadMoreSectionFooterIdentifier)
    }

    var isRemovingFloatEffect: Bool = false
    @RwAtomic
    var sectionModels: [MeetTabHistorySectionViewModel] = []
    weak var delegate: MeetTabDataSourceDelegate?

    func updateData(_ sectionModels: [MeetTabHistorySectionViewModel]) {
        self.sectionModels = sectionModels
    }

    func findMeetingID(_ meetingID: String) -> (IndexPath, TabListItem)? {
        for section in 0..<sectionModels.count {
            for row in 0..<sectionModels[section].items.count {
                switch self.sectionModels[section].items[row] {
                case let meetModel as MeetTabMeetCellViewModel:
                    if meetModel.vcInfo.meetingID == meetingID {
                        return (IndexPath(row: row, section: section), meetModel.vcInfo)
                    }
                default:
                    break
                }
            }
        }
        return nil
    }

    func findHistoryID(_ historyID: String) -> (IndexPath, TabListItem)? {
        for section in 0..<sectionModels.count {
            for row in 0..<sectionModels[section].items.count {
                switch self.sectionModels[section].items[row] {
                case let meetModel as MeetTabMeetCellViewModel:
                    if meetModel.vcInfo.historyID == historyID {
                        return (IndexPath(row: row, section: section), meetModel.vcInfo)
                    }
                default:
                    break
                }
            }
        }
        return nil
    }

    func getVisibleItems(from sectionModel: MeetTabHistorySectionViewModel) -> [MeetTabCellViewModel] {
        let isRegular = isRegular
        return sectionModel.items.filter {
            if isRegular {
                return $0.visibleInTraitStyle.contains(.regular)
            } else {
                return $0.visibleInTraitStyle.contains(.compact)
            }
        }
    }
}

extension MeetTabHistoryDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard !sectionModels.isEmpty, let sectionItem = sectionModels[safeAccess: section]?.sectionItem else {
            return .leastNonzeroMagnitude
        }
        return sectionItem.headerHeightGetter(isRegular)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard !sectionModels.isEmpty, let sectionItem = sectionModels[safeAccess: section]?.sectionItem else {
            return .leastNonzeroMagnitude
        }
        return sectionItem.footerHeightGetter(sectionItem.loadStatus, isRegular)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegate?.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last,
              indexPath == lastVisibleIndexPath,
              tableView.contentOffset.y >= 0 {
            removeFloatEffect(tableView)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView)
        if scrollView is EmbeddedTableView {
            DispatchQueue.main.async {
                scrollView.showsVerticalScrollIndicator = (scrollView.contentOffset.y >= 0)
            }
            guard scrollView.contentOffset.y >= 0 else { return }
            removeFloatEffect(scrollView)
        }
    }

    private func removeFloatEffect(_ scrollView: UIScrollView) {
        guard !isRemovingFloatEffect else { return }
        isRemovingFloatEffect = true
        defer { isRemovingFloatEffect = false }
        guard let tableView = scrollView as? UITableView,
           let footerSection = tableView.indexPathsForVisibleRows?.last?.section else {
            return
        }
        // 去除悬浮效果
        // 获取是否有默认调整的内边距
        let defaultEdgeTop: CGFloat = tableView.contentInset.top
        let sectionFooterHeight: CGFloat = tableView.rectForFooter(inSection: footerSection).height

        // 下边距相关
        var edgeBottom: CGFloat = 0
        let b = tableView.contentOffset.y + tableView.frame.height
        let h = tableView.contentSize.height - sectionFooterHeight

        if b <= h {
            edgeBottom = -sectionFooterHeight
        } else if b > h && b < tableView.contentSize.height {
            edgeBottom = b - h - sectionFooterHeight
        }

        // 设置内边距
        scrollView.contentInset = UIEdgeInsets(top: defaultEdgeTop, left: 0, bottom: edgeBottom, right: 0)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndScrollingAnimation(scrollView)
    }
}

extension MeetTabHistoryDataSource: MeetTabBaseTableViewCellDelegate {
    func reloadWholeView() {
        self.delegate?.reloadTableView()
    }
}

extension MeetTabHistoryDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard !sectionModels.isEmpty else { return 0 }
        return sectionModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !sectionModels.isEmpty, let sectionModel = sectionModels[safeAccess: section] else { return 0 }
        return getVisibleItems(from: sectionModel).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !sectionModels.isEmpty,
              let sectionModel = sectionModels[safeAccess: indexPath.section],
              let item = getVisibleItems(from: sectionModel)[safeAccess: indexPath.row] else {
            return UITableViewCell()
        }
        let isLastCellInSection: Bool = indexPath.row == sectionModel.items.count - 1
        let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
        let configer = cell as? MeetTabBaseTableViewCell
        configer?.reloadStackViews(tableWidth: tableView.frame.width)
        configer?.bindTo(viewModel: item)
        if isRegular {
            configer?.showSeparator(!isLastCellInSection)
        } else {
            configer?.showSeparator(false)
        }
        configer?.delegate = self

        delegate?.tableView(tableView, cellForRowAt: indexPath, cell: cell)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !sectionModels.isEmpty, let sectionItem = sectionModels[safeAccess: section]?.sectionItem else {
            return nil
        }
        let headerView: MeetTabSectionConfigurable?
        if isRegular {
            headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.padSectionHeaderIdentifier) as? MeetTabSectionConfigurable
        } else {
            headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.sectionHeaderIdentifier) as? MeetTabSectionConfigurable
        }
        headerView?.bindTo(viewModel: sectionItem)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !sectionModels.isEmpty, let sectionItem = sectionModels[safeAccess: section]?.sectionItem else {
            return nil
        }
        let footerView: MeetTabSectionConfigurable?
        if sectionItem.loadStatus != .result {
            if isRegular {
                footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.padLoadMoreSectionFooterIdentifier) as? MeetTabSectionConfigurable
            } else {
                footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.loadMoreSectionFooterIdentifier) as? MeetTabSectionConfigurable
            }
        } else {
            if isRegular {
                footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.padSectionFooterIdentifier) as? MeetTabSectionConfigurable
            } else {
                footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionItem.sectionFooterIdentifier) as? MeetTabSectionConfigurable
            }
        }
        footerView?.bindTo(viewModel: sectionItem)
        return footerView
    }
}
