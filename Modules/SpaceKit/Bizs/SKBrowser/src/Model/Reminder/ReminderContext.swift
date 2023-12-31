//
//  ReminderContext.swift
//  SpaceKit
//
//  Created by nine on 2019/10/15.
//

import SKCommon

class ReminderContext {
    var config: ReminderVCConfig
    var docsInfo: DocsInfo?
    var dateLabel: UILabel
    var expireTime: TimeInterval
    init(dateLabel: UILabel, config: ReminderVCConfig, expireTime: TimeInterval, docsInfo: DocsInfo?) {
        self.config = config
        self.dateLabel = dateLabel
        self.expireTime = expireTime
        self.docsInfo = docsInfo
    }
}
