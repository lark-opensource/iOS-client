//
//  MeetTabViewController+LoadMore.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import RxCocoa
import RxSwift
import ByteViewTracker

extension MeetTabViewController {
    func setupHistory() {
        tabResultView.tableView.dataSource = historyDataSource
        historyDataSource.delegate = self

        viewModel.upcomingSectionObservable.subscribe(onNext: { [weak self] (section, refresh)  in
                guard let self = self else { return }
                guard refresh else { return }
                self.viewModel.upComingSectionViewModel = section
                let sectionModels = self.viewModel.ongoingSectionViewModel + self.viewModel.upComingSectionViewModel + self.viewModel.historySectionViewModel
                self.historyDataSource.updateData(sectionModels)
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.tabResultView.tableView.reloadData()
                    }
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.ongoingSectionObservable.subscribe(onNext: { [weak self] (section, refresh)  in
                guard let self = self else { return }
                guard refresh else { return }
                self.viewModel.ongoingSectionViewModel = section
                let sectionModels = self.viewModel.ongoingSectionViewModel + self.viewModel.upComingSectionViewModel + self.viewModel.historySectionViewModel
                self.historyDataSource.updateData(sectionModels)
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.tabResultView.tableView.reloadData()
                    }
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.historySectionObservable.subscribe(onNext: { [weak self] (section, refresh)  in
                guard let self = self else { return }
                guard refresh else { return }
                self.viewModel.historySectionViewModel = section
                let sectionModels = self.viewModel.ongoingSectionViewModel + self.viewModel.upComingSectionViewModel + self.viewModel.historySectionViewModel
                self.historyDataSource.updateData(sectionModels)
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.tabResultView.tableView.reloadData()
                    }
                }
            })
            .disposed(by: rx.disposeBag)

        tabResultView.tableView.rx
            .setDelegate(historyDataSource)
            .disposed(by: rx.disposeBag)
    }

    func addLoadMore<T: DiffDataProtocol>(
        _ diffDataSource: DiffDataSource<T>,
        tableView: UITableView,
        disposeBag: DisposeBag
    ) {
        diffDataSource.addLoading
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                tableView.es.stopPullToRefresh(ignoreFooter: true)
                AppreciableTracker.shared.end(.vc_tab_pull_time)
            })
            .disposed(by: disposeBag)

        diffDataSource.checkLoading
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                AppreciableTracker.shared.end(.vc_tab_load_more_time)
            })
            .disposed(by: disposeBag)
    }

    func addHistoryLoadMore() {
        historyLoadMoreBag = DisposeBag()
        addLoadMore(
            viewModel.historyDataSource,
            tableView: tabResultView.tableView,
            disposeBag: historyLoadMoreBag
        )
    }

    func addHistoryRefreshBar() {
        tabResultView.tableView.es
            .addPullToRefresh(animator: historyRefreshAnimator) { [weak self] in
                AppreciableTracker.shared.start(.vc_tab_pull_time)
                self?.addHistoryLoadMore()
                self?.viewModel.loadTabData(false)
                self?.preloadEnabled = true
            }
    }

    func addLoadError<T: DiffDataProtocol>(
        _ diffDataSources: [DiffDataSource<T>],
        result: MeetTabResultView
    ) {
        Observable.combineLatest(diffDataSources.map { $0.loadStatus })
            .map { $0.mergedStatus }
            .distinctUntilChanged { $0 == .result && $1 == .loadError } // 有数据则忽略错误
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                result.statusObserver.onNext(status)
                if self.layoutStyle == .regular {
                    self.containerView.isScrollEnabled = false
                } else {
                    self.containerView.isScrollEnabled = (status == .result)
                }
                if status != .result {
                    self.resetContainerViewContentOffset()
                }
            })
            .disposed(by: rx.disposeBag)
    }

}

extension MeetTabViewController: TabDataObserver {
    func didChangeNetStatus(status: MeetTabViewModel.NetworkStatus) {
        guard status != .weak else {
            Toast.show(I18n.View_G_InternetConnectionPoor, on: view)
            return
        }
        let height = (status == .good) ? 0 : Layout.netHeight
        DispatchQueue.main.async {
            self.noInternetView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
        }
    }
}

extension DiffDataSource {
    var loading: Observable<DiffDataSource.DataResult> {
        return result.filter({ result -> Bool in
            switch result {
            case .loadResults, .loadError: return true
            default: return false
            }
        })
    }

    var addLoading: Observable<Bool> {
        return loading.take(1).map({ result -> Bool in
            switch result {
            case let .loadResults(_, hasMore): return hasMore
            case .loadError: return false
            default: return false
            }
        })
    }

    var checkLoading: Observable<Bool> {
        return loading.skip(1).map({ result -> Bool in
            switch result {
            case let .loadResults(_, hasMore): return hasMore
            case .loadError: return true
            default: return false
            }
        })
    }

    var loadStatus: Observable<MeetTabResultStatus> {
        return result.map { $0.loadStatus }
    }
}

extension DiffDataSource.DataResult {
    var loadStatus: MeetTabResultStatus {
        switch self {
        case let .eventResults(items):
            return items.isEmpty ? .noResult : .result
        case .loadError:
            return .loadError
        case let .loadResults(items, _):
            return items.isEmpty ? .noResult : .result
        case .loadingResults:
            return .loading
        }
    }
}

extension MeetTabResultStatus {
    static func & (lhs: MeetTabResultStatus, rhs: MeetTabResultStatus) -> MeetTabResultStatus {
        switch (lhs, rhs) {
        case (.result, _), (_, .result):
            return .result
        case (.loading, _), (_, .loading):
            return .loading
        case (.loadError, _), (_, .loadError):
            return .loadError
        case (.noResult, _), (_, .noResult):
            return .noResult
        }
    }
}

extension Array where Element == MeetTabResultStatus {
    var mergedStatus: MeetTabResultStatus {
        return self.reduce(.noResult) { $0 & $1 }
    }
}
