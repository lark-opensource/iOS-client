//
//  V3ListViewModel+Fetch.swift
//  Todo
//
//  Created by wangwanxin on 2022/11/9.
//

import Foundation
import RxCocoa
import RxSwift

// MARK: - List Fetch Data

extension V3ListViewModel {

    func resetContainer() {
        listScene.temporary = nil
        selectedGuid = nil
        newCreatedGuid = nil
        trySetupHeartbeat()
    }

    func willFetchListData() {
        onListUpdate?(.resetOffset)
        newCreatedGuid = nil
    }

    func fetchListData() {
        guard isTaskList else {
            // 从本地拿取数据，用于我负责的，我关注的，快速访问
            queue.addTask { [weak self] in return self?.makeListViewData() }
            return
        }
        // 用于清单
        removeTaskListFoldState()
        rxViewState.accept(.loading)
        listApi?.getTaskContainerGroupInfo(
            by: curContainerID,
            view: curView.metaData ?? .init(),
            timeZone: curTimeContext.timeZone,
            count: Utils.List.fetchCount.initial
        )
        .take(1).asSingle()
        .observeOn(MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] data in
            self?.hanleGroupInfoResult(metaData: data)
        }, onError: { [weak self] _ in
            self?.rxViewState.accept(.failed())
            V3Home.logger.error("get group info failed")
        })
        .disposed(by: disposeBag)
    }

    func retryFetch() {
        fetchListData()
    }

    func loadMore() {
        guard let listMetaData = listScene.temporary else { return }
        guard let nextFetchIds = leftTaskGuids(from: listMetaData), !nextFetchIds.isEmpty else {
            V3Home.logger.info("not necessary load more")
            return
        }
        listApi?.getContainerTasks(
            by: curContainerID,
            taskGuids: Array(nextFetchIds.prefix(Utils.List.fetchCount.loadMore))
        )
        .take(1).asSingle()
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onSuccess: { [weak self] data in
            self?.handleContainerTasks(newMetaData: data)
        }, onError: { [weak self] _ in
            self?.rxViewState.accept(.failed(.needsRetry))
            V3Home.logger.error("get container tasks failed")
        })
        .disposed(by: disposeBag)
    }

    private func hanleGroupInfoResult(metaData: ListMetaData) {
        guard let firstScreenTasks = metaData.tasks  else {
            V3Home.logger.error("first screen data is nil")
            return
        }
        listScene.temporary = metaData
        // 是否加载更多，默认是没有
        let hasMore = metaData.taskGuids?.count ?? 0 > firstScreenTasks.count

        queue.addTask { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            return self.makeListViewData(hasMore: hasMore)
        }
    }

    private func handleContainerTasks(newMetaData: ListMetaData) {
        guard var metaData = listScene.temporary else { return }
        // 记录数据
        if let tasks = newMetaData.tasks, !tasks.isEmpty {
            var normalTasks = [Rust.Todo](), removedTasks = [Rust.Todo]()
            let userID = curUserId
            tasks.forEach { task in
                if task.isRemoved(userID, ignoreRole: true) {
                    removedTasks.append(task)
                } else {
                    normalTasks.append(task)
                }
            }
            if !removedTasks.isEmpty {
                V3Home.logger.info("removed tasks count \(removedTasks.count)")
                metaData.taskGuids?.removeAll(where: { id in
                    return removedTasks.contains(where: { $0.guid == id })
                })
            }
            metaData.tasks?.append(contentsOf: normalTasks)
        }
        if !newMetaData.refs.isEmpty {
            metaData.refs.append(contentsOf: newMetaData.refs)
        }
        listScene.temporary = metaData
        let hasMore = (leftTaskGuids(from: metaData)?.count ?? 0) > 0
        queue.addTask { [weak self] () -> V3ListViewData? in
            guard let self = self else { return nil }
            return self.makeListViewData(hasMore: hasMore)
        }
    }

    private func leftTaskGuids(from metaData: ListMetaData) -> [String]? {
        let existedTaskGuids = metaData.tasks?.map { $0.guid }

        let nextFetchIds = metaData.taskGuids?
            .filter { id in
                guard let existedTaskGuids = existedTaskGuids else {
                    return true
                }
                return !existedTaskGuids.contains(where: { $0 == id })
            }
        V3Home.logger.info("left task guid count is \(nextFetchIds?.count)")
        return nextFetchIds
    }

}
