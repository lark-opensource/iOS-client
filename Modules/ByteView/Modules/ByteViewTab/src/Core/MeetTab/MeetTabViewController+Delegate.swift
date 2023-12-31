//
//  MeetTabViewController+Delegate.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import RxSwift
import ByteViewCommon

extension MeetTabViewController: MeetTabDataSourceDelegate {

    var viewIsRegular: Bool {
        return isRegular
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, cell: UITableViewCell) {
        if indexPath.row == 0 {
            setupTabListOnboarding(refView: cell)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionModel = historyDataSource.sectionModels[safeAccess: indexPath.section] else { return }
        let cellItem = historyDataSource.getVisibleItems(from: sectionModel)[safeAccess: indexPath.row]
        if let item = cellItem as? MeetTabMeetCellViewModel {
            if item is MeetTabOngoingCellViewModel {
                MeetTabTracks.trackMeetTabOperation(.clickOngoingCell, with: ["conference_id": item.vcInfo.meetingID])
            } else {
                MeetTabTracks.trackClickTabListItem(with: item.vcInfo.meetingID)
            }
            self.gotoMeetingDetail(queryID: item.vcInfo.historyID, tabListItem: item.vcInfo)
        } else if let item = cellItem as? MeetTabUpcomingCellViewModel {
            MeetTabTracks.trackMeetTabOperation(.clickUpcomingCell, with: ["meeting_number": item.instance.meetingNumber])
            self.router?.gotoCalendarEvent(calendarID: viewModel.calendarID,
                                          key: item.instance.key,
                                          originalTime: Int(item.instance.originalTime),
                                          startTime: Int(item.instance.startTime),
                                          from: self)
            // 外部状态没有通知，每次点击都拉一次最新状态
            viewModel.loadUpcomingData(false)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 在双击Tabbar跳转结束后，重新允许在滑动时显示/隐藏NaviBar
        shouldCheckNavigationBarVisibility = true
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if preloadEnabled,
           viewModel.historyDataSource.current.count > MeetTabListViewModel.preLoadBuffer,
           indexPath.row >= (viewModel.historyDataSource.current.count - MeetTabListViewModel.preLoadBuffer) {
            preloadEnabled = false
            preloadBag = DisposeBag()
            preloadWorkItem?.cancel()
            preloadWorkItem = nil
            viewModel.historyDataSource.loadMore()
            viewModel.historyDataSource.loading
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] result in
                    switch result {
                    case .loadResults(_, let hasMore):
                        self?.preloadEnabled = hasMore
                        self?.preloadBag = DisposeBag()
                    default: break
                    }
                }).disposed(by: preloadBag)
        }
    }

    func reloadTableView() {
        DispatchQueue.main.async { [weak self] in
            if let tableView = self?.tabResultView.tableView {
                tableView.reloadData()
            }
        }
    }
}
