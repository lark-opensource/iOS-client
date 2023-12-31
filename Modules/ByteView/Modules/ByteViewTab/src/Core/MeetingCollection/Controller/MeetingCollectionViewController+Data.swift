//
//  MeetingCollectionViewController+Data.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import RxSwift

extension MeetingCollectionViewController {

    func setupHistory() {
        tabResultView.tableView.dataSource = historyDataSource
        historyDataSource.delegate = self

        viewModel.historySectionObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] section in
                self?.historyDataSource.updateData(section)
                UIView.performWithoutAnimation {
                    self?.tabResultView.tableView.reloadData()
                    self?.configHeaderView()
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
            })
            .disposed(by: disposeBag)

        diffDataSource.checkLoading
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
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
                self?.addHistoryLoadMore()
                self?.viewModel.loadData(false)
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
                guard self != nil else { return }
                result.statusObserver.onNext(status)
            })
            .disposed(by: rx.disposeBag)
    }

}
