//
//  FlagListViewController+BindData.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/20.
//

import Foundation
import RxSwift

struct DataSourceDiff {
    // 删除的数据
    var deletedItems: [IndexPath] = []
}

extension FlagListViewController {
    func bindData() {
        // 和自己VM的数据源绑定
        self.viewModel.datasource.asDriver().skip(1)
            .drive(onNext: { [weak self] (datasource) in
                guard let `self` = self else { return }

                if self.viewModel.refreshType == .delete, let result = self.getDiffResult(diff: datasource) {
                    // 删除的话需要特殊处理，有删除动画
                    FlagListViewController.logger.info("LarkFlag: [DataSourceUpdated] refreshType = .delete, count = \(result.deletedItems.count), deletedItems = \(result.deletedItems)")
                    // 执行完block后会调用reloadData，在这之前需要更新数据源
                    let deleteBlock = { [weak self] in
                        guard let self = self else { return }
                        self.tableView.deleteRows(at: result.deletedItems, with: .fade)
                        // 更新数据源：必须要在tableView调用reloadData之前
                        self.datasource = datasource
                    }
                    self.tableView.performBatchUpdates(deleteBlock, completion: nil)
                } else {
                    // 插入和更新的话简单替换数据源并reloadData就行
                    FlagListViewController.logger.info("LarkFlag: [DataSourceUpdated] refreshType = .reload")
                    // 更新数据源
                    self.datasource = datasource
                    // 重新刷新tableView
                    self.tableView.reloadData()
                }
                // 判断是否要显示空页面
                let showEmptyView = self.datasource.isEmpty
                self.viewModel.showEmptyViewRelay.accept(showEmptyView)
                // 移除loading
                self.loadingHud?.remove()
                self.loadingHud = nil
                // 日志
                let ids = self.datasource.map { flagItem in
                    flagItem.uniqueId
                }
                FlagListViewController.logger.info("LarkFlag: [DataSourceUpdated] ids = \(ids), count = \(self.datasource.count) , totalCount = \(self.viewModel.totalCount)")
            })
            .disposed(by: self.disposeBag)
        // 触发TableView刷新之后，需要检查一下是否添加空态页
        self.viewModel.showEmptyViewObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] showEmptyView in
                guard let self = self else { return }
                self.showOrRemoveEmptyView(showEmptyView)
            }).disposed(by: self.disposeBag)
        // 加载首屏数据
        self.viewModel.loadMore()
    }

    func getDiffResult(diff: [FlagItem]) -> DataSourceDiff? {
        let newData = diff
        let oldData = self.datasource
        var deletedItems: [IndexPath] = []
        for (index, element) in oldData.enumerated() {
            if !isItemInSource(flagItem: element, source: newData) {
                // 如果旧的数据源里面某一条数据不在新的数据源中，那么这条数据应该需要删除，把位置记录下来
                deletedItems.append(IndexPath(item: index, section: 0))
            }
        }
        if deletedItems.isEmpty {
            return nil
        }
        var result = DataSourceDiff()
        result.deletedItems = deletedItems
        return result
    }

    func isItemInSource(flagItem: FlagItem, source: [FlagItem]) -> Bool {
        var result = false
        for item in source where (item.uniqueId == flagItem.uniqueId) {
            result = true
        }
        return result
    }
}
