//
//  HiddenChatListViewModel+DataQueue.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation

extension HiddenChatListViewModel {
    func frozenDataQueue(_ taskType: FeedDataQueueTaskType) {
        FeedContext.log.info("teamlog/hidden/queue/frozen. old: \(isQueueState())")
        dataQueue.isSuspended = true
    }

    func resumeDataQueue(_ taskType: FeedDataQueueTaskType) {
        FeedContext.log.info("teamlog/hidden/queue/resume. old: \(isQueueState())")
        dataQueue.isSuspended = false
    }

    func isQueueState() -> Bool {
        dataQueue.isSuspended
    }

    func addTask(_ task: @escaping () -> Void) {
        let t = { [weak self] in
            guard let self = self else { return }
            task()
            self.outputData(self.dataSourceCache)
        }
        dataQueue.addOperation(t)
    }

    private func outputData(_ dataSource: FeedTeamItemViewModel) {
        var dataSource1 = dataSource
        dataSource1.removeShownChats()
        fireRefresh(dataSource1)
    }

    private func fireRefresh(_ dataSource: FeedTeamItemViewModel) {
        DispatchQueue.main.async { [dataSource, weak self] in
            guard let self = self else { return }
            FeedContext.log.info("teamlog/hidden/output. \(dataSource.description)")
            self.dataSourceRelay.accept(dataSource)
        }
    }

}
