//
//  FeedTeamViewController+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/19.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkModel
import RustPB

extension FeedTeamViewController {
    func bind() {
        viewModel.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else { return }
                switch self.getSwitchModeModule() {
                case .threeBarMode(_):
                    self.viewModel.dependency.filterDataStore.FilterReloadRelay.accept(())
                case .standardMode:
                    break
                }
                self.render()
                self.showOrRemoveEmptyView()
                self.backFirstListWhenExist()
                self.setTableFooterDisplay()
            }).disposed(by: disposeBag)

        viewModel.loadingStateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else { return }
                self.showOrHidenLoading()
            }).disposed(by: disposeBag)

        // 监听选中态
        subscribeSelect()
        observSelectFeedTab()

        // 监听截屏事件打log
        screenShot()

        // 监听filter action
        let filterGroupAction = try? userResolver.resolve(assert: FilterActionHandler.self)
        filterGroupAction?.groupActionSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                self?.handleAction(action)
            }).disposed(by: disposeBag)
    }

    func render() {
        switch viewModel.teamUIModel.renderType {
        case .fullReload:
            fullReload()
        case .reloadSection(let section):
            reloadSection(section)
        }
    }

    func reloadSection(_ section: Int) {
        guard !viewModel.isQueueState() else { return }
        guard section < tableView.numberOfSections else {
            fullReload()
            return
        }
        let task = {
            self.tableView.reloadSections(IndexSet(integer: section), with: .fade)
        }
        self.tableView.performBatchUpdates(task, completion: nil)
    }

    func fullReload() {
        if !viewModel.isQueueState() {
            tableView.reloadData()
        }
    }
}
