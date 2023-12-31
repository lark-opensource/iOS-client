//
//  BatchService.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation

final class BatchService {

    let timer: BatchTimer
    let uploader: BatchUploader
    let scheduler: BatchUploadScheduler

    init() {
        uploader = BatchUploader()
        timer = BatchTimer(timerInterval: Const.batchTimerInterval)
        scheduler = BatchUploadScheduler()
        timer.handler = { [weak self] in
            guard let self = self else { return }
            guard SecurityAuditManager.shared.isNetworkEnable else {
                return
            }
            guard !SecurityAuditManager.shared.conf.session.isEmpty else {
                return
            }
            guard self.scheduler.shouldUpload() else {
                return
            }
            self.uploader.upload(complete: { [weak self] result in
                guard let self = self else { return }
                self.scheduler.record(result)
            })

        }
    }
}
