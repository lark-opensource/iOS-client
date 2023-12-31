//
//  FeedTeamViewModel+DataQueue.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation

extension FeedTeamViewModel {
    func frozenDataQueue(_ taskType: FeedDataQueueTaskType) {
        FeedContext.log.info("teamlog/queue/frozen. old: \(isQueueState())")
        dataQueue.isSuspended = true
    }

    func resumeDataQueue(_ taskType: FeedDataQueueTaskType) {
        FeedContext.log.info("teamlog/queue/resume. old: \(isQueueState())")
        dataQueue.isSuspended = false
    }

    func isQueueState() -> Bool {
        dataQueue.isSuspended
    }

    func addTask(_ task: @escaping () -> Void) {
        let t = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataState = .localHandle
            task()
            self.dataSourceCache.dataState = .ready
            self.outputData(self.dataSourceCache)
            self.dataSourceCache.renderType = .fullReload
            self.dataSourceCache.dataFrom = .unknown
        }
        dataQueue.addOperation(t)
    }

    private func outputData(_ dataSource: FeedTeamDataSourceInterface) {
        var dataSource1 = dataSource
        dataSource1.removeHidenChats()
        fireRefresh(dataSource1)
    }

    private func fireRefresh(_ dataSource: FeedTeamDataSourceInterface) {
        DispatchQueue.main.async { [dataSource, weak self] in
            guard let self = self else { return }
            FeedContext.log.info("teamlog/output. \(dataSource.uiDescription)")
            self.dataSourceRelay.accept(dataSource)
        }
    }

}
