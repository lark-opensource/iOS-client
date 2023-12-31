//
//  MailPreloadImageEvent.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/28.
//

import Foundation

class MailPreloadImageEvent {
    private var startTime: Int
    private var startDownloadTime: Int?
    private var finishDownloadTime: Int?
    // 预加载触发的场景,取值： 新邮件: newMessage, 列表滚动： list, 消息卡片： card， 搜索： search
    private let come_from: String
    // 文件大小
    private var dataLength: Int?
    // 下载状态，0：加载成功、1：失败、2： 取消、3：命中率低导致未被调度
    private var status: Int = 0

    init(from: String) {
        self.come_from = from
        self.startTime = MailTracker.getCurrentTime()
    }

    func startDownload() {
        self.startDownloadTime = MailTracker.getCurrentTime()
    }

    func downloadFinish(status: Int, dataLength: Int?) {
        self.status = status
        self.dataLength = dataLength
        self.finishDownloadTime = MailTracker.getCurrentTime()
        log()
    }

    private func log() {
        var params = [String: Any]()
        params["status"] = status
        params["come_from"] = come_from
        if let length = dataLength {
            params["length"] = length
        }

        if let startDownloadTime = startDownloadTime {
            let cost = startDownloadTime - startTime
            params["waitScheduleInterval"] = cost
            if let finishDownloadTime = finishDownloadTime {
                let cost = finishDownloadTime - startDownloadTime
                params["time_cost_ms"] = cost
            }
        }
        MailTracker.log(event: "mail_message_image_preload_dev", params: params)
        MailLogger.info("mail_message_image_preload_dev", extraInfo: params, error: nil, component: nil)
    }
}
