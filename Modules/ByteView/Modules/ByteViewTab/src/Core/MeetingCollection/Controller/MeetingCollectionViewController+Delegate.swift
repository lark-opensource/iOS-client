//
//  MeetingCollectionViewController+Delegate.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import RxSwift

extension MeetingCollectionViewController: MeetTabDataSourceDelegate {
    var viewIsRegular: Bool {
        Util.rootTraitCollection?.isRegular ?? false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionItem = historyDataSource.sectionModels[safeAccess: indexPath.section],
              let item = historyDataSource.getVisibleItems(from: sectionItem)[safeAccess: indexPath.row] as? MeetingCollectionCellViewModel else { return }
        MeetTabTracks.trackClickCollection(with: item.meetingID)
        self.gotoMeetingDetail(tabListItem: item.vcInfo)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tabResultView.tableView else { return }
        let length = abs(headerView.contentStackView.frame.origin.y - naviBar.bounds.height)
        let offset = min(scrollView.contentOffset.y, length)
        let alpha = offset / length
        naviBar.updateBgAlpha(alpha)
        updateTableViewBackgroundViewHeight(scrollView.contentOffset.y)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if preloadEnabled,
           viewModel.historyDataSource.current.count > MeetingCollectionViewModel.preLoadBuffer,
           indexPath.row >= (viewModel.historyDataSource.current.count - MeetingCollectionViewModel.preLoadBuffer) {
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
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
}
